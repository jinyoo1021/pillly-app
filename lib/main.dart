import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/supabase_client.dart';
import 'features/notifications/data/fcm_service.dart';
import 'features/notifications/data/interactive_notification_handler.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before any Firebase services are used
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase client for auth and API calls
  await SupabaseClientService.initialize();

  // Initialize FCM listener and local notifications with action buttons
  await FcmService.initialize();

  // Create a shared ProviderContainer so notification handlers can refresh state
  final container = ProviderContainer();
  InteractiveNotificationHandler.setContainer(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PilllyApp(),
    ),
  );
}