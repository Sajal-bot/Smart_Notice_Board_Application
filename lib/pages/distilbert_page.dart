import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DistilBertPage extends StatefulWidget {
  const DistilBertPage({super.key});

  @override
  State<DistilBertPage> createState() => _DistilBertPageState();
}

class _DistilBertPageState extends State<DistilBertPage> {
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _mergedStream() async* {
    final notices = FirebaseFirestore.instance.collection('notices').snapshots();
    final noticesFr = FirebaseFirestore.instance.collection('notices_fr').snapshots();

    await for (final snap1 in notices) {
      final snap2 = await noticesFr.first;
      yield [...snap1.docs, ...snap2.docs];
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final date = ts.toDate();
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
          "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    return "—";
  }

<<<<<<< HEAD
  String _extractUserName(Map<String, dynamic> data) {
    final possibleKeys = [
      'user',
      'person',
      'userName',
      'username',
      'name',
      'createdByName',
      'displayName',
      'email',
      'createdBy',
    ];

    for (final key in possibleKeys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    final userData = data['userData'];
    if (userData is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        final value = userData[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }

    final userMap = data['userInfo'];
    if (userMap is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        final value = userMap[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }

    return "Unknown";
  }

=======
>>>>>>> 64ed81801480cd129f0fc1b5aa8a1aa17d014eda
  Future<void> _updatePriority(DocumentReference ref, String newPriority) async {
    await ref.update({'priority': newPriority});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Priority updated to $newPriority')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DistilBERT Priorities')),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _mergedStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
<<<<<<< HEAD

=======
>>>>>>> 64ed81801480cd129f0fc1b5aa8a1aa17d014eda
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No notices found.'));
          }

          docs.sort((a, b) {
            final ta = a.data()['timestamp'];
            final tb = b.data()['timestamp'];
            if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
            return 0;
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final ref = docs[i].reference;

              final text = (data['notice'] ?? data['text'] ?? '').toString();
<<<<<<< HEAD
              final user = _extractUserName(data);
              final status = (data['status'] ?? 'Pending').toString();
              final priority = (data['priority'] ?? 'Normal').toString();
              final ts = data['timestamp'];
              final source = ref.path.contains('notices_fr')
                  ? 'Face Recognition'
                  : 'App';
=======
              final user = (data['user'] ?? data['person'] ?? 'Unknown').toString();
              final status = (data['status'] ?? 'Pending').toString();
              final priority = (data['priority'] ?? 'Normal').toString();
              final ts = data['timestamp'];
              final source = ref.path.contains('notices_fr') ? 'Face Recognition' : 'App';
>>>>>>> 64ed81801480cd129f0fc1b5aa8a1aa17d014eda

              Color badgeColor;
              switch (priority.toLowerCase()) {
                case 'high':
                  badgeColor = Colors.red.shade100;
                  break;
                case 'low':
                  badgeColor = Colors.green.shade100;
                  break;
                default:
                  badgeColor = Colors.purple.shade100;
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    text,
<<<<<<< HEAD
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
=======
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
>>>>>>> 64ed81801480cd129f0fc1b5aa8a1aa17d014eda
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Source: $source'),
                        Text('User: $user'),
                        Text('Status: $status'),
                        Text('Time: ${_formatTimestamp(ts)}'),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
<<<<<<< HEAD
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
=======
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
>>>>>>> 64ed81801480cd129f0fc1b5aa8a1aa17d014eda
                          child: Text(
                            'Priority: $priority',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _updatePriority(ref, value),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'High', child: Text('High')),
                      PopupMenuItem(value: 'Medium', child: Text('Medium')),
                      PopupMenuItem(value: 'Low', child: Text('Low')),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 64ed81801480cd129f0fc1b5aa8a1aa17d014eda
