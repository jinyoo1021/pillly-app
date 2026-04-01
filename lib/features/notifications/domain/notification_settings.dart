class NotificationSettings {
  const NotificationSettings({
    this.enabled = true,
    this.advanceMinutes = 0,
  });

  final bool enabled;
  final int advanceMinutes; // 0 | 5 | 10 | 15 | 30

  NotificationSettings copyWith({
    bool? enabled,
    int? advanceMinutes,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      advanceMinutes: advanceMinutes ?? this.advanceMinutes,
    );
  }
}