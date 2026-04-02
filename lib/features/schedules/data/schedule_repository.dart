import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../domain/schedule.dart';

class ScheduleRepository {
  ScheduleRepository();

  Future<List<TodaySchedule>> fetchTodaySchedules() async {
    final session = SupabaseClientService.currentSession;
    if (session == null) return [];

    final uri = Uri.parse('${AppConstants.apiBaseUrl}/schedules/today');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch today schedules: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // Backend returns 'items' key instead of 'schedules'
    final items = body['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => TodaySchedule.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}