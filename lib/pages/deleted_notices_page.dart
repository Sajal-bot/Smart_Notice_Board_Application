import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';

class DeletedNoticesPage extends StatelessWidget {
  const DeletedNoticesPage({super.key});

  /// 🔹 Combine deleted notices from both `notices` and `notices_fr`
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _mergedStream() {
    final frStream = FirebaseFirestore.instance
        .collection('notices_fr')
        .where('status', isEqualTo: 'Deleted')
        .orderBy('timestamp', descending: true)
        .snapshots();

    final normalStream = FirebaseFirestore.instance
        .collection('notices')
        .where('status', isEqualTo: 'Deleted')
        .orderBy('timestamp', descending: true)
        .snapshots();

    // ✅ FIX: Use Rx.combineLatest2 to merge both streams
    return Rx.combineLatest2<
        QuerySnapshot<Map<String, dynamic>>,
        QuerySnapshot<Map<String, dynamic>>,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      frStream,
      normalStream,
      (fr, normal) => [...fr.docs, ...normal.docs],
    );
  }

  /// Format Firestore Timestamp → readable text
  String _fmtTs(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
    }
    return '—';
  }

  /// "Deleted by" pill
  Widget _deletedByPill(String who) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8E7FF), Color(0xFFFFE6F1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Color(0xFFE9C8F7)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 16),
          const SizedBox(width: 6),
          Text(
            'Deleted by: $who',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Deleted Notices')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.surfaceVariant.withOpacity(.06),
              cs.secondary.withOpacity(.04),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: _mergedStream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('Trash is empty.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final doc = docs[i];
                final d = doc.data();

                final text = (d['text'] ??
                        d['notice'] ??
                        '[No text provided]')
                    .toString();
                final deletedAt = d['deleted_at'] ?? d['timestamp'];
                final whoRaw = (d['deleted_by'] ?? '').toString().trim();
                final who = whoRaw.isEmpty ? 'Unknown' : whoRaw;
                final source = doc.reference.parent.id; // "notices" or "notices_fr"

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text and metadata section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.35,
                                ),
                                softWrap: true,
                                maxLines: null,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Deleted • ${_fmtTs(deletedAt)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Source: $source',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _deletedByPill(who),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Buttons
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Restore Button
                            SizedBox(
                              width: 100,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  minimumSize: const Size(0, 0),
                                ),
                                onPressed: () async {
                                  await doc.reference.update({
                                    'status': 'Displayed',
                                    'deleted_by': FieldValue.delete(),
                                    'deleted_at': FieldValue.delete(),
                                  });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Restored')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.restore, size: 18),
                                label: const Text('Restore'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Delete Forever Button
                            SizedBox(
                              width: 100,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  minimumSize: const Size(0, 0),
                                  side: const BorderSide(color: Colors.red),
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete forever?'),
                                      content: const Text(
                                          'This cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await doc.reference.delete();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Deleted forever'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(
                                  Icons.delete_forever_outlined,
                                  size: 18,
                                ),
                                label: const Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
