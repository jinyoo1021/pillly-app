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
    return Medication(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      cycleType: parseCycleType(map['cycle_type'] as String),
      scheduledTimes: List<String>.from(map['scheduled_times'] ?? []),
      dosage: (map['dosage'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      intervalDays: map['interval_days'] as int?,
      weekdays: map['weekdays'] != null
          ? List<int>.from(map['weekdays'])
          : null,
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
    return {
      'name': name,
      'cycle_type': cycleType.name,
      'scheduled_times': scheduledTimes,
      if (dosage != null) 'dosage': dosage,
      if (unit != null && unit!.isNotEmpty) 'unit': unit,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (weekdays != null) 'weekdays': weekdays,
      if (memo != null && memo!.isNotEmpty) 'memo': memo,
    };
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
    return {
      if (name != null) 'name': name,
      if (cycleType != null) 'cycle_type': cycleType!.name,
      if (scheduledTimes != null) 'scheduled_times': scheduledTimes,
      if (dosage != null) 'dosage': dosage,
      if (unit != null) 'unit': unit,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (weekdays != null) 'weekdays': weekdays,
      if (memo != null) 'memo': memo,
    };
  }
}