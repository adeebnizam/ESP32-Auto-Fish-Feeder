class FeedingSchedule {
  const FeedingSchedule({
    required this.id,
    required this.hour,
    required this.minute,
    required this.portion,
    required this.enabled,
  });

  final String id;
  final int hour;
  final int minute;
  final int portion;
  final bool enabled;

  int get minutesSinceMidnight => hour * 60 + minute;

  factory FeedingSchedule.fromMap(String id, Map<Object?, Object?> map) {
    return FeedingSchedule(
      id: id,
      hour: (map['hour'] as num?)?.toInt() ?? 0,
      minute: (map['minute'] as num?)?.toInt() ?? 0,
      portion: (map['portion'] as num?)?.toInt() ?? 1,
      enabled: map['enabled'] as bool? ?? false,
    );
  }
}
