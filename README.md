# pillly-app

Flutter mobile app for [Pillly](https://github.com/jinyoo1021/pillly) — iOS & Android, Riverpod state management, and interactive lock-screen notifications with one-tap dose confirmation.

This is one half of the Pillly project. For the full picture, see the [main README](https://github.com/jinyoo1021/pillly) and the [backend API](https://github.com/jinyoo1021/pillly-api).

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Screens](#screens)
- [Key Architecture Patterns](#key-architecture-patterns)
  - [GoRouter Auth Redirect Guard](#gorouter-auth-redirect-guard)
  - [Riverpod AsyncNotifier Pattern](#riverpod-asyncnotifier-pattern)
  - [Background Isolate Re-initialization](#background-isolate-re-initialization)
  - [ProviderContainer Outside the Widget Tree](#providercontainer-outside-the-widget-tree)
- [Notification Flow](#notification-flow)
- [Local Development](#local-development)
- [Environment Variables](#environment-variables)
- [Testing](#testing)
- [What I Learned](#what-i-learned)
- [Limitations and What I'd Do Differently](#limitations-and-what-id-do-differently)

---

## Tech Stack

| Layer | Technology | Why |
|---|---|---|
| Framework | Flutter 3 + Dart | Single codebase for iOS and Android with identical UI and notification behavior |
| State management | Riverpod 3 (manual `AsyncNotifier`) | `AsyncValue.guard()` pattern, optimistic updates, and automatic rollback |
| Navigation | GoRouter 17 | Auth-state-driven redirect guard with `_AuthChangeNotifier` |
| Auth | Supabase Flutter + Google Sign-In SDK + Sign in with Apple | Native SDKs acquire `id_token`, which is exchanged with Supabase Auth |
| Push (receive) | firebase_messaging | FCM message reception across foreground, background, and terminated states |
| Push (display) | flutter_local_notifications v21 | Converts data-only FCM payloads into custom notifications with action buttons |
| HTTP | http package | Lightweight REST client used by notification action handlers |
| Local storage | SharedPreferences | Onboarding completion flag and notification preference persistence |
| Localization | intl | Date and time formatting (`DateFormat`) |

---

## Project Structure

```
lib/
├── main.dart                     # Initializes Firebase, Supabase, FCM — sets up shared ProviderContainer
├── app.dart                      # MaterialApp.router
├── core/
│   ├── router.dart               # GoRouter routes + auth redirect guard
│   ├── constants.dart            # --dart-define values, notification channel/action IDs
│   └── supabase_client.dart      # Supabase singleton initialization
├── features/
│   ├── auth/
│   │   ├── data/                 # AuthRepository — email, Google, Apple, session
│   │   ├── domain/               # PilllyUser model
│   │   ├── providers/            # AuthNotifier (AsyncNotifier), isAuthenticatedProvider
│   │   └── presentation/         # SplashScreen, OnboardingScreen, LoginScreen, RegisterScreen
│   ├── schedules/
│   │   ├── data/                 # ScheduleRepository — GET /schedules/today
│   │   ├── domain/               # TodaySchedule, DoseStatus enum
│   │   ├── providers/            # TodaySchedulesNotifier (optimistic update)
│   │   └── presentation/         # HomeScreen
│   ├── medications/
│   │   ├── data/                 # MedicationRepository — full CRUD + toggle
│   │   ├── domain/               # Medication, MedicationCreateRequest, MedicationUpdateRequest
│   │   ├── providers/            # MedicationListNotifier, MedicationCreateNotifier
│   │   └── presentation/         # MedicationListScreen, MedicationAddScreen, MedicationEditScreen
│   ├── dose/
│   │   ├── data/                 # DoseRepository — confirm, skip, undo, logs, stats
│   │   ├── domain/               # DoseLog, DoseStats, MedicationStat
│   │   ├── providers/            # DoseNotifier, DoseLogsNotifier, DoseStatsNotifier, SelectedDateLogsNotifier
│   │   └── presentation/         # DoseHistoryScreen, DoseStatsScreen
│   ├── notifications/
│   │   ├── data/                 # FcmService, InteractiveNotificationHandler
│   │   ├── domain/               # NotificationSettings
│   │   ├── providers/            # NotificationSettingsNotifier
│   │   └── presentation/         # NotificationSettingsScreen
│   └── settings/
│       └── presentation/         # SettingsScreen
└── shared/
    ├── theme/                    # AppColors, AppTheme
    └── widgets/                  # BottomNav, PrimaryTextField
```

**Architecture pattern:** feature-based clean architecture — each feature is self-contained with four layers: `data → domain → providers → presentation`.

`DoseStatus` lives in `schedules/domain/` rather than `dose/domain/` by design. `TodaySchedule` (returned by the home screen API) carries a `DoseStatus`, so placing the enum in `dose/` would create a circular dependency. The `dose` feature imports from `schedules`, not the other way around.

---

## Screens

| Screen | Route | Key detail |
|---|---|---|
| SplashScreen | `/` | 1.8s fade/scale animation, then routes to one of three destinations |
| OnboardingScreen | `/onboarding` | 3-page `PageView`, expanding dot indicator, saves `onboarding_done` to SharedPreferences |
| LoginScreen | `/login` | Email + Google + Apple login, server errors translated to user-friendly copy |
| RegisterScreen | `/register` | 4 fields: name / email / password / confirm password, 8-char minimum |
| HomeScreen | `/home` | Optimistic dose confirm/skip, 3-state button UI, adherence card, pull-to-refresh |
| MedicationListScreen | `/medications` | Active/inactive sections, optimistic toggle, 2-step delete confirmation dialog |
| MedicationAddScreen | `/medications/add` | CycleType-driven UI: weekday selector (weekly), ± interval picker, up to 6 time slots |
| MedicationEditScreen | `/medications/:id/edit` | Pre-populates from existing medication, reads from active schedules only |
| DoseHistoryScreen | `/dose/history` | `GridView.builder` 7-column calendar, tap date for per-medication detail |
| DoseStatsScreen | `/dose/stats` | Weekly/monthly tab, `LinearProgressIndicator` bar chart (no external chart package) |
| NotificationSettingsScreen | `/settings/notifications` | Enabled toggle, 0/5/10/15/30-min advance reminder, test notification trigger |
| SettingsScreen | `/settings` | First-letter avatar, sign-out with 2-step confirmation dialog |

**SplashScreen routing logic:**
```
Authenticated           → /home
Not authenticated
  └── Onboarding done  → /login
  └── First launch     → /onboarding
```

---

## Key Architecture Patterns

### GoRouter Auth Redirect Guard

All route protection is handled in `router.dart`. Public routes (splash, onboarding, login, register) are accessible without authentication. Every other route redirects to `/login` if not authenticated, and redirects authenticated users away from `/login` to `/home`.

```dart
redirect: (context, state) {
  if (!isAuthenticated && !publicRoutes.contains(location)) return AppRoutes.login;
  if (isAuthenticated && location == AppRoutes.login) return AppRoutes.home;
  return null;
},
```

`_AuthChangeNotifier` bridges GoRouter's `refreshListenable` to Riverpod — it listens to `authNotifierProvider` and `isAuthenticatedProvider` and calls `notifyListeners()` when either changes, triggering a redirect re-evaluation.

### Riverpod AsyncNotifier Pattern

All async operations follow the same structure:

```dart
Future<void> confirmDose({required String scheduleId, ...}) async {
  // 1. Optimistic UI update — reflect immediately
  ref.read(todaySchedulesProvider.notifier).updateScheduleStatus(scheduleId, DoseStatus.done);

  // 2. Call the API
  state = await AsyncValue.guard(() => _repo.confirmDose(...));

  // 3. Roll back on failure
  if (state.hasError) {
    ref.read(todaySchedulesProvider.notifier).refresh();
  }
}
```

This pattern is used for dose confirm/skip (home screen) and medication toggle (medication list screen).

### Background Isolate Re-initialization

`firebaseMessagingBackgroundHandler` runs in a separate Dart isolate — entirely outside the app's process. All stateful services must be re-initialized from scratch:

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final localNotifications = FlutterLocalNotificationsPlugin();
  await localNotifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
  );

  await androidPlugin?.createNotificationChannel(...);
  await _showNotificationFromData(localNotifications, message.data, message.hashCode);
}
```

`@pragma('vm:entry-point')` is required on both handlers. Without it, the Flutter tree-shaker removes them from the release build and background notifications silently stop working.

Both handlers must be top-level functions — closures and instance methods cannot be used because Dart isolates don't share memory with the main isolate.

### ProviderContainer Outside the Widget Tree

Notification action handlers run outside the widget tree and have no `BuildContext`. To invalidate Riverpod providers from those handlers, `main.dart` creates a `ProviderContainer` before `runApp`, passes it to `InteractiveNotificationHandler`, and wraps the app in `UncontrolledProviderScope` with the same container:

```dart
final container = ProviderContainer();
InteractiveNotificationHandler.setContainer(container);

runApp(
  UncontrolledProviderScope(
    container: container,
    child: const PilllyApp(),
  ),
);
```

After an action button is tapped and the dose is logged, the handler calls:

```dart
container.read(todaySchedulesProvider.notifier).refresh();
container.invalidate(doseLogsProvider);
container.invalidate(selectedDateLogsProvider);
```

This makes the home screen and history calendar refresh instantly after a lock-screen action, without the user needing to open the app.

---

## Notification Flow

The full path from QStash webhook to UI update:

```
FastAPI /v1/notifications/notify  (called by QStash at scheduled time)
  → FCM data-only message dispatched to device

Device receives FCM message
├── Foreground  → FcmService._handleForegroundMessage()
├── Background  → firebaseMessagingBackgroundHandler()   ← separate Dart isolate
└── Terminated  → _messaging.getInitialMessage() on next launch

All paths converge at _showNotificationFromData()
  → flutter_local_notifications.show()
     actions: [Taken ✓ (ACTION_DONE), Skip ✗ (ACTION_SKIP)]

User taps action button
├── Foreground/background  → _onNotificationTap / _onBackgroundNotificationTap
└── Terminated             → getNotificationAppLaunchDetails() on startup

→ InteractiveNotificationHandler.handle(response)
    decodes JSON payload from notification → extracts schedule_id + log_date
    if ACTION_DONE → POST /dose/confirm
    if ACTION_SKIP → POST /dose/skip
→ ProviderContainer.read(todaySchedulesProvider.notifier).refresh()
→ ProviderContainer.invalidate(doseLogsProvider)
→ UI updates without user opening the app
```

**Why data-only FCM?**
When an FCM payload includes a `notification` field, Android auto-renders a system notification that does not support custom action buttons. Sending data-only messages lets Flutter intercept the raw payload and render a fully custom local notification with Taken ✓ / Skip ✗ buttons via `flutter_local_notifications`.

**iOS — `UNNotificationCategory` registered in `AppDelegate.swift`:**
```swift
let doneAction = UNNotificationAction(identifier: "ACTION_DONE", title: "Taken ✓", options: .authenticationRequired)
let skipAction = UNNotificationAction(identifier: "ACTION_SKIP", title: "Skip ✗",  options: .destructive)
let pillCategory = UNNotificationCategory(identifier: "PILL_REMINDER", actions: [doneAction, skipAction], intentIdentifiers: [], options: [])
UNUserNotificationCenter.current().setNotificationCategories([pillCategory])
```

**Android — `ActionBroadcastReceiver` registered in `AndroidManifest.xml`** (built into `flutter_local_notifications`).

---

## Local Development

### Prerequisites

- Flutter 3.x (`flutter --version`)
- Android emulator (Pixel device via Android Studio) or iOS Simulator (Xcode)
- pillly-api running locally (see [pillly-api README](https://github.com/jinyoo1021/pillly-api))
- Firebase project configured (`flutterfire configure` — generates `firebase_options.dart`)

### Install dependencies

```bash
flutter pub get
```

### Run on Android emulator

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/v1 \
  --dart-define=SUPABASE_URL=http://10.0.2.2:***** \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  -d emulator-5554
```

### Run on iOS simulator

```bash
flutter run \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/v1 \
  --dart-define=SUPABASE_URL=http://127.0.0.1:***** \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

**Android emulator network note:** Inside the Android emulator, `localhost` and `127.0.0.1` refer to the emulator itself, not the Mac. The Mac's localhost is accessible at `10.0.2.2`. If you use `127.0.0.1` on an Android emulator, every API call will silently fail with a connection refused error.

### Check active devices

```bash
flutter devices
```

---

## Environment Variables

All configuration is injected at build time using `--dart-define`. No `.env` file is committed.

| Variable | Required | Default | Description |
|---|---|---|---|
| `API_BASE_URL` | ✅ | `https://api.pillly.app/v1` | Backend API base URL (no trailing slash) |
| `SUPABASE_URL` | ✅ | — | Supabase project URL |
| `SUPABASE_ANON_KEY` | ✅ | — | Supabase anon key (safe to embed in client) |

All three are read in `lib/core/constants.dart` via `String.fromEnvironment()`:

```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.pillly.app/v1',
);
```

If `SUPABASE_URL` or `SUPABASE_ANON_KEY` are not provided, Supabase initialization fails at startup with an assertion error.

---

## Testing

```bash
flutter test              # all 68 tests
flutter test test/unit/   # 51 unit tests
flutter test test/widget/ # 17 widget tests
flutter analyze           # static analysis
```

| File | Type | Coverage |
|---|---|---|
| `pillly_user_test.dart` | Unit | `fromMap`, `copyWith`, `toMap` serialization |
| `medication_test.dart` | Unit | `fromMap` with nested schedules, `parseCycleType` all 4 values, active-only schedule filter |
| `schedule_test.dart` | Unit | `fromMap`, `parseStatus` all status values, `copyWith` status update |
| `dose_log_test.dart` | Unit | Unknown status → `pending` fallback, `dayStatus` priority (done > missed > pending > skipped) |
| `dose_stats_test.dart` | Unit | `MedicationStat.fromMap`, `overall_rate` parsing, empty `by_medication` handling |
| `login_screen_test.dart` | Widget | Empty email error, invalid email format error, empty password error, sign-up link visible |
| `medication_add_screen_test.dart` | Widget | Required fields render, empty name error, cycle type options, weekday selector on Weekly |

---

## What I Learned

### 1. Never name a model class the same as an SDK class

The first version of the user domain model was named `AuthUser`. This caused an `ambiguous_import` error because `supabase_flutter` already exports a class called `AuthUser` internally.

The fix was simple — rename the model to `PilllyUser` — but it touched every file that imported it. The lesson: when introducing domain models, check the names of classes exported by the packages you're using before committing to a name.

---

### 2. `isAuthenticatedProvider` must read from an async source

The first implementation based `isAuthenticatedProvider` on `currentUserProvider`, which reads the Supabase session synchronously:

```dart
// Broken — currentUserProvider is synchronous
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
```

After a successful login, GoRouter immediately re-evaluates the redirect. But `currentUserProvider` reads the Supabase session state before it's been reflected in Riverpod — it returns `null`, so the router sends the user back to `/login`.

**Fix:** base `isAuthenticatedProvider` on `authNotifierProvider`, which is an `AsyncNotifier` and only emits after the session has been fully set:

```dart
// Correct — reads from AsyncNotifier state
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value != null;
});
```

**Takeaway:** In Riverpod, any provider that depends on async state must read from an async-aware source. A synchronous `Provider` that wraps async data will read stale values at re-evaluation time.

---

### 3. Background isolates need everything re-initialized from scratch

Firebase background message handlers run in a completely separate Dart isolate — no shared memory, no existing singletons, no widget tree. Every service that was initialized in `main()` must be re-initialized inside the handler.

This means calling `Firebase.initializeApp()`, `FlutterLocalNotificationsPlugin().initialize()`, and `AndroidPlugin.createNotificationChannel()` again, as if the app just launched. Skipping any of these produces a silent failure — the handler runs but nothing happens.

Additionally, both background handler functions must be:

- **Top-level functions** — not closures, not instance methods. Dart isolates cannot close over variables from another isolate.
- **Annotated with `@pragma('vm:entry-point')`** — without this, the Flutter tree-shaker removes the function from release builds. Background notifications work in debug mode but silently stop in production.

---

### 4. Supabase auto-signs-in after registration — the router intercepts it

After a successful `signUp()`, Supabase automatically creates a session. `isAuthenticated` becomes `true` immediately, and the GoRouter redirect sends the user to `/home` before they ever reach `/login`.

The fix is to explicitly sign out right after registration succeeds:

```dart
await _repo.signUpWithEmail(...);
ref.read(authNotifierProvider.notifier).signOut();  // clear the auto-session
context.go(AppRoutes.login);
```

**Takeaway:** Auth SDKs that combine registration and sign-in into one call (as Supabase does by design) create a state that auth-guard routers will immediately act on. If the UX requires a separate login step, the auto-session must be cleared explicitly.

---

### 5. `Medication.fromMap()` was reading from the wrong schedule

When a medication's schedule is updated, old schedules are soft-deleted (`is_active = false`) and new ones are inserted. The API response includes all schedules, both active and inactive.

The first parser read `cycleType` and `weekdays` from `schedulesList.first`:

```dart
// Wrong — .first is the oldest (inactive) schedule
final cycleTypeStr = schedulesList.isNotEmpty
    ? schedulesList.first['cycle_type'] as String? ?? 'daily'
    : 'daily';
```

After any schedule edit, the medication list and edit screen would show the old cycle type because `.first` is the oldest record, not the current one. The fix filters for active schedules first:

```dart
final activeSchedules = schedulesList.where((s) => s['is_active'] == true).toList();

final cycleTypeStr = activeSchedules.isNotEmpty
    ? activeSchedules.first['cycle_type'] as String? ?? 'daily'
    : 'daily';

// weekdays also extracted from active schedule's cycle_value
final cycleValue = activeSchedules.first['cycle_value'];
if (cycleValue is Map && cycleValue['weekdays'] != null) {
  weekdays = List<int>.from(cycleValue['weekdays']);
}
```

---

### 6. Three API response structure mismatches discovered during integration

The Flutter model layer was written before the backend was fully finalized, which led to three shape mismatches that caused silent failures — no crash, just empty lists or infinite loading:

| Field | Flutter expected | Actual backend |
|---|---|---|
| Medication scheduled times | `scheduled_times: ["08:00", "20:00"]` | `schedules: [{scheduled_time: "08:00:00", cycle_type: "daily"}, ...]` |
| Today's schedule response key | `schedules` | `items` |
| Medication create response | `body['medication']` (wrapped) | `body` directly |

**Takeaway:** When frontend and backend are developed in parallel, agree on response shapes in writing before implementing either side. A shared API contract (even a simple JSON file) would have prevented all three of these.

---

### 7. `flutter_local_notifications` v21 changed the entire API to named parameters

The existing notification setup code was written with the v20 API. After upgrading to v21, every `initialize()` and `show()` call produced type errors.

The issue: v21 changed all positional parameters to named parameters throughout the package. Running `flutter pub deps` to confirm the installed version was the key diagnostic step — the error messages alone didn't make the version change obvious.

The full `_setupLocalNotifications()` and every `show()` call had to be rewritten from scratch using the v21 named-parameter API.

---

### 8. `StateProvider` was removed in Riverpod 3.x

The first implementation of `selectedMonthProvider` used `StateProvider`:

```dart
// Riverpod 2.x — doesn't exist in 3.x
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());
```

In Riverpod 3.x, `StateProvider` was removed. The replacement is `NotifierProvider`:

```dart
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime(DateTime.now().year, DateTime.now().month);

  void set(DateTime month) => state = month;
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);
```

**Takeaway:** When starting a project with a major library version, read the migration guide before writing any code. Riverpod's 2.x → 3.x migration removed several provider types that are still common in tutorials and Stack Overflow answers.

---

### 9. `AsyncNotifier.update` conflicts with the parent class method

`MedicationUpdateNotifier` originally had a method named `update()`:

```dart
class MedicationUpdateNotifier extends AsyncNotifier<void> {
  Future<void> update(MedicationUpdateRequest req) async { ... } // invalid_override
}
```

`AsyncNotifier` has a built-in `update()` method that Riverpod uses internally. Naming a subclass method the same produces an `invalid_override` compile error. The fix was renaming the business logic method to `save()`.

---

### 10. Bar chart built without an external package

The statistics screen displays a per-medication adherence bar chart. Rather than pulling in a chart library, this was built using Flutter's built-in `LinearProgressIndicator`:

```dart
color: pct >= 80 ? AppColors.done
     : pct >= 50 ? AppColors.pending
     : AppColors.missed,
```

The decision was deliberate — a chart library adds hundreds of KB and significant API surface to learn, for a bar chart that only needs color-coded width. Three colored progress bars were sufficient.

---

## Limitations and What I'd Do Differently

### `--dart-define` has no example file

There is no committed file showing which `--dart-define` values are required. A new developer must read `AppConstants` in `constants.dart` to discover them. Adding a `dart-defines.example.json` usable with `--dart-define-from-file` would solve the onboarding friction entirely:

```json
{
  "API_BASE_URL": "http://10.0.2.2:8000/v1",
  "SUPABASE_URL": "http://10.0.2.2:*****",
  "SUPABASE_ANON_KEY": "your_key_here"
}
```

---

### Riverpod code-gen was not used

All providers were written manually. Riverpod 3.x includes `riverpod_generator` and `@riverpod` annotations that generate the provider boilerplate automatically, give compile-time names for providers, and eliminate the risk of typos in provider variable names.

Starting without code-gen was a conscious choice to reduce initial setup friction, but the accumulated boilerplate across 10+ providers makes it worth setting up from the start on the next project.

---

### Integration tests were written but never fully run

`integration_test/app_test.dart` covers the splash → onboarding → login screen flow, but the tests were never run against a connected backend. The file exists and passes basic rendering checks, but there is no verified end-to-end test covering dose confirmation, medication add, or the history calendar.

---

### Widget tests don't use real providers

The widget tests in `test/widget/` render screens with hardcoded state rather than real `ProviderScope`. They verify that form fields exist and validation messages appear, but they don't test that the screens correctly respond to provider state changes. Adding a `ProviderScope` wrapper with `overrides` would make these tests significantly more useful.

---

### iOS APNs action buttons were not verified on a real device

`_send_apns()` in the backend routes iOS push through Firebase Admin SDK, which handles APNs delivery internally. The Flutter side registers the `PILL_REMINDER` `UNNotificationCategory` in `AppDelegate.swift`, but the full Taken ✓ / Skip ✗ button flow on iOS was never confirmed on a real device due to the APNs certificate setup not being completed.

`FcmService.triggerTestNotification()` was added as a workaround — it generates a local notification directly, bypassing FCM entirely, to simulate the action button UI in the simulator.

---

### Color system is static constants, not `ThemeExtension`

`AppColors` is a class of `static const Color` values. This works fine for a light-only app, but it can't be accessed via `Theme.of(context)` and has no path to dark mode support. Using `ThemeExtension<AppColors>` from the start would make colors context-aware and dark mode support a configuration change rather than a refactor.
