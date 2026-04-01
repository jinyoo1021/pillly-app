import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/dose_repository.dart';
import '../domain/dose_log.dart';
import '../../schedules/domain/schedule.dart';

final doseRepositoryProvider = Provider<DoseRepository>((ref) {
  return DoseRepository();
});

// ── Selected month ────────────────────────────────────────

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void set(DateTime month) => state = month;
}

final selectedMonthProvider =
NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

// ── Dose logs for selected month ──────────────────────────

final doseLogsProvider =
AsyncNotifierProvider<DoseLogsNotifier, List<DoseLog>>(
  DoseLogsNotifier.new,
);

class DoseLogsNotifier extends AsyncNotifier<List<DoseLog>> {
  DoseRepository get _repo => ref.read(doseRepositoryProvider);

  @override
  Future<List<DoseLog>> build() async {
    final month = ref.watch(selectedMonthProvider);
    return _fetchForMonth(month);
  }

  Future<void> loadMonth(DateTime month) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchForMonth(month));
  }

  Future<List<DoseLog>> _fetchForMonth(DateTime month) async {
    final from = DateFormat('yyyy-MM-dd').format(
      DateTime(month.year, month.month, 1),
    );
    final to = DateFormat('yyyy-MM-dd').format(
      DateTime(month.year, month.month + 1, 0),
    );
    return _repo.fetchLogs(from: from, to: to);
  }
}

// ── Logs grouped by date ──────────────────────────────────

final logsByDateProvider = Provider<Map<String, List<DoseLog>>>((ref) {
  final logs = ref.watch(doseLogsProvider).value ?? [];
  final map = <String, List<DoseLog>>{};
  for (final log in logs) {
    final key = DateFormat('yyyy-MM-dd').format(log.logDate);
    map.putIfAbsent(key, () => []).add(log);
  }
  return map;
});

// ── Day status (for calendar dot color) ──────────────────

DoseStatus? dayStatus(List<DoseLog> logs) {
  if (logs.isEmpty) return null;
  final allDone = logs.every((l) => l.status == DoseStatus.done);
  final hasMissed = logs.any((l) => l.status == DoseStatus.missed);
  final hasPending = logs.any((l) => l.status == DoseStatus.pending);

  if (allDone) return DoseStatus.done;
  if (hasMissed) return DoseStatus.missed;
  if (hasPending) return DoseStatus.pending;
  return DoseStatus.skipped;
}