import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_notification.dart';

class NotificationRepo {
  static const _boxName = 'app_notifications';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PriorityAdapter());
      Hive.registerAdapter(AppNotificationAdapter());
    }
    await Hive.openBox<AppNotification>(_boxName);
  }

  static Box<AppNotification> get _box => Hive.box<AppNotification>(_boxName);

  static List<AppNotification> all() => _box.values.toList();

  static Future<void> upsert(AppNotification n) => _box.put(n.id, n);

  static Future<void> delete(String id) => _box.delete(id);
}
