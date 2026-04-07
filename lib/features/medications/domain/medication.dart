enum CycleType { daily, weekly, interval }

class Medication {
  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.cycleType,
    required this.scheduledTimes,
    this.dosage,
    this.unit,
    this.intervalDays,
    this.weekdays,
    this.memo,
    this.isActive = true,
  });

  final String id;
  final String userId;
  final String name;
  final CycleType cycleType;
  final List<String> scheduledTimes;
  final double? dosage;
  final String? unit;
  final int? intervalDays;
  final List<int>? weekdays;
  final String? memo;
  final bool isActive;

  static CycleType parseCycleType(String value) {
    return switch (value) {
      'weekly' => CycleType.weekly,
      'interval' => CycleType.interval,
      _ => CycleType.daily,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    // Extract scheduled_times from nested schedules array
    final schedulesList = map['schedules'] as List<dynamic>? ?? [];
    final activeSchedules = schedulesList
        .where((s) => s['is_active'] == true)
        .toList();
    final scheduledTimes = activeSchedules
        .map((s) => (s['scheduled_time'] as String).substring(0, 5))
        .toList();

    // Get cycle_type from first schedule if not at root level
    final cycleTypeStr = map['cycle_type'] as String? ??
        (schedulesList.isNotEmpty
            ? schedulesList.first['cycle_type'] as String? ?? 'daily'
            : 'daily');

    List<int>? weekdays;
    if (map['weekdays'] != null) {
      weekdays = List<int>.from(map['weekdays']);
    } else if (activeSchedules.isNotEmpty) {
      final cycleValue = activeSchedules.first['cycle_value'];
      if (cycleValue is Map && cycleValue['weekdays'] != null) {
        weekdays = List<int>.from(cycleValue['weekdays']);
      }
    }

    return Medication(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String,
      cycleType: parseCycleType(cycleTypeStr),
      scheduledTimes: scheduledTimes,
      dosage: map['dosage'] != null
          ? double.tryParse(map['dosage'].toString())
          : null,
      unit: map['unit'] as String?,
      intervalDays: map['interval_days'] as int?,
      weekdays: weekdays,
      memo: map['memo'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Medication copyWith({
    String? name,
    bool? isActive,
    double? dosage,
    String? unit,
    String? memo,
    List<String>? scheduledTimes,
  }) {
    return Medication(
      id: id,
      userId: userId,
      name: name ?? this.name,
      cycleType: cycleType,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      intervalDays: intervalDays,
      weekdays: weekdays,
      memo: memo ?? this.memo,
      isActive: isActive ?? this.isActive,
    );
  }
}

class MedicationCreateRequest {
  const MedicationCreateRequest({
    required this.name,
    required this.cycleType,
    required this.scheduledTimes,
    this.dosage,
    this.unit,
    this.intervalDays,
    this.weekdays,
    this.memo,
  });

  final String name;
  final CycleType cycleType;
  final List<String> scheduledTimes;
  final double? dosage;
  final String? unit;
  final int? intervalDays;
  final List<int>? weekdays;
  final String? memo;

  Map<String, dynamic> toMap() {
    Map<String, dynamic>? cycleValue;
    if (cycleType == CycleType.weekly && weekdays != null) {
      cycleValue = {'weekdays': weekdays};
    } else if (cycleType == CycleType.interval && intervalDays != null) {
      cycleValue = {'interval_days': intervalDays};
    }

    final schedules = scheduledTimes.map((time) {
      final entry = <String, dynamic>{
        'scheduled_time': time,
        'cycle_type': cycleType.name,
      };
      if (cycleValue != null) entry['cycle_value'] = cycleValue;
      return entry;
    }).toList();

    final map = <String, dynamic>{
      'name': name,
      'schedules': schedules,
    };
    if (dosage != null) map['dosage'] = dosage.toString();
    if (memo != null && memo!.isNotEmpty) map['memo'] = memo;
    return map;
  }
}

class MedicationUpdateRequest {
  const MedicationUpdateRequest({
    this.name,
    this.cycleType,
    this.scheduledTimes,
    this.dosage,
    this.unit,
    this.intervalDays,
    this.weekdays,
    this.memo,
  });

  final String? name;
  final CycleType? cycleType;
  final List<String>? scheduledTimes;
  final double? dosage;
  final String? unit;
  final int? intervalDays;
  final List<int>? weekdays;
  final String? memo;

  Map<String, dynamic> toMap() {
    Map<String, dynamic>? cycleValue;
    if (cycleType == CycleType.weekly && weekdays != null) {
      cycleValue = {'weekdays': weekdays};
    } else if (cycleType == CycleType.interval && intervalDays != null) {
      cycleValue = {'interval_days': intervalDays};
    }

    List<Map<String, dynamic>>? schedules;
    if (scheduledTimes != null && cycleType != null) {
      schedules = scheduledTimes!.map((time) {
        final entry = <String, dynamic>{
          'scheduled_time': time,
          'cycle_type': cycleType!.name,
        };
        if (cycleValue != null) entry['cycle_value'] = cycleValue;
        return entry;
      }).toList();
    }

    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (schedules != null) map['schedules'] = schedules;
    if (dosage != null) map['dosage'] = dosage.toString();
    if (memo != null) map['memo'] = memo;
    return map;
  }
}