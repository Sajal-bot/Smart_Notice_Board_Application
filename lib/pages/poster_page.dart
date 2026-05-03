// lib/pages/poster_page.dart
//
// Posters page with:
// ✅ Cloudinary upload (unsigned preset)
// ✅ Ask for Poster Title (heading)
// ✅ Ask for Scheduled time
// ✅ Store in Firestore: title, imageUrl, status, scheduledAt, user info
// ✅ 3-dots menu: user name, scheduled time, change status (Pending/Displayed), delete
// ✅ Auto-change Pending -> Displayed when scheduled time is reached (WHILE APP IS RUNNING)
//
// IMPORTANT:
// - Firestore collection name used: posters
// - Fields expected/created:
//   title (String)
//   imageUrl (String)
//   publicId (String)
//   status (String: "Pending"/"Displayed")
//   createdAt (Timestamp)
//   scheduledAt (Timestamp)
//   displayedAt (Timestamp?) optional
//   userId (String)
//   userName (String)
//
// Cloudinary:
// - cloudName must be your "cloud name" (res.cloudinary.com/<cloudName>/...)
// - uploadPreset must be your UNSIGNED preset name
//
// Based on your curl test, your cloudName seems: drlyrj07t
// and preset name: hwikigmn

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PostersPage extends StatefulWidget {
  const PostersPage({super.key});

  @override
  State<PostersPage> createState() => _PostersPageState();
}

class _PostersPageState extends State<PostersPage> {
  // ✅ Cloudinary config (set THESE)
  static const String _cloudName = "drlyrj07t";
  static const String _uploadPreset = "hwikigmn";

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();

    // Run once immediately, then every 30s
    _syncScheduledPosters();
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _syncScheduledPosters();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  // Auto-update: Pending -> Displayed if scheduledAt <= now (app must be running)
  Future<void> _syncScheduledPosters() async {
    try {
      final now = Timestamp.now();

      final q = await _db
          .collection('posters')
          .where('status', isEqualTo: 'Pending')
          .where('scheduledAt', isLessThanOrEqualTo: now)
          .get();

      if (q.docs.isEmpty) return;

      final batch = _db.batch();
      for (final d in q.docs) {
        batch.update(d.reference, {
          'status': 'Displayed',
          'displayedAt': now,
        });
      }
      await batch.commit();
    } catch (_) {
      // keep silent to avoid log spam
    }
  }

  // ---------- UI helpers ----------
  String _fmtDateTime(DateTime dt) {
    // Simple formatter without intl
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(dt.hour);
    final m = two(dt.minute);
    final d = two(dt.day);
    final mo = two(dt.month);
    final y = dt.year.toString();
    return "$d-$mo-$y  $h:$m";
  }

  Color _statusColor(String status) {
    if (status == 'Displayed') return Colors.green;
    return Colors.orange;
  }

  // ---------- Dialog to create poster ----------
  Future<void> _openAddPosterDialog() async {
    final user = _auth.currentUser;
    if (user == null) {
      _snack("Please login first.");
      return;
    }

    final titleCtrl = TextEditingController();
    XFile? picked;
    DateTime scheduled = DateTime.now().add(const Duration(minutes: 1));

    bool uploading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDState) {
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final x = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
              );
              if (x != null) {
                setDState(() => picked = x);
              }
            }

            Future<void> pickSchedule() async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: ctx,
                initialDate: scheduled,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: DateTime(now.year + 3),
              );
              if (date == null) return;

              final time = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay.fromDateTime(scheduled),
              );
              if (time == null) return;

              setDState(() {
                scheduled = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            Future<void> submit() async {
              final title = titleCtrl.text.trim();

              if (title.isEmpty) {
                _snack("Enter poster title.");
                return;
              }
              if (picked == null) {
                _snack("Select an image first.");
                return;
              }

              setDState(() => uploading = true);

              try {
                // 1) Upload to Cloudinary
                final uploadRes = await _uploadToCloudinary(File(picked!.path));
                final secureUrl = uploadRes['secure_url'] as String?;
                final publicId = uploadRes['public_id'] as String?;

                if (secureUrl == null || publicId == null) {
                  throw Exception(
                      "Cloudinary response missing secure_url/public_id");
                }

                // 2) Save to Firestore
                final u = _auth.currentUser!;
                final userName = (u.displayName?.trim().isNotEmpty ?? false)
                    ? u.displayName!.trim()
                    : (u.email ?? u.uid);

                final nowTs = Timestamp.now();
                final scheduledTs = Timestamp.fromDate(scheduled);

                await _db.collection('posters').add({
                  'title': title,
                  'imageUrl': secureUrl,
                  'publicId': publicId,
                  'status': 'Pending',
                  'createdAt': nowTs,
                  'scheduledAt': scheduledTs,
                  'userId': u.uid,
                  'userName': userName,
                });

                if (mounted) Navigator.pop(ctx);
                _snack("Poster uploaded & scheduled.");
              } catch (e) {
                _snack("Upload failed: $e");
              } finally {
                setDState(() => uploading = false);
              }
            }

            return AlertDialog(
              title: const Text("Add Poster"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: "Poster Title / Heading",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: uploading ? null : pickSchedule,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                  "Schedule: ${_fmtDateTime(scheduled)}"),
                            ),
                            const Icon(Icons.edit),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: uploading ? null : pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.image_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                picked == null
                                    ? "Select image"
                                    : "Selected: ${picked!.name}",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.upload_file),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (picked != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(picked!.path),
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: uploading ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: uploading ? null : submit,
                  child: uploading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Upload"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------- Cloudinary upload ----------
  Future<Map<String, dynamic>> _uploadToCloudinary(File file) async {
    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");

    final req = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception("cloudinary upload failed: ${resp.statusCode} ${resp.body}");
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ---------- actions ----------
  Future<void> _setStatus(DocumentReference ref, String status) async {
    await ref.update({
      'status': status,
      if (status == 'Displayed') 'displayedAt': Timestamp.now(),
    });
  }

  Future<void> _deletePoster(DocumentSnapshot doc) async {
    // NOTE: This deletes Firestore doc only.
    // If you also want to delete from Cloudinary, you need signed API call (API secret) on a backend.
    await doc.reference.delete();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Posters"),
        actions: [
          IconButton(
            tooltip: "Sync scheduled posters now",
            onPressed: _syncScheduledPosters,
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPosterDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('posters')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text("No posters yet. Tap + to add one."),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;

              final title = (data['title'] ?? '').toString();
              final imageUrl = (data['imageUrl'] ?? '').toString();
              final status = (data['status'] ?? 'Pending').toString();
              final userName = (data['userName'] ?? '').toString();

              final scheduledAt = (data['scheduledAt'] as Timestamp?)?.toDate();
              final scheduledText =
                  scheduledAt == null ? "No schedule" : _fmtDateTime(scheduledAt);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.isEmpty
                            ? Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              )
                            : Image.network(
                                imageUrl,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 90,
                                  height: 90,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),

                      // text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isEmpty ? "(No Title)" : title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Scheduled: $scheduledText",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _statusColor(status).withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 3 dots menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          try {
                            if (value == 'details') {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Poster Details"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // ✅ ADDED: Title also shown in details
                                      Text(
                                        "Title: ${title.isEmpty ? '(No Title)' : title}",
                                      ),
                                      const SizedBox(height: 6),

                                      Text("User: $userName"),
                                      const SizedBox(height: 6),
                                      Text("Scheduled: $scheduledText"),
                                      const SizedBox(height: 6),
                                      Text("Status: $status"),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Close"),
                                    ),
                                  ],
                                ),
                              );
                            } else if (value == 'pending') {
                              await _setStatus(d.reference, 'Pending');
                            } else if (value == 'displayed') {
                              await _setStatus(d.reference, 'Displayed');
                            } else if (value == 'delete') {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Delete poster?"),
                                  content: const Text(
                                      "This will remove it from Firestore. Continue?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await _deletePoster(d);
                              }
                            }
                          } catch (e) {
                            _snack("Action failed: $e");
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Text("Details (User/Time/Status)"),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'pending',
                            child: Text("Set status: Pending"),
                          ),
                          const PopupMenuItem(
                            value: 'displayed',
                            child: Text("Set status: Displayed"),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text("Delete"),
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
