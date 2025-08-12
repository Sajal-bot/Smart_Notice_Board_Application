import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeletedNoticesPage extends StatelessWidget {
  const DeletedNoticesPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() => FirebaseFirestore
      .instance
      .collection('notices')
      .where('status', isEqualTo: 'Deleted')
      .orderBy('timestamp', descending: true)
      .snapshots();

  String _fmtTs(dynamic ts) =>
      ts is Timestamp ? ts.toDate().toString().split('.').first : '—';

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

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(d['text'] ?? ''),
                    subtitle: Text('Deleted • ${_fmtTs(d['timestamp'])}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            await doc.reference.update({'status': 'Pending'});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Restored')),
                              );
                            }
                          },
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore'),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete forever?'),
                                content: const Text('This cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await doc.reference.delete();
                            }
                          },
                          icon: const Icon(Icons.delete_forever_outlined),
                          label: const Text('Delete'),
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
