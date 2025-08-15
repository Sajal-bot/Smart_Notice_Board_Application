// lib/notice_status_updater.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeStatusUpdater {
  NoticeStatusUpdater._();
  static final NoticeStatusUpdater instance = NoticeStatusUpdater._();

  Timer? _timer;

  // Estimated server - device time difference (serverNow - deviceNow).
  static Duration _clockSkew = Duration.zero;

  // <-- Add a small grace to avoid early flips from skew / jitter.
  static const Duration _grace = Duration(seconds: 75);

  void start({Duration every = const Duration(minutes: 1)}) async {
    _timer?.cancel();
    await _syncServerClockSkew();      // one-time calibration
    await sweepPendingOnce();          // run immediately
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

    // Accept 'scheduledAt' (preferred) or fallback to 'timestamp'.
    final rawWhen = data['scheduledAt'] ?? data['timestamp'];
    final whenUtc = _toUtc(rawWhen);
    if (whenUtc == null) return;

    // Use server-adjusted "now"
    final nowUtc = DateTime.now().toUtc().add(_clockSkew);

    // >>> Only flip *after* scheduled time + grace
    if (status == 'Pending' && nowUtc.isAfter(whenUtc.add(_grace))) {
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
