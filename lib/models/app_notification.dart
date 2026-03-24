import 'package:hive/hive.dart';

part 'app_notification.g.dart';

@HiveType(typeId: 0)
enum Priority {
  @HiveField(0)
  low,
  @HiveField(1)
  normal,
  @HiveField(2)
  high,
}

@HiveType(typeId: 1)
class AppNotification extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  Priority priority;

  @HiveField(4)
  DateTime startTime;

  @HiveField(5)
  int durationMinutes;

  @HiveField(6)
  int frequencyMinutes;

  @HiveField(7)
  bool enabled;

  AppNotification({
    required this.id,
    required this.text,
    required this.colorValue,
    required this.priority,
    required this.startTime,
    required this.durationMinutes,
    required this.frequencyMinutes,
    this.enabled = true,
  });

  Duration get duration => Duration(minutes: durationMinutes);
  Duration get frequency => Duration(minutes: frequencyMinutes);
}
