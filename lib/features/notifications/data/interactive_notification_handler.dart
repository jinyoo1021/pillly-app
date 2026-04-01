import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';

class InteractiveNotificationHandler {
  InteractiveNotificationHandler._();

  // Call this from FcmService._onNotificationTap
  static Future<void> handle(NotificationResponse response) async {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId == null || payload == null) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final scheduleId = data['schedule_id'] as String?;
    final logDate = data['log_date'] as String?;

    if (scheduleId == null || logDate == null) return;

    if (actionId == AppConstants.actionDone) {
      await _postAction('/dose/confirm', scheduleId, logDate);
    } else if (actionId == AppConstants.actionSkip) {
      await _postAction('/dose/skip', scheduleId, logDate);
    }
  }

  static Future<void> _postAction(
      String path,
      String scheduleId,
      String logDate,
      ) async {
    final session = SupabaseClientService.currentSession;
    if (session == null) return;

    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'schedule_id': scheduleId,
        'log_date': logDate,
      }),
    );
  }
}