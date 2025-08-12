import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubmitNoticePage extends StatefulWidget {
  const SubmitNoticePage({super.key});
  @override
  State<SubmitNoticePage> createState() => _SubmitNoticePageState();
}

class _SubmitNoticePageState extends State<SubmitNoticePage> {
  final _text = TextEditingController();
  String _priority = 'Normal';
  DateTime? _scheduledAt;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final txt = _text.text.trim();
    if (txt.isEmpty) return;
    setState(() => _busy = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('notices').add({
        'text': txt,
        'priority': _priority,
        'status': 'Pending',
        'user_id': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'scheduled_at': _scheduledAt == null
            ? null
            : Timestamp.fromDate(_scheduledAt!),
        'source': 'app',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notice submitted')));
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom; // keyboard

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Notice')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withOpacity(.06),
              cs.secondary.withOpacity(.06),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _text,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Write your notice',
                          hintText: 'Type here…',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ⬇️ Wrap avoids horizontal overflow on small screens
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width:
                                360, // gives room on large screens, will be clamped on small
                            child: DropdownButtonFormField<String>(
                              value: _priority,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Low',
                                  child: Text('Low'),
                                ),
                                DropdownMenuItem(
                                  value: 'Normal',
                                  child: Text('Normal'),
                                ),
                                DropdownMenuItem(
                                  value: 'High',
                                  child: Text('High'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _priority = v ?? 'Normal'),
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickSchedule,
                            icon: const Icon(Icons.schedule),
                            label: Text(
                              _scheduledAt == null
                                  ? 'Schedule (optional)'
                                  : _scheduledAt!
                                        .toLocal()
                                        .toString()
                                        .split('.')
                                        .first,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  const Chip(
                    label: Text('Tip: You can schedule a future time'),
                  ),
                  Chip(
                    label: Text('Priority: $_priority'),
                    backgroundColor: _priority == 'High'
                        ? Colors.red[100]
                        : _priority == 'Low'
                        ? Colors.green[100]
                        : Colors.amber[100],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
