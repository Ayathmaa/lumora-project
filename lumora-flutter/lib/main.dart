import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:lumora_flutter/services/auth_service.dart';
import 'package:lumora_flutter/services/mood_service.dart';
import 'package:lumora_flutter/services/notification_service.dart';
import 'package:lumora_flutter/screens/anonymous_username_screen.dart';
import 'package:lumora_flutter/screens/google_profile_completion_screen.dart';
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  String? _lastGateKey;

  void _popTransientRoutes() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  bool _usesGoogle(User user) {
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  void _enterGate(String key, {required bool popTransientRoutes}) {
    if (_lastGateKey == key) return;
    _lastGateKey = key;
    if (popTransientRoutes) {
      _popTransientRoutes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        final user = snapshot.data;

        if (user == null) {
          _enterGate('signedOut', popTransientRoutes: true);
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
          builder: (context, profileSnapshot) {
            if (!profileSnapshot.hasData) {
              return const _AuthLoadingScreen();
            }

            final hasProfile = profileSnapshot.data?.exists == true;
            if (hasProfile) {
              _enterGate('signedIn:${user.uid}', popTransientRoutes: true);
              return const MainShell();
            }

            if (user.isAnonymous) {
              _enterGate(
                'setupAnonymous:${user.uid}',
                popTransientRoutes: false,
              );
              return const AnonymousUsernameScreen();
            }

            if (_usesGoogle(user)) {
              _enterGate('setupGoogle:${user.uid}', popTransientRoutes: false);
              return GoogleProfileCompletionScreen(googleUser: user);
            }

            _enterGate('waitingProfile:${user.uid}', popTransientRoutes: false);
            return const _AuthLoadingScreen();
          },
        );
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFC8DCF0),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF7AB5D8))),
    );
  }
}
