enum DoseStatus { pending, done, skipped, missed }

class TodaySchedule {
  const TodaySchedule({
    required this.scheduleId,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    required this.status,
    this.dosage,
    this.unit,
    this.doseLogId,
  });

  final String scheduleId;
  final String medicationId;
  final String medicationName;
  final String scheduledTime;
  final DoseStatus status;
  final double? dosage;
  final String? unit;
  final String? doseLogId;

  static DoseStatus parseStatus(String value) {
    return switch (value) {
      'done' => DoseStatus.done,
      'skipped' => DoseStatus.skipped,
      'missed' => DoseStatus.missed,
      _ => DoseStatus.pending,
    };
  }

  factory TodaySchedule.fromMap(Map<String, dynamic> map) {
    return TodaySchedule(
      scheduleId: map['schedule_id'] as String,
      medicationId: map['medication_id'] as String? ?? '',
      medicationName: map['medication_name'] as String,
      scheduledTime: map['scheduled_time'] as String,
      status: parseStatus(map['status'] as String? ?? 'pending'),
      dosage: (map['dosage'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      doseLogId: map['dose_log_id'] as String?,
    );
  }

  TodaySchedule copyWith({DoseStatus? status, String? doseLogId}) {
    return TodaySchedule(
      scheduleId: scheduleId,
      medicationId: medicationId,
      medicationName: medicationName,
      scheduledTime: scheduledTime,
      status: status ?? this.status,
      dosage: dosage,
      unit: unit,
      doseLogId: doseLogId ?? this.doseLogId,
    );
  }
}