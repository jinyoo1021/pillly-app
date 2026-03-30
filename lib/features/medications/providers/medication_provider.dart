import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/medication_repository.dart';
import '../domain/medication.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

class MedicationCreateNotifier extends AsyncNotifier<void> {
  MedicationRepository get _repo => ref.read(medicationRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<bool> create(MedicationCreateRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.createMedication(request));
    return !state.hasError;
  }
}

final medicationCreateProvider =
AsyncNotifierProvider<MedicationCreateNotifier, void>(
  MedicationCreateNotifier.new,
);