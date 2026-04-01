import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dose_repository.dart';
import '../domain/dose_stats.dart';
import 'dose_history_provider.dart';

// ── Selected period ───────────────────────────────────────

class SelectedPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'week';

  void set(String period) => state = period;
}

final selectedPeriodProvider =
NotifierProvider<SelectedPeriodNotifier, String>(
  SelectedPeriodNotifier.new,
);

// ── Dose stats ────────────────────────────────────────────

final doseStatsProvider =
AsyncNotifierProvider<DoseStatsNotifier, DoseStats>(
  DoseStatsNotifier.new,
);

class DoseStatsNotifier extends AsyncNotifier<DoseStats> {
  DoseRepository get _repo => ref.read(doseRepositoryProvider);

  @override
  Future<DoseStats> build() async {
    final period = ref.watch(selectedPeriodProvider);
    return _repo.fetchStats(period: period);
  }

  Future<void> loadPeriod(String period) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
          () => _repo.fetchStats(period: period),
    );
  }
}