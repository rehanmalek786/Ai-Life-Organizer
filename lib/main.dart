import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/app_providers.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_navigation.dart';
import 'widgets/shared_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'AI Life Organizer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode,
            home: const SplashScreen(next: _AuthGate()),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _onboardingComplete;
  String? _checkedForUid;

  Future<void> _checkOnboarding(String uid) async {
    _checkedForUid = uid;

    // Check the on-device cache first - once onboarding is done, every
    // future app launch skips the network round-trip entirely, which is
    // what was making the app feel slow to open.
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getBool('onboarding_done_$uid');
      if (cached == true) {
        if (mounted && _checkedForUid == uid) setState(() => _onboardingComplete = true);
        return;
      }
    } catch (_) {}

    bool complete = false;
    try {
      complete = await FirestoreService().isOnboardingComplete().timeout(const Duration(seconds: 6));
    } catch (_) {
      complete = false;
    }

    if (complete) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_done_$uid', true);
      } catch (_) {}
    }

    if (mounted && _checkedForUid == uid) {
      setState(() => _onboardingComplete = complete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.ready) {
      return const Scaffold(body: LoadingView());
    }

    if (!auth.isSignedIn) {
      _checkedForUid = null;
      _onboardingComplete = null;
      return const AuthScreen();
    }

    final uid = auth.user!.uid;
    if (_checkedForUid != uid) {
      _checkOnboarding(uid);
      return const Scaffold(body: LoadingView());
    }

    if (_onboardingComplete == false) {
      return OnboardingScreen(onDone: () => setState(() => _onboardingComplete = true));
    }

    if (_onboardingComplete == null) {
      return const Scaffold(body: LoadingView());
    }

    return const MainNavigation();
  }
}
