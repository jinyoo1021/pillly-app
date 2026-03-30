import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../domain/medication.dart';

class MedicationRepository {
  MedicationRepository();

  Future<Medication> createMedication(MedicationCreateRequest request) async {
    final session = SupabaseClientService.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConstants.apiBaseUrl}/medications');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toMap()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create medication: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Medication.fromMap(body['medication'] as Map<String, dynamic>);
  }
}