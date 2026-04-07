import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../../schedules/providers/schedule_provider.dart';
import '../../dose/providers/dose_history_provider.dart';

class InteractiveNotificationHandler {
  InteractiveNotificationHandler._();

  // Shared container for accessing Riverpod providers outside the widget tree
  static ProviderContainer? _container;

  static void setContainer(ProviderContainer container) {
    _container = container;
  }

  /// Entry point for both foreground and background notification action taps
  static Future<void> handle(NotificationResponse response) async {
    final actionId = response.actionId;
    final payload = response.payload;
    if (actionId == null || payload == null) return;

    // Decode the JSON payload that was attached when building the local notification
    Map<String, dynamic> data;
    try {
      data = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final scheduleId = data['schedule_id'] as String?;
    final logDate = data['log_date'] as String?;
    if (scheduleId == null || logDate == null) return;

    // Route to the correct API endpoint based on which button the user tapped
    if (actionId == AppConstants.actionDone) {
      await _postAction('/dose/confirm', scheduleId, logDate);
    } else if (actionId == AppConstants.actionSkip) {
      await _postAction('/dose/skip', scheduleId, logDate);
    }

    // Invalidate cached data so the UI reflects the updated dose status
    refreshProviders();
  }

  /// Refresh all dose-related providers after a notification action is processed
  static void refreshProviders() {
    final container = _container;
    if (container == null) return;
    container.read(todaySchedulesProvider.notifier).refresh();
    container.invalidate(doseLogsProvider);
    container.invalidate(selectedDateLogsProvider);
  }

  /// Send a POST request to the backend to record the dose action
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