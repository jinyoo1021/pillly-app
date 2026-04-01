import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../domain/dose_action.dart';
import '../domain/dose_log.dart';
import '../domain/dose_stats.dart';

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
    final items = body['logs'] as List<dynamic>? ?? [];
    return items
        .map((e) => DoseLog.fromMap(e as Map<String, dynamic>))
        .toList();
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