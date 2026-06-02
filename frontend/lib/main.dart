import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/auth/login_screen.dart';
import 'screens/core/home_screen.dart';
import 'screens/authority/authority_home_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/permissions_screen.dart';
import 'data/app_colors.dart';
import 'utils/app_theme.dart';
import 'utils/navigation_service.dart' as navigation;
import 'routes/app_routes.dart';
import 'services/notifications/notification_service.dart';
import 'services/core/user_location_sync_service.dart';
import 'services/core/connectivity_service.dart';
import 'services/auth/auth_service.dart';
import 'services/authority/authority_api_service.dart';
import 'widgets/connectivity_wrapper.dart';
import 'firebase_options.dart';

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
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Catch UI rendering errors and paint them on the screen instead of a white void.
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Material(
          color: Colors.black,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                'UI CRASH:\n${details.exception}\n\n${details.stack}',
                style: const TextStyle(color: Colors.yellow, fontSize: 12),
                textDirection: ui.TextDirection.ltr,
              ),
            ),
          ),
        );
      };

      // Catch uncaught Flutter framework errors.
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
        _showFatalError(
          'FLUTTER ERROR:\n${details.exceptionAsString()}',
          details.stack,
        );
      };

      // Catch async/platform errors outside the Flutter framework.
      ui.PlatformDispatcher.instance.onError =
          (Object error, StackTrace stack) {
            debugPrint('PlatformDispatcher error: $error\n$stack');
            _showFatalError('ASYNC/PLATFORM ERROR:\n$error', stack);
            return true;
          };

      try {
        // Load .env — gracefully skip if file is missing in the build.
        try {
          await dotenv.load();
        } catch (e) {
          debugPrint('Warning: .env not loaded — $e');
        }

        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        try {
          await NotificationService.instance.init();
        } catch (e) {
          debugPrint('Warning: Notifications init failed — $e');
        }

        UserLocationSyncService.instance.start();
        ConnectivityService.instance.init();

        await AppTheme.initTheme();
        await EasyLocalization.ensureInitialized();

        runApp(
          EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('ar')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            child: const MyApp(),
          ),
        );
      } catch (e, stack) {
        debugPrint('Fatal startup error: $e\n$stack');
        _showFatalError('FATAL STARTUP ERROR:\n$e', stack);
      }
    },
    (Object error, StackTrace stack) {
      debugPrint('runZonedGuarded error: $error\n$stack');
      _showFatalError('ZONE ERROR:\n$error', stack);
    },
  );
}

class _ErrorApp extends StatelessWidget {
  final String message;
  final StackTrace? stack;
  const _ErrorApp({required this.message, this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              'AmanCity Fatal Error\n\n$message\n\n${stack ?? ''}',
              style: const TextStyle(color: Colors.yellow, fontSize: 12),
              textDirection: ui.TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
  }
}

void _showFatalError(String message, StackTrace? stack) {
  runApp(_ErrorApp(message: message, stack: stack));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.currentMode == AppThemeMode.dark;
    return MaterialApp(
      title: 'AmanCity',
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.primary,
        useMaterial3: true,
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
      return const _DiagnosticLoadingScreen(
        phaseLabel: 'CHECKING CONNECTIVITY & PERMISSIONS...',
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
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.socialProfileCompletionRequired,
      builder: (context, needsSocialProfileCompletion, _) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _DiagnosticLoadingScreen(
                phaseLabel: 'WAITING FOR AUTH...',
              );
            }
            if (snapshot.hasData) {
              final user = snapshot.data!;
              // Block unverified email users — sign them out silently
              if (!user.emailVerified &&
                  user.providerData.any((p) => p.providerId == 'password')) {
                return const LoginScreen();
              }

              if (needsSocialProfileCompletion) {
                return const LoginScreen();
              }

              // Push the FCM token to the backend each time the user is authenticated
              NotificationService.instance.updateFcmToken();

              // Check role and route accordingly
              return FutureBuilder<String?>(
                future: AuthorityApiService.instance.fetchCurrentUserRole(),
                builder: (context, roleSnapshot) {
                  if (roleSnapshot.connectionState == ConnectionState.waiting) {
                    return const _DiagnosticLoadingScreen(
                      phaseLabel: 'RESOLVING USER ROLE...',
                    );
                  }
                  if (roleSnapshot.data == 'authority') {
                    return const AuthorityHomeScreen();
                  }
                  return const HomeScreen();
                },
              );
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}

class _DiagnosticLoadingScreen extends StatelessWidget {
  final String phaseLabel;
  const _DiagnosticLoadingScreen({required this.phaseLabel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurpleAccent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.orangeAccent),
                const SizedBox(height: 24),
                Text(
                  phaseLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
