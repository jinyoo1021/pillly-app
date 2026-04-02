import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../schedules/domain/schedule.dart';
import '../domain/dose_log.dart';
import '../providers/dose_history_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';

class DoseHistoryScreen extends ConsumerWidget {
  const DoseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final logsAsync = ref.watch(doseLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dose history'),
        automaticallyImplyLeading: false,
      ),
      body: logsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text(
                'Failed to load history',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref
                    .read(doseLogsProvider.notifier)
                    .loadMonth(selectedMonth),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (logs) {
          final logsByDate = ref.watch(logsByDateProvider);
          return Column(
            children: [
              // Month navigator
              _MonthNavigator(
                month: selectedMonth,
                onPrev: () {
                  final prev = DateTime(
                    selectedMonth.year,
                    selectedMonth.month - 1,
                  );
                  ref.read(selectedMonthProvider.notifier).set(prev);
                  ref.read(doseLogsProvider.notifier).loadMonth(prev);
                },
                onNext: () {
                  final next = DateTime(
                    selectedMonth.year,
                    selectedMonth.month + 1,
                  );
                  ref.read(selectedMonthProvider.notifier).set(next);
                  ref.read(doseLogsProvider.notifier).loadMonth(next);
                },
              ),

              // Calendar
              _CalendarGrid(
                month: selectedMonth,
                logsByDate: logsByDate,
              ),

              const Divider(height: 1, color: AppColors.grey200),

              // Monthly summary
              _MonthlySummary(logs: logs),

              const Divider(height: 1, color: AppColors.grey200),

              // Log list
              Expanded(
                child: logs.isEmpty
                    ? const _EmptyView()
                    : _LogList(logs: logs),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}

// ── Month navigator ───────────────────────────────────────

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy').format(month);
    final isCurrentMonth = month.year == DateTime.now().year &&
        month.month == DateTime.now().month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
            color: AppColors.textSecondary,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: isCurrentMonth ? null : onNext,
            color: isCurrentMonth
                ? AppColors.grey200
                : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ── Calendar grid ─────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.logsByDate,
  });

  final DateTime month;
  final Map<String, List<DoseLog>> logsByDate;

  static const List<String> _weekdays = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  ];

  Color _dotColor(DoseStatus? status) {
    return switch (status) {
      DoseStatus.done => AppColors.done,
      DoseStatus.missed => AppColors.missed,
      DoseStatus.skipped => AppColors.skipped,
      DoseStatus.pending => AppColors.pending,
      null => Colors.transparent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // Sun=0
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: _weekdays
                .map((d) => Expanded(
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Day cells
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) {
                return const SizedBox.shrink();
              }
              final day = index - startWeekday + 1;
              final date = DateTime(month.year, month.month, day);
              final key = DateFormat('yyyy-MM-dd').format(date);
              final logs = logsByDate[key] ?? [];
              final status = dayStatus(logs);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isFuture = date.isAfter(today);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isToday
                              ? Colors.white
                              : isFuture
                              ? AppColors.grey400
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.transparent
                          : _dotColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Monthly summary ───────────────────────────────────────

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({required this.logs});
  final List<DoseLog> logs;

  @override
  Widget build(BuildContext context) {
    final total = logs.length;
    final done = logs.where((l) => l.status == DoseStatus.done).length;
    final skipped =
        logs.where((l) => l.status == DoseStatus.skipped).length;
    final missed =
        logs.where((l) => l.status == DoseStatus.missed).length;
    final rate = total == 0 ? 0 : (done / total * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _StatChip(
            label: 'Adherence',
            value: '$rate%',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Taken',
            value: '$done',
            color: AppColors.done,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Skipped',
            value: '$skipped',
            color: AppColors.skipped,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Missed',
            value: '$missed',
            color: AppColors.missed,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
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

// ── Log list ──────────────────────────────────────────────

class _LogList extends StatelessWidget {
  const _LogList({required this.logs});
  final List<DoseLog> logs;

  @override
  Widget build(BuildContext context) {
    // Sort by date descending
    final sorted = [...logs]
      ..sort((a, b) => b.logDate.compareTo(a.logDate));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (context, index) => _LogTile(log: sorted[index]),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final DoseLog log;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (log.status) {
      DoseStatus.done => AppColors.done,
      DoseStatus.skipped => AppColors.skipped,
      DoseStatus.missed => AppColors.missed,
      DoseStatus.pending => AppColors.pending,
    };

    final statusLabel = switch (log.status) {
      DoseStatus.done => 'Taken',
      DoseStatus.skipped => 'Skipped',
      DoseStatus.missed => 'Missed',
      DoseStatus.pending => 'Pending',
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.medicationName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    DateFormat('MMM d').format(log.logDate),
                    if (log.scheduledTime != null) log.scheduledTime!,
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty view ────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📋', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            'No dose records this month',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Records will appear here after you\nstart tracking your medications.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}