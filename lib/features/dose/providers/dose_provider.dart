import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dose_repository.dart';
import '../domain/dose_action.dart';
import '../../schedules/domain/schedule.dart';
import '../../schedules/providers/schedule_provider.dart';
import '../providers/dose_history_provider.dart';

final doseRepositoryProvider = Provider<DoseRepository>((ref) {
  return DoseRepository();
});

class DoseNotifier extends AsyncNotifier<void> {
  DoseRepository get _repo => ref.read(doseRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<void> confirmDose({
    required String scheduleId,
    required String logDate,
  }) async {
    // Optimistic UI update
    ref
        .read(todaySchedulesProvider.notifier)
        .updateScheduleStatus(scheduleId, DoseStatus.done);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.confirmDose(
      DoseConfirmRequest(scheduleId: scheduleId, logDate: logDate),
    ));

    if (state.hasError) {
      // Rollback on failure
      ref.read(todaySchedulesProvider.notifier).refresh();
    }
    await ref.read(todaySchedulesProvider.notifier).refresh();
    ref.invalidate(doseLogsProvider);
  }

  Future<void> skipDose({
    required String scheduleId,
    required String logDate,
  }) async {
    // Optimistic UI update
    ref
        .read(todaySchedulesProvider.notifier)
        .updateScheduleStatus(scheduleId, DoseStatus.skipped);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.skipDose(
      DoseSkipRequest(scheduleId: scheduleId, logDate: logDate),
    ));

    if (state.hasError) {
      // Rollback on failure
      ref.read(todaySchedulesProvider.notifier).refresh();
    }
    await ref.read(todaySchedulesProvider.notifier).refresh();
    ref.invalidate(doseLogsProvider);
  }

  // Undo - optimistic UI update
  Future<void> undoDose({required String scheduleId}) async {
   ref
        .read(todaySchedulesProvider.notifier)
        .updateScheduleStatus(scheduleId, DoseStatus.pending);
  }
}

final doseNotifierProvider =
AsyncNotifierProvider<DoseNotifier, void>(DoseNotifier.new);