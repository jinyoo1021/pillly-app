import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import 'interactive_notification_handler.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {}

class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // ── Initialize ────────────────────────────────────────

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _setupLocalNotifications();
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
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
    );

    // Use var to avoid generic parsing issue
    final plugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        importance: Importance.high,
      ),
    );
  }

  // ── Foreground message handler ────────────────────────

  static Future<void> _handleForegroundMessage(
      RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction(
              AppConstants.actionDone,
              'Taken ✓',
            ),
            AndroidNotificationAction(
              AppConstants.actionSkip,
              'Skip ✗',
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: AppConstants.iosNotificationCategoryId,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Notification tap handler ──────────────────────────

  static void _onNotificationTap(NotificationResponse response) {
    InteractiveNotificationHandler.handle(response);
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

  static Future<void> _postToken(
      String token, String accessToken) async {
    final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/notifications/token');
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