import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});

final todaySchedulesProvider =
AsyncNotifierProvider<TodaySchedulesNotifier, List<TodaySchedule>>(
  TodaySchedulesNotifier.new,
);

class TodaySchedulesNotifier extends AsyncNotifier<List<TodaySchedule>> {
  ScheduleRepository get _repo => ref.read(scheduleRepositoryProvider);

  @override
  Future<List<TodaySchedule>> build() async {
    return _repo.fetchTodaySchedules();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.fetchTodaySchedules());
  }

  // Optimistic update — instantly reflect UI before server responds
  void updateScheduleStatus(String scheduleId, DoseStatus status) {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((s) {
        if (s.scheduleId == scheduleId) return s.copyWith(status: status);
        return s;
      }).toList(),
    );
  }
}