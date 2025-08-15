import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CurrentNoticePage extends StatelessWidget {
  const CurrentNoticePage({super.key});

  // 🔹 Priority order map
  int _priorityOrder(String priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Normal':
        return 2;
      case 'Low':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Running Now"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .where('status', isEqualTo: 'Displayed')
            .orderBy('scheduled_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Copy and sort locally by priority
          final notices = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final pa = _priorityOrder((a['priority'] ?? 'Normal') as String);
              final pb = _priorityOrder((b['priority'] ?? 'Normal') as String);
              if (pa != pb) return pb.compareTo(pa); // sort High > Normal > Low
              return (b['scheduled_at'] ?? Timestamp.now())
                  .compareTo(a['scheduled_at'] ?? Timestamp.now());
            });

          if (notices.isEmpty) {
            return const Center(child: Text("No running notices."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final data = notices[index].data() as Map<String, dynamic>;

              final priority = data['priority'] ?? 'Normal';
              final status = data['status'] ?? 'Unknown';

              String scheduledAt = 'Not defined';
              if (data.containsKey('scheduled_at') &&
                  data['scheduled_at'] != null) {
                scheduledAt = DateFormat('dd MMM yyyy, hh:mm a')
                    .format(data['scheduled_at'].toDate());
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
                        data['text'] ?? '',
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
                                ? Colors.red[200]
                                : Colors.purple[100],
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
