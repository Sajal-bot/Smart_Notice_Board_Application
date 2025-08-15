import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeletedNoticesPage extends StatelessWidget {
  const DeletedNoticesPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() => FirebaseFirestore
      .instance
      .collection('notices')
      .where('status', isEqualTo: 'Deleted')
      .orderBy('timestamp', descending: true) // stable ordering
      .snapshots();

  String _fmtTs(dynamic ts) =>
      ts is Timestamp ? ts.toDate().toString().split('.').first : '—';

  // 🌸 Pastel "Deleted by" pill (always shows; falls back to 'Unknown')
  Widget _deletedByPill(String who) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8E7FF), Color(0xFFFFE6F1)], // lavender → pink
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
      appBar: AppBar(title: const Text('Deleted Notices')), // no const AppBar
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
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _stream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty)
              return const Center(child: Text('Trash is empty.'));

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final doc = docs[i];
                final d = doc.data();

                final text = (d['text'] ?? '').toString();
                final deletedAt = d['deleted_at'] ?? d['timestamp'];
                final whoRaw = (d['deleted_by'] ?? '').toString().trim();
                final who = whoRaw.isEmpty ? 'Unknown' : whoRaw; // ← fallback

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
                        // Text area with the notice content
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
                              const SizedBox(height: 6),
                              _deletedByPill(who), // Always show deleted by info
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Column for the actions (Restore & Delete buttons)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // **Restore Button**:
                            // This button will restore the deleted notice to 'Pending' status.
                            SizedBox(
                              width: 100, // Fixed width to ensure both buttons are the same
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 0),
                                ),
                                onPressed: () async {
                                  await doc.reference.update({
                                    'status': 'Pending',
                                    'deleted_by': FieldValue.delete(),
                                    'deleted_at': FieldValue.delete(),
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Restored')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.restore, size: 18),
                                label: const Text('Restore'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // **Delete Button**:
                            // This button will permanently delete the notice from the database.
                            // It shows a confirmation dialog before proceeding with the deletion.
                            SizedBox(
                              width: 100, // Same fixed width as Restore button
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 0),
                                  side: BorderSide(color: Colors.red),  // Red border
                                  foregroundColor: Colors.red,  // Red text and icon
                                ),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete forever?'),
                                      content: const Text(
                                        'This cannot be undone.',
                                      ),
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
                                  if (ok == true) await doc.reference.delete();
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
