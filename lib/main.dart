import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:notify_app/pages/current_notice_page.dart';
import 'package:notify_app/pages/deleted_notices_page.dart';
import 'package:notify_app/pages/notices_list_page.dart';
import 'package:notify_app/pages/submit_notice_page.dart';
import 'firebase_options.dart';

import 'auth/auth_gate.dart';

// Keep routes if you use them for navigation between login/register pages
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ❌ Do not force /login on startup
      // initialRoute: '/login',

      // ✅ Let AuthGate decide
      home: const AuthGate(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),

        // NEW
        '/submit': (context) => const SubmitNoticePage(),
        '/notices': (context) => const NoticesListPage(),
        '/current': (context) => const CurrentNoticePage(),
        '/deleted': (context) => const DeletedNoticesPage(),
      },
    );
  }
}
