import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/models/feeding_schedule.dart';

void main() {
  test('parses and sorts schedule values', () {
    final schedule = FeedingSchedule.fromMap('schedule_001', {
      'enabled': true,
      'hour': 8,
      'minute': 30,
      'portion': 2,
    });

    expect(schedule.id, 'schedule_001');
    expect(schedule.minutesSinceMidnight, 510);
    expect(schedule.portion, 2);
    expect(schedule.enabled, isTrue);
  });
}
