import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CurrentNoticePage extends StatelessWidget {
  const CurrentNoticePage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() => FirebaseFirestore
      .instance
      .collection('notices')
      .where('status', isEqualTo: 'Displayed')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots();

  String _fmtTs(dynamic ts) =>
      ts is Timestamp ? ts.toDate().toString().split('.').first : '—';

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
              return const Center(
                child: Text('No notice is currently displayed.'),
              );
            }
            final d = docs.first.data();

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
                        d['text'] ?? '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              'Priority: ${d['priority'] ?? 'Normal'}',
                            ),
                          ),
                          Chip(
                            label: Text(
                              'Status: ${d['status'] ?? 'Displayed'}',
                            ),
                          ),
                          Chip(label: Text('When: ${_fmtTs(d['timestamp'])}')),
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
