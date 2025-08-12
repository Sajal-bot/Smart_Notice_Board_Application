// lib/auth/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ❗️Pick ONE of these two, depending on what you actually use:
import '../pages/home_page.dart'; // using pages/home_page.dart
import '../pages/login_page.dart'; // unauthenticated screen
// If you prefer the combined screen instead of login_page.dart, use this:
// import 'login_register_page.dart';      // and swap it below

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is persisted & signed in -> go Home
        if (snap.data != null) {
          return const HomePage();
        }

        // Not signed in -> show your login (or combined login/register) page
        return const LoginPage();
        // If you prefer combined:
        // return const LoginRegisterPage();
      },
    );
  }
}
