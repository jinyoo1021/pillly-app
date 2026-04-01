class WeeklyStats {
  const WeeklyStats({
    required this.weekLabel,
    required this.total,
    required this.done,
  });

  final String weekLabel; // "Mar 24 – Mar 30"
  final int total;
  final int done;

  double get adherenceRate => total == 0 ? 0 : done / total;

  factory WeeklyStats.fromMap(Map<String, dynamic> map) {
    return WeeklyStats(
      weekLabel: map['week_label'] as String? ?? '',
      total: map['total'] as int? ?? 0,
      done: map['done'] as int? ?? 0,
    );
  }
}

class MonthlyStats {
  const MonthlyStats({
    required this.monthLabel,
    required this.total,
    required this.done,
    required this.skipped,
    required this.missed,
  });

  final String monthLabel; // "March 2026"
  final int total;
  final int done;
  final int skipped;
  final int missed;

  double get adherenceRate => total == 0 ? 0 : done / total;

  factory MonthlyStats.fromMap(Map<String, dynamic> map) {
    return MonthlyStats(
      monthLabel: map['month_label'] as String? ?? '',
      total: map['total'] as int? ?? 0,
      done: map['done'] as int? ?? 0,
      skipped: map['skipped'] as int? ?? 0,
      missed: map['missed'] as int? ?? 0,
    );
  }
}

class DoseStats {
  const DoseStats({
    required this.period,
    required this.totalDoses,
    required this.doneDoses,
    required this.skippedDoses,
    required this.missedDoses,
    required this.weeklyBreakdown,
    required this.monthlyBreakdown,
  });

  final String period; // 'week' | 'month'
  final int totalDoses;
  final int doneDoses;
  final int skippedDoses;
  final int missedDoses;
  final List<WeeklyStats> weeklyBreakdown;
  final List<MonthlyStats> monthlyBreakdown;

  double get adherenceRate =>
      totalDoses == 0 ? 0 : doneDoses / totalDoses;

  factory DoseStats.fromMap(Map<String, dynamic> map) {
    return DoseStats(
      period: map['period'] as String? ?? 'week',
      totalDoses: map['total_doses'] as int? ?? 0,
      doneDoses: map['done_doses'] as int? ?? 0,
      skippedDoses: map['skipped_doses'] as int? ?? 0,
      missedDoses: map['missed_doses'] as int? ?? 0,
      weeklyBreakdown: (map['weekly_breakdown'] as List<dynamic>? ?? [])
          .map((e) => WeeklyStats.fromMap(e as Map<String, dynamic>))
          .toList(),
      monthlyBreakdown:
      (map['monthly_breakdown'] as List<dynamic>? ?? [])
          .map((e) =>
          MonthlyStats.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}