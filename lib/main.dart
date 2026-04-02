import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app.dart';
import 'core/supabase_client.dart';
import 'firebase_options.dart';
import 'features/notifications/data/fcm_service.dart';
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

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase init
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  if (supabaseUrl.isNotEmpty) {
    await SupabaseClientService.initialize();
  }

  // FCM init (after Firebase)
  await FcmService.initialize();

  runApp(
    const ProviderScope(
      child: PilllyApp(),
    ),
  );
}