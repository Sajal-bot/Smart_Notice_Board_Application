// lib/notice_status_updater.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeStatusUpdater {
  NoticeStatusUpdater._();
  static final NoticeStatusUpdater instance = NoticeStatusUpdater._();

  Timer? _timer;

  // Estimated server - device time difference (serverNow - deviceNow).
  static Duration _clockSkew = Duration.zero;

  void start({Duration every = const Duration(seconds: 10)}) async {
    _timer?.cancel();
    await _syncServerClockSkew(); // one-time calibration
    // No immediate run to avoid flipping right after creation
    _timer = Timer.periodic(every, (_) => sweepPendingOnce());
  }

  void stop() => _timer?.cancel();

  static Future<void> sweepPendingOnce() async {
    final q = await FirebaseFirestore.instance
        .collection('notices')
        .where('status', isEqualTo: 'Pending')
        .get();

    for (final doc in q.docs) {
      await checkAndUpdateNoticeStatus(doc);
    }
  }

  static Future<void> checkAndUpdateNoticeStatus(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    if (data == null) return;

    final status = (data['status'] ?? '') as String;

    // Accept 'scheduled_at' (preferred) or fallback to 'timestamp'.
    final rawWhen = data['scheduled_at'] ?? data['timestamp'];
    final whenUtc = _toUtc(rawWhen);
    if (whenUtc == null) return;

    // Use server-adjusted "now"
    final nowUtc = DateTime.now().toUtc().add(_clockSkew);

    // STRICT check: only update if now >= scheduled time
    if (status == 'Pending' && !nowUtc.isBefore(whenUtc)) {
      await doc.reference.update({
        'status': 'Displayed',
        'displayedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static DateTime? _toUtc(dynamic v) {
    if (v is Timestamp) return v.toDate().toUtc();
    if (v is DateTime) return v.toUtc();
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed == null) return null;
      return parsed.isUtc ? parsed : parsed.toUtc();
    }
    return null;
  }

  static Future<void> _syncServerClockSkew() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('__meta')
          .doc('__clock');

      await ref.set({'now': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      final snap = await ref.get(const GetOptions(source: Source.server));
      final ts = snap.data()?['now'];
      final serverNowUtc =
          ts is Timestamp ? ts.toDate().toUtc() : DateTime.now().toUtc();

      final deviceNowUtc = DateTime.now().toUtc();
      _clockSkew = serverNowUtc.difference(deviceNowUtc);
    } catch (_) {
      _clockSkew = Duration.zero;
    }
  }
}
