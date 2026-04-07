import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../../firebase_options.dart';
import 'interactive_notification_handler.dart';

// ── Background isolate handlers ─────────────────────────
// Must be top-level functions — cannot be closures or instance methods.

@pragma('vm:entry-point')
Future<void> _onBackgroundNotificationTap(NotificationResponse response) async {
  // Initialize Supabase in background isolate for API calls
  await SupabaseClientService.initialize();
  await InteractiveNotificationHandler.handle(response);
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Re-initialize local notifications in background isolate
  final localNotifications = FlutterLocalNotificationsPlugin();
  await localNotifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
  );

  final androidPlugin = localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      importance: Importance.high,
    ),
  );

  // Convert data-only FCM message into local notification with action buttons
  await _showNotificationFromData(localNotifications, message.data, message.hashCode);
}

// ── Shared notification builder ─────────────────────────
// Used by both background handler and FcmService to avoid duplication.

Future<void> _showNotificationFromData(
    FlutterLocalNotificationsPlugin plugin,
    Map<String, dynamic> data,
    int notificationId,
    ) async {
  final title = data['title'] ?? '💊 Medication Reminder';
  final body = data['body'] ?? 'Time to take your medication';

  await plugin.show(
    id: notificationId,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction(AppConstants.actionDone, 'Taken ✓'),
          AndroidNotificationAction(AppConstants.actionSkip, 'Skip ✗'),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: AppConstants.iosNotificationCategoryId,
      ),
    ),
    payload: jsonEncode(data),
  );
}

// ── FcmService ──────────────────────────────────────────

class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // ── Initialize ────────────────────────────────────────

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _setupLocalNotifications();

    // Listen for data-only FCM messages while app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is brought back from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle notification tap that launched the app from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    await registerToken();
  }

  // ── Permission ────────────────────────────────────────

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ── Local notifications setup ─────────────────────────

  static Future<void> _setupLocalNotifications() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        importance: Importance.high,
      ),
    );
  }

  // ── Foreground message handler ────────────────────────
  // Data-only FCM → local notification with action buttons

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Debug: verify FCM message arrives and contains data
    await _showNotificationFromData(
      _localNotifications,
      message.data,
      message.hashCode,
    );
  }

  // ── Notification tap handlers ─────────────────────────

  static Future<void> _onNotificationTap(NotificationResponse response) async {
    await InteractiveNotificationHandler.handle(response);
  }

  // ── App opened via notification tap ───────────────────
  // Refresh UI state when user taps the notification body (not action buttons)

  static void _handleMessageOpenedApp(RemoteMessage message) {
    InteractiveNotificationHandler.refreshProviders();
  }

  // ── Token registration ────────────────────────────────

  static Future<void> registerToken() async {
    final session = SupabaseClientService.currentSession;
    if (session == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _postToken(token, session.accessToken);
    _messaging.onTokenRefresh.listen(
          (newToken) => _postToken(newToken, session.accessToken),
    );
  }

  static Future<void> _postToken(String token, String accessToken) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/notifications/token');
    await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'token': token, 'platform': 'android'}),
    );
  }
}