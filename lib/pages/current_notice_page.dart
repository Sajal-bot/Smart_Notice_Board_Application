import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:notify_app/notice_status_updater.dart'; // <-- make sure this file exists

class CurrentNoticePage extends StatelessWidget {
  const CurrentNoticePage({super.key});

  /// Stream the most recently Displayed notice
  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() => FirebaseFirestore
      .instance
      .collection('notices')
      .where('status', isEqualTo: 'Displayed')
      .orderBy('displayedAt', descending: true)
      .limit(1)
      .snapshots();

  String _fmtTs(dynamic ts) =>
      ts is Timestamp ? ts.toDate().toString().split('.').first : '—';

  Future<void> _checkAndUpdateNoticeStatus(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await NoticeStatusUpdater.checkAndUpdateNoticeStatus(doc);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Running Now')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary.withOpacity(.05), cs.tertiary.withOpacity(.06)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _stream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No notice is currently displayed.'));
            }

            final doc = docs.first;
            final d = doc.data();

            // Optional: safety check if status should flip
            SchedulerBinding.instance.addPostFrameCallback((_) async {
              await _checkAndUpdateNoticeStatus(doc);
            });

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: cs.primaryContainer,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (d['text'] ?? '') as String,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text('Priority: ${d['priority'] ?? 'Normal'}')),
                          Chip(label: Text('Status: ${d['status'] ?? 'Displayed'}')),
                          Chip(label: Text('When: ${_fmtTs(d['displayedAt'] ?? d['timestamp'])}')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
