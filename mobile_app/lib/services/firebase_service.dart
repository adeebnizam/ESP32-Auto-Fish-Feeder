import 'package:firebase_database/firebase_database.dart';

import '../models/feeding_schedule.dart';

class FirebaseService {
  FirebaseService({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  static const feederId = 'feeder_001';

  final FirebaseDatabase _database;

  DatabaseReference get _deviceRef => _database.ref('devices/$feederId');

  DatabaseReference get _commandsRef => _database.ref('commands/$feederId');

  DatabaseReference get _schedulesRef => _database.ref('schedules/$feederId');

  Stream<bool> get feederOnlineStream => _deviceRef
      .child('online')
      .onValue
      .map((event) => event.snapshot.value == true);

  Stream<DateTime?> get lastFeedAtStream =>
      _deviceRef.child('lastFeedAt').onValue.map((event) {
        final value = event.snapshot.value;
        if (value is num) {
          return DateTime.fromMillisecondsSinceEpoch(value.toInt());
        }
        return null;
      });

  Stream<List<FeedingSchedule>> get schedulesStream =>
      _schedulesRef.onValue.map((event) {
        final value = event.snapshot.value;
        if (value is! Map) return <FeedingSchedule>[];

        return value.entries
            .map(
              (entry) => FeedingSchedule.fromMap(
                entry.key.toString(),
                Map<Object?, Object?>.from(entry.value as Map),
              ),
            )
            .where((schedule) => schedule.enabled)
            .toList()
          ..sort(
            (a, b) => a.minutesSinceMidnight.compareTo(b.minutesSinceMidnight),
          );
      });

  Future<String> queueFeedCommand({int amount = 1}) async {
    final command = _commandsRef.push();
    final commandId = command.key;
    if (commandId == null) {
      throw StateError('Firebase could not generate a command ID.');
    }

    await command.set({
      'commandId': commandId,
      'type': 'feed',
      'amount': amount,
      'createdAt': ServerValue.timestamp,
      'status': 'pending',
    });
    return commandId;
  }

  Future<void> saveSchedule({
    required int hour,
    required int minute,
    required int portion,
  }) async {
    final schedule = _schedulesRef.push();
    await schedule.set({
      'enabled': true,
      'hour': hour,
      'minute': minute,
      'portion': portion,
    });
  }

  Future<void> deleteSchedule(String scheduleId) =>
      _schedulesRef.child(scheduleId).remove();
}
