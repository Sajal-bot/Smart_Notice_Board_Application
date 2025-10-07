import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// Auth & routing
import 'auth/auth_gate.dart';

// Splash (animated)
import 'pages/splash_notice_card.dart';

// App pages
import 'package:notify_app/pages/current_notice_page.dart';
import 'package:notify_app/pages/deleted_notices_page.dart';
import 'package:notify_app/pages/notices_list_page.dart';
import 'package:notify_app/pages/submit_notice_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/notices_fr_page.dart';

// Background updater
import 'notice_status_updater.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Start periodic status updater (runs while app is open)
  NoticeStatusUpdater.instance.start(); // checks immediately, then every 1 minute

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notify',
      debugShowCheckedModeBanner: false,

      // Start from our animated splash
      initialRoute: '/',

      routes: {
        // 1) Animated splash (after native lavender screen)
        '/': (_) => const SplashNoticeCard(nextRoute: '/auth'),

        // 2) Auth gate decides: go to HomePage or Login/Register
        '/auth': (_) => const AuthGate(),

        // Auth pages
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),

        // Main app pages
        '/home': (_) => const HomePage(),
        '/submit': (_) => const SubmitNoticePage(),
        '/notices': (_) => const NoticesListPage(),
        '/current': (_) => const CurrentNoticePage(),
        '/deleted': (_) => const DeletedNoticesPage(),
        '/notices-fr': (context) => const NoticesFRPage(),
      },
    );
  }
}
