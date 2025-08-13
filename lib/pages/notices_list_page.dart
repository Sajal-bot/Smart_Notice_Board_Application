import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NoticesListPage extends StatelessWidget {
  const NoticesListPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    return FirebaseFirestore.instance
        .collection('notices')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  String _fmtTs(dynamic ts) =>
      ts is Timestamp ? ts.toDate().toString().split('.').first : '—';

  Color _priorityColor(BuildContext ctx, String p) {
    final cs = Theme.of(ctx).colorScheme;
    return p == 'High'
        ? Colors.red.shade100
        : p == 'Low'
        ? Colors.green.shade100
        : cs.secondaryContainer.withOpacity(.6);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Displayed':
        return Colors.blue.shade100;
      case 'Archived':
        return Colors.grey.shade300;
      case 'Deleted':
        return Colors.red.shade200;
      default:
        return Colors.amber.shade100; // Pending
    }
  }

  // ---- Name helpers ---------------------------------------------------------

  String _titleCase(String input) {
    final parts = input.split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    return parts
        .map(
          (w) => w.length == 1
              ? w.toUpperCase()
              : '${w[0].toUpperCase()}${w.substring(1)}',
        )
        .join(' ');
  }

  String _deriveNameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'User';
    final local = email.split('@').first;
    // Replace separators with spaces, keep digits if any
    final cleaned = local.replaceAll(RegExp(r'[._\-]+'), ' ').trim();
    return _titleCase(cleaned);
  }

  // Pick best display label for current user: name → username → displayName → email(local-part) → uid
  Future<String> _currentUserLabel() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return 'User';
    final uid = u.uid;

    try {
      final prof = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = prof.data();
      if (data != null) {
        final name = (data['name'] ?? '').toString().trim();
        if (name.isNotEmpty) return name;
        final username = (data['username'] ?? '').toString().trim();
        if (username.isNotEmpty) return username;
      }
    } catch (_) {}

    final dn = (u.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    final em = (u.email ?? '').trim();
    if (em.isNotEmpty) {
      final friendly = _deriveNameFromEmail(em);
      // Persist for next time
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': friendly,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
      return friendly;
    }

    return uid; // last fallback
  }

  // ---- Status update (adds deleted_by as NAME only) -------------------------

  Future<void> _updateStatus(DocumentReference ref, String status) async {
    if (status == 'Deleted') {
      final who = await _currentUserLabel(); // <- NAME, not email
      await ref.update({
        'status': 'Deleted',
        'deleted_by': who,
        'deleted_at': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'status': status,
        'deleted_by': FieldValue.delete(),
        'deleted_at': FieldValue.delete(),
      });
    }
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('All Notices')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(.05),
              cs.surfaceVariant.withOpacity(.05),
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
              return const Center(child: Text('No notices yet.'));

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final doc = docs[i];
                final d = doc.data();
                final pr = (d['priority'] ?? 'Normal') as String;
                final st = (d['status'] ?? 'Pending') as String;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _priorityColor(context, pr),
                      child: Icon(
                        pr == 'High'
                            ? Icons.priority_high
                            : pr == 'Low'
                            ? Icons.low_priority
                            : Icons.label_important_outline,
                        color: Colors.black87,
                      ),
                    ),
                    title: Text(d['text'] ?? ''),
                    subtitle: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text('Priority: $pr'),
                          backgroundColor: _priorityColor(context, pr),
                        ),
                        Chip(
                          label: Text('Status: $st'),
                          backgroundColor: _statusColor(st),
                        ),
                        Chip(label: Text(_fmtTs(d['timestamp']))),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (v) async {
                        await _updateStatus(doc.reference, v);
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Marked $v')));
                        }
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(
                          value: 'Displayed',
                          child: ListTile(
                            leading: Icon(Icons.play_circle_outline),
                            title: Text('Mark as Displayed'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Archived',
                          child: ListTile(
                            leading: Icon(Icons.archive_outlined),
                            title: Text('Archive'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Deleted',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Move to Deleted'),
                          ),
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
