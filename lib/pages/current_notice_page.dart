import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class CurrentNoticePage extends StatelessWidget {
  const CurrentNoticePage({super.key});

  // 🔹 Priority order map
  int _priorityOrder(String priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 0;
    }
  }

  /// 🔹 Combine normal notices + FR notices (Displayed only)
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _mergedStream() {
    final normalStream = FirebaseFirestore.instance
        .collection('notices')
        .where('status', isEqualTo: 'Displayed')
        .orderBy('scheduled_at', descending: true)
        .snapshots();

    final frStream = FirebaseFirestore.instance
        .collection('notices_fr')
        .where('status', isEqualTo: 'Displayed')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Rx.combineLatest2<
        QuerySnapshot<Map<String, dynamic>>,
        QuerySnapshot<Map<String, dynamic>>,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      normalStream,
      frStream,
      (normal, fr) => [...normal.docs, ...fr.docs],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Running Now"),
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _mergedStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notices = snapshot.data!.toList()
            ..sort((a, b) {
              final pa =
                  _priorityOrder((a.data()['priority'] ?? 'Normal') as String);
              final pb =
                  _priorityOrder((b.data()['priority'] ?? 'Normal') as String);
              if (pa != pb) return pb.compareTo(pa);
              return (b.data()['scheduled_at'] ?? b.data()['timestamp'] ?? Timestamp.now())
                  .compareTo(a.data()['scheduled_at'] ?? a.data()['timestamp'] ?? Timestamp.now());
            });

          if (notices.isEmpty) {
            return const Center(child: Text("No running notices."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final data = notices[index].data();

              final text = (data['text'] ?? data['notice'] ?? '').toString();
              final priority = (data['priority'] ?? 'Normal').toString();
              final status = (data['status'] ?? 'Displayed').toString();

              String scheduledAt = 'Not defined';
              final ts = data['scheduled_at'] ?? data['timestamp'];
              if (ts != null && ts is Timestamp) {
                scheduledAt =
                    DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
              }

              return Card(
                color: const Color(0xFFF8F3FF),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              'Priority: $priority',
                              style: const TextStyle(fontSize: 12),
                            ),
                          backgroundColor: priority == 'High'
                              ? Colors.red[100]
                              : priority == 'Medium'
                                  ? Colors.purple[100]
                                  : Colors.green[100],
                          ),
                          Chip(
                            label: Text(
                              'Status: $status',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue[100],
                          ),
                          Chip(
                            label: Text(
                              'Scheduled at: $scheduledAt',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
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
    );
  }
}
