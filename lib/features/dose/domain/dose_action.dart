class DoseConfirmRequest {
  const DoseConfirmRequest({
    required this.scheduleId,
    required this.logDate,
  });

  final String scheduleId;
  final String logDate; // "yyyy-MM-dd"

  Map<String, dynamic> toMap() => {
    'schedule_id': scheduleId,
    'log_date': logDate,
  };
}

class DoseSkipRequest {
  const DoseSkipRequest({
    required this.scheduleId,
    required this.logDate,
  });

  final String scheduleId;
  final String logDate;

  Map<String, dynamic> toMap() => {
    'schedule_id': scheduleId,
    'log_date': logDate,
  };
}