import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../domain/dose_action.dart';
import '../domain/dose_log.dart';
import '../domain/dose_stats.dart';
import '../../../features/schedules/domain/schedule.dart';

class DoseRepository {
  DoseRepository();

  // ── POST /dose/confirm ───────────────────────────────

  Future<void> confirmDose(DoseConfirmRequest request) async {
    await _post('/dose/confirm', request.toMap());
  }

  // ── POST /dose/skip ──────────────────────────────────

  Future<void> skipDose(DoseSkipRequest request) async {
    await _post('/dose/skip', request.toMap());
  }

  // ── GET /dose/logs ───────────────────────────────────

  Future<List<DoseLog>> fetchLogs({
    required String from,
    required String to,
  }) async {
    final session = SupabaseClientService.currentSession;
    if (session == null) return [];

    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/dose/logs?from=$from&to=$to',
    );
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch dose logs: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // Backend returns daily summary, not individual logs
    // Convert summary to DoseLog list for calendar display
    final items = body['logs'] as List<dynamic>? ?? [];
    return items.map((e) {
      final map = e as Map<String, dynamic>;
      final dateStr = map['date'] as String;
      final done = map['done'] as int? ?? 0;
      final total = map['total'] as int? ?? 0;

      // Determine status from daily summary
      String status;
      if (done == total && total > 0) {
        status = 'done';
      } else if (done > 0) {
        status = 'done';
      } else {
        status = 'missed';
      }

      return DoseLog(
        id: dateStr,
        scheduleId: '',
        medicationName: '$done/$total taken',
        logDate: DateTime.parse(dateStr),
        status: DoseStatus.values.firstWhere(
              (s) => s.name == status,
          orElse: () => DoseStatus.pending,
        ),
      );
    }).toList();
  }

  // ── GET /dose/stats ──────────────────────────────────

  Future<DoseStats> fetchStats({required String period}) async {
    final session = SupabaseClientService.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/dose/stats?period=$period',
    );
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch stats: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return DoseStats.fromMap(body);
  }

  // ── GET /dose/logs/day ───────────────────────────────────

  Future<List<DoseLog>> fetchDayLogs({required String date}) async {
    final session = SupabaseClientService.currentSession;
    if (session == null) return [];

    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/dose/logs/day?date=$date',
    );
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch day logs: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>? ?? [];
    return items.map((e) => DoseLog.fromMap(e as Map<String, dynamic>)).toList();
  }

  // ── Private helper ───────────────────────────────────

  Future<void> _post(String path, Map<String, dynamic> body) async {
    final session = SupabaseClientService.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Request failed ($path): ${response.body}');
    }
  }
}