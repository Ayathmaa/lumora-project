import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:lumora_flutter/services/auth_service.dart';
import 'package:lumora_flutter/services/mood_service.dart';
import 'package:lumora_flutter/services/notification_service.dart';
import 'package:lumora_flutter/screens/login_screen.dart';
import 'package:lumora_flutter/screens/main_shell.dart';

/// A [PageTransitionsBuilder] that applies no transition animation.
class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final notificationService = NotificationService();

  // Wire up the mood-save callback used by notification actions.
  // This runs both when the app is in the foreground and when it launches
  // from a background action tap.
  onNotificationMoodScore = (score) async {
    try {
      await MoodService().saveTodayMood(score: score);
    } catch (_) {}
  };

  await notificationService.init(
    onActionReceived: (NotificationResponse response) {
      handleMoodAction(response.actionId);
    },
  );
  await notificationService.requestPermissions();
  await notificationService.scheduleDailyMoodReminder();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7AB5D8)),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoTransitionBuilder(),
            TargetPlatform.iOS: _NoTransitionBuilder(),
            TargetPlatform.fuchsia: _NoTransitionBuilder(),
            TargetPlatform.linux: _NoTransitionBuilder(),
            TargetPlatform.macOS: _NoTransitionBuilder(),
            TargetPlatform.windows: _NoTransitionBuilder(),
          },
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFC8DCF0),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7AB5D8)),
            ),
          );
        }

        // If user is logged in, show main shell (with nav bar)
        if (snapshot.hasData) {
          return const MainShell();
        }

        // Otherwise, show login screen
        return const LoginScreen();
      },
    );
  }
}
