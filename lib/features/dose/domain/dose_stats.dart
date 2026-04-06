class MedicationStat {
  const MedicationStat({
    required this.medicationName,
    required this.rate,
    this.colorTag,
  });

  final String medicationName;
  final int rate;
  final String? colorTag;

  factory MedicationStat.fromMap(Map<String, dynamic> map) {
    return MedicationStat(
      medicationName: map['medication_name'] as String? ?? '',
      rate: map['rate'] as int? ?? 0,
      colorTag: map['color_tag'] as String?,
    );
  }
}

class DoseStats {
  const DoseStats({
    required this.period,
    required this.overallRate,
    required this.byMedication,
  });

  final String period;
  final int overallRate;
  final List<MedicationStat> byMedication;

  factory DoseStats.fromMap(Map<String, dynamic> map) {
    return DoseStats(
      period: map['period'] as String? ?? 'week',
      overallRate: map['overall_rate'] as int? ?? 0,
      byMedication: (map['by_medication'] as List<dynamic>? ?? [])
          .map((e) => MedicationStat.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}