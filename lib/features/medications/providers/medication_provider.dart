import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/medication_repository.dart';
import '../domain/medication.dart';
import '../../schedules/providers/schedule_provider.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

// Medication list

final medicationListProvider =
AsyncNotifierProvider<MedicationListNotifier, List<Medication>>(
  MedicationListNotifier.new,
);

class MedicationListNotifier extends AsyncNotifier<List<Medication>> {
  MedicationRepository get _repo => ref.read(medicationRepositoryProvider);

  @override
  Future<List<Medication>> build() async {
    return _repo.fetchMedications();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.fetchMedications());
  }

  Future<void> toggle(String id) async {
    // Optimistic update
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((m) {
        if (m.id == id) return m.copyWith(isActive: !m.isActive);
        return m;
      }).toList(),
    );

    try {
      await _repo.toggleMedication(id);
    } catch (_) {
      // Rollback on failure
      refresh();
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.deleteMedication(id);
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.where((m) => m.id != id).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

// Medication create

class MedicationCreateNotifier extends AsyncNotifier<void> {
  MedicationRepository get _repo => ref.read(medicationRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<bool> create(MedicationCreateRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.createMedication(request));
    if (!state.hasError) {
      ref.read(medicationListProvider.notifier).refresh();
    }
    return !state.hasError;
  }
}

final medicationCreateProvider =
AsyncNotifierProvider<MedicationCreateNotifier, void>(
  MedicationCreateNotifier.new,
);

// Medication update

class MedicationUpdateNotifier extends AsyncNotifier<void> {
  MedicationRepository get _repo => ref.read(medicationRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<bool> save({
    required String id,
    required MedicationUpdateRequest request,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
          () => _repo.updateMedication(id: id, request: request),
    );
    if (!state.hasError) {
      ref.read(medicationListProvider.notifier).refresh();
      await ref.read(todaySchedulesProvider.notifier).refresh();
    }
    return !state.hasError;
  }
}

final medicationUpdateProvider =
AsyncNotifierProvider<MedicationUpdateNotifier, void>(
  MedicationUpdateNotifier.new,
);