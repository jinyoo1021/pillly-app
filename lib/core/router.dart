import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/schedules/presentation/home_screen.dart';
import '../features/medications/presentation/medication_add_screen.dart';
import '../features/medications/presentation/medication_list_screen.dart';
import '../features/medications/presentation/medication_edit_screen.dart';
import '../features/medications/domain/medication.dart';
import '../features/dose/presentation/dose_history_screen.dart';
import '../features/dose/presentation/dose_stats_screen.dart';
import '../features/notifications/presentation/notification_settings_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String medicationAdd = '/medications/add';
  static const String medicationEdit = '/medications/:id/edit';
  static const String medicationList = '/medications';
  static const String doseHistory = '/dose/history';
  static const String doseStats = '/dose/stats';
  static const String notificationSettings = '/settings/notifications';
  static const String settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final location = state.matchedLocation;

      const publicRoutes = {
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
      };

      if (!isAuthenticated && !publicRoutes.contains(location)) {
        return AppRoutes.login;
      }

      if (isAuthenticated && location == AppRoutes.login) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.medicationAdd,
        builder: (context, state) =>
        const MedicationAddScreen(),
      ),
      GoRoute(
        path: AppRoutes.medicationEdit,
        builder: (context, state) {
          final medication = state.extra as Medication;
          return MedicationEditScreen(medication: medication);
        }
      ),
      GoRoute(
        path: AppRoutes.medicationList,
        builder: (context, state) =>
        const MedicationListScreen(),
      ),
      GoRoute(
        path: AppRoutes.doseHistory,
        builder: (context, state) =>
        const DoseHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.doseStats,
        builder: (context, state) =>
        const DoseStatsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) =>
        const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) =>
        const SettingsScreen(),
      ),
    ],
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(isAuthenticatedProvider, (prev, next) => notifyListeners());
  }
}

// class _PlaceholderScreen extends StatelessWidget {
//   const _PlaceholderScreen({required this.label});
//   final String label;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(label)),
//       body: Center(
//         child: Text(
//           label,
//           style: const TextStyle(fontSize: 18, color: Color(0xFF6B7585)),
//         ),
//       ),
//     );
//   }
// }