import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../core/supabase_client.dart';
import '../domain/medication.dart';

class MedicationRepository {
  MedicationRepository();

  // GET /medications

  Future<List<Medication>> fetchMedications() async {
    final session = SupabaseClientService.currentSession;
    if (session == null) return [];

    final uri = Uri.parse('${AppConstants.apiBaseUrl}/medications');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch medications: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['medications'] as List<dynamic>? ?? [];
    return items
        .map((e) => Medication.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // POST /medications

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

    // Backend returns medication data directly (not nested under 'medication' key)
    final medicationData = body.containsKey('medication')
        ? body['medication'] as Map<String, dynamic>
        : body;

    return Medication.fromMap(medicationData);
  }

  // PATCH /medications/{id}

  Future<Medication> updateMedication({
    required String id,
    required MedicationUpdateRequest request,
  }) async {
    final session = SupabaseClientService.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConstants.apiBaseUrl}/medications/$id');
    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toMap()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update medication: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // Backend returns medication data directly (not nested)
    final medicationData = body.containsKey('medication')
        ? body['medication'] as Map<String, dynamic>
        : body;

    return Medication.fromMap(medicationData);
  }

  // PATCH /medications/{id}/toggle

  Future<void> toggleMedication(String id) async {
    final session = SupabaseClientService.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final uri =
    Uri.parse('${AppConstants.apiBaseUrl}/medications/$id/toggle');
    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle medication: ${response.body}');
    }
  }

  // DELETE /medications/{id}

  Future<void> deleteMedication(String id) async {
    final session = SupabaseClientService.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConstants.apiBaseUrl}/medications/$id');
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete medication: ${response.body}');
    }
  }
}