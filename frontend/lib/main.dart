import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/auth/login_screen.dart';
import 'screens/core/home_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/permissions_screen.dart';
import 'data/app_colors.dart';
import 'utils/navigation_service.dart' as navigation;
import 'routes/app_routes.dart';
import 'services/notifications/notification_service.dart';
import 'services/core/user_location_sync_service.dart';
import 'services/core/connectivity_service.dart';
import 'widgets/connectivity_wrapper.dart';

/// Permissions that must be granted before using the app.
const _requiredPermissions = [
  Permission.locationWhenInUse,
  Permission.camera,
  Permission.microphone,
  Permission.phone,
  Permission.photos,
  Permission.notification,
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  UserLocationSyncService.instance.start();
  ConnectivityService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AmanCity',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      navigatorKey: navigation.Navigator.navigatorKey,
      home: const _StartGate(),
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) =>
          ConnectivityWrapper(child: child ?? const SizedBox.shrink()),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Shows onboarding on first launch, then the auth gate on subsequent launches.
class _StartGate extends StatefulWidget {
  const _StartGate();

  @override
  State<_StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<_StartGate> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

    // Always verify required permissions, regardless of onboarding state.
    bool allGranted = true;
    if (onboardingDone) {
      for (final perm in _requiredPermissions) {
        final status = await perm.status;
        if (!status.isGranted && !status.isLimited) {
          allGranted = false;
          break;
        }
      }
    }

    if (mounted) {
      setState(() => _onboardingDone = onboardingDone && allGranted);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }
    // Not done with onboarding → show onboarding
    if (!_onboardingDone!) {
      // Check if onboarding was completed but permissions were revoked
      return FutureBuilder<bool>(
        future: SharedPreferences.getInstance().then(
          (p) => p.getBool('onboarding_complete') ?? false,
        ),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            // Onboarding was done but permissions revoked → go to permissions directly
            return const PermissionsScreen();
          }
          return const OnboardingScreen();
        },
      );
    }
    return const AuthGate();
  }
}

/// Listens to Firebase auth state — shows Login or Home accordingly.
class AuthGate extends StatelessWidget {
  const AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          // Block unverified email users — sign them out silently
          if (!user.emailVerified &&
              user.providerData.any((p) => p.providerId == 'password')) {
            FirebaseAuth.instance.signOut();
            return const LoginScreen();
          }
          // Push the FCM token to the backend each time the user is authenticated
          NotificationService.instance.updateFcmToken();
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
