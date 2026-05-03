// lib/pages/notices_fr_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NoticesFRPage extends StatelessWidget {
  const NoticesFRPage({super.key});

  Future<void> _confirmAndMoveToDeleted(
      BuildContext context, String docId, String user) async {
    final shouldMove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Move to Deleted"),
        content: const Text(
          "Are you sure you want to move this notice to Deleted?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              "Confirm",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldMove == true) {
      try {
        await FirebaseFirestore.instance
            .collection('notices_fr')
            .doc(docId)
            .update({
          'status': 'Deleted',
          'deleted_at': FieldValue.serverTimestamp(),
          'deleted_by': user,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Notice moved to Deleted")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Operation failed: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notices (FR)")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices_fr')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notices = snapshot.data!.docs;
          if (notices.isEmpty) {
            return const Center(child: Text("No FR notices yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final doc = notices[index];
              final data = doc.data() as Map<String, dynamic>;

              final text = (data['text'] ?? data['notice'] ?? '').toString();
              final user =
                  (data['user'] ?? data['person'] ?? 'Unknown').toString();
              final status = (data['status'] ?? 'Displayed').toString();

              String scheduledAt = 'Not defined';
              final ts = data['timestamp'];
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
                      // Title + menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              text,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _confirmAndMoveToDeleted(context, doc.id, user);
                              }
                            },
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline),
                                    SizedBox(width: 6),
                                    Text('Move to Deleted'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Chips (User, Status, Scheduled)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              'User: $user',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.green[100],
                          ),
                          Chip(
                            label: Text(
                              'Status: $status',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: status == 'Deleted'
                                ? Colors.red[100]
                                : Colors.blue[100],
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
