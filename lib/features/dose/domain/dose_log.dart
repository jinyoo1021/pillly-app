import '../../schedules/domain/schedule.dart';

class DoseLog {
  const DoseLog({
    required this.id,
    required this.scheduleId,
    required this.medicationName,
    required this.logDate,
    required this.status,
    this.scheduledTime,
    this.takenAt,
  });

  final String id;
  final String scheduleId;
  final String medicationName;
  final DateTime logDate;
  final DoseStatus status;
  final String? scheduledTime;
  final DateTime? takenAt;

  factory DoseLog.fromMap(Map<String, dynamic> map) {
    return DoseLog(
      id: map['id'] as String? ?? '',
      scheduleId: map['schedule_id'] as String? ?? '',
      medicationName: map['medication_name'] as String? ?? '',
      logDate: DateTime.parse(map['log_date'] as String),
      status: DoseStatus.values.firstWhere(
            (s) => s.name == (map['status'] as String? ?? 'pending'),
        orElse: () => DoseStatus.pending,
      ),
      scheduledTime: map['scheduled_time'] as String?,
      takenAt: map['taken_at'] != null
          ? DateTime.parse(map['taken_at'] as String)
          : null,
    );
  }
}