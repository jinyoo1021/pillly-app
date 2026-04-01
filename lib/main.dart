import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app.dart';
import 'core/supabase_client.dart';
import 'features/notifications/data/interactive_notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle notification action that launched the app
  final launchDetails = await FlutterLocalNotificationsPlugin()
      .getNotificationAppLaunchDetails();

  if (launchDetails?.didNotificationLaunchApp == true) {
    final response = launchDetails!.notificationResponse;
    if (response != null) {
      await InteractiveNotificationHandler.handle(response);
    }
  }

  // Supabase init
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  if (supabaseUrl.isNotEmpty) {
    await SupabaseClientService.initialize();
  }

  runApp(
    const ProviderScope(
      child: PilllyApp(),
    ),
  );
}