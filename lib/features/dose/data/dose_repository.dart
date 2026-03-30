import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../domain/dose_action.dart';

class DoseRepository {
  DoseRepository();

  Future<void> confirmDose(DoseConfirmRequest request) async {
    await _post('/dose/confirm', request.toMap());
  }

  Future<void> skipDose(DoseSkipRequest request) async {
    await _post('/dose/skip', request.toMap());
  }

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