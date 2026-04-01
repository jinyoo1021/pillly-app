import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../domain/dose_stats.dart';
import '../providers/dose_stats_provider.dart';

class DoseStatsScreen extends ConsumerWidget {
  const DoseStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final statsAsync = ref.watch(doseStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Statistics'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Period selector
          _PeriodSelector(
            selected: period,
            onChanged: (p) {
              ref.read(selectedPeriodProvider.notifier).set(p);
              ref.read(doseStatsProvider.notifier).loadPeriod(p);
            },
          ),

          Expanded(
            child: statsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚠️',
                        style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load statistics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(doseStatsProvider.notifier)
                          .loadPeriod(period),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
              data: (stats) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Adherence rate card
                  _AdherenceCard(stats: stats),

                  const SizedBox(height: 20),

                  // Summary row
                  _SummaryRow(stats: stats),

                  const SizedBox(height: 24),

                  // Bar chart
                  if (period == 'week' &&
                      stats.weeklyBreakdown.isNotEmpty) ...[
                    _SectionLabel(label: 'Weekly breakdown'),
                    const SizedBox(height: 12),
                    _WeeklyBarChart(
                        items: stats.weeklyBreakdown),
                  ],

                  if (period == 'month' &&
                      stats.monthlyBreakdown.isNotEmpty) ...[
                    _SectionLabel(label: 'Monthly breakdown'),
                    const SizedBox(height: 12),
                    _MonthlyBarChart(
                        items: stats.monthlyBreakdown),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Period selector ───────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _PeriodTab(
            label: 'This week',
            value: 'week',
            selected: selected,
            onTap: () => onChanged('week'),
          ),
          const SizedBox(width: 10),
          _PeriodTab(
            label: 'This month',
            value: 'month',
            selected: selected,
            onTap: () => onChanged('month'),
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
            isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Adherence card ────────────────────────────────────────

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({required this.stats});
  final DoseStats stats;

  @override
  Widget build(BuildContext context) {
    final pct = (stats.adherenceRate * 100).round();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Adherence rate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pct >= 80
                      ? 'Excellent! Keep it up 🎉'
                      : pct >= 60
                      ? 'Good progress — stay consistent!'
                      : 'Let\'s work on building the habit 💪',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Circular progress
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: stats.adherenceRate,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white),
                  strokeWidth: 8,
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats});
  final DoseStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryCard(
          label: 'Taken',
          value: '${stats.doneDoses}',
          color: AppColors.done,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          label: 'Skipped',
          value: '${stats.skippedDoses}',
          color: AppColors.skipped,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          label: 'Missed',
          value: '${stats.missedDoses}',
          color: AppColors.missed,
        ),
        const SizedBox(width: 10),
        _SummaryCard(
          label: 'Total',
          value: '${stats.totalDoses}',
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ── Weekly bar chart ──────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.items});
  final List<WeeklyStats> items;

  @override
  Widget build(BuildContext context) {
    final maxVal =
    items.map((i) => i.total).fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: items.map((item) {
          final pct =
          (item.adherenceRate * 100).round();
          final barWidth = maxVal == 0
              ? 0.0
              : item.done / maxVal;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    item.weekLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: barWidth,
                      backgroundColor: AppColors.grey100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct >= 80
                            ? AppColors.done
                            : pct >= 50
                            ? AppColors.pending
                            : AppColors.missed,
                      ),
                      minHeight: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$pct%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Monthly bar chart ─────────────────────────────────────

class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.items});
  final List<MonthlyStats> items;

  @override
  Widget build(BuildContext context) {
    final maxVal =
    items.map((i) => i.total).fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: items.map((item) {
          final pct =
          (item.adherenceRate * 100).round();
          final barWidth = maxVal == 0
              ? 0.0
              : item.done / maxVal;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    item.monthLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: barWidth,
                      backgroundColor: AppColors.grey100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct >= 80
                            ? AppColors.done
                            : pct >= 50
                            ? AppColors.pending
                            : AppColors.missed,
                      ),
                      minHeight: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$pct%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}