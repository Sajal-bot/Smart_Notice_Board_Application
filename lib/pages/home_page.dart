// lib/pages/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Update these to your actual asset file names
  final List<String> _images = const [
    'assets/images/image111.png',
    'assets/images/image222.png',
    'assets/images/image333.png',
    'assets/images/image444.png',
    'assets/images/image555.png',
  ];

  int _current = 0;
  Timer? _timer;
  late final Future<String?> _usernameFuture;

  @override
  void initState() {
    super.initState();
    _usernameFuture = _getUsername();

    // change slide every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _current = (_current + 1) % _images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<String?> _getUsername() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) return (doc.data() ?? {})['username'] as String?;
    return null;
  }

  Future<void> _confirmAndLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      // AuthGate will automatically show Login
    }
  }

  @override
  Widget build(BuildContext context) {
    // responsive banner height (~35% of screen)
    final double bannerHeight = MediaQuery.of(context).size.height * 0.35;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _confirmAndLogout,
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        // for "Welcome, <username>"
        future: _usernameFuture,
        builder: (context, snap) {
          final username = snap.data ?? 'User';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // ======= Top carousel (edge-to-edge) =======
              SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // fading image
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Image.asset(
                        _images[_current],
                        key: ValueKey(_images[_current]),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),

                    // welcome overlay inside image (top)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Welcome, $username 👋',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black54,
                                  offset: Offset(1.5, 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // dots indicator
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_images.length, (i) {
                          final active = i == _current;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: active ? 20 : 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ======= Quick Actions Grid (4 icons) =======
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  children: [
                    _ActionTile(
                      icon: Icons.note_add_outlined,
                      label: 'Submit Notice',
                      onTap: () => Navigator.pushNamed(context, '/submit'),
                    ),
                    _ActionTile(
                      icon: Icons.list_alt_outlined,
                      label: 'All Notices',
                      onTap: () => Navigator.pushNamed(context, '/notices'),
                    ),
                    _ActionTile(
                      icon: Icons.play_circle_outline,
                      label: 'Running Now',
                      onTap: () => Navigator.pushNamed(context, '/current'),
                    ),
                    _ActionTile(
                      icon: Icons.delete_outline,
                      label: 'Deleted',
                      onTap: () => Navigator.pushNamed(context, '/deleted'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ======= (Optional) anything else you want under grid =======
              // Example placeholder section (remove if not needed)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Quick tips: Use the tiles above to manage your notices.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

/// Simple card-like tile for the home quick actions
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: scheme.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

