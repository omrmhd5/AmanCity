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

/// Set while [_BootstrapApp] is on screen — routes fatal errors into bootstrap UI.
_BootstrapAppState? _bootstrapState;

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
        _reportFatal(
          'FLUTTER ERROR:\n${details.exceptionAsString()}',
          details.stack,
        );
      };

      ui.PlatformDispatcher.instance.onError =
          (Object error, StackTrace stack) {
            debugPrint('PlatformDispatcher error: $error\n$stack');
            _reportFatal('ASYNC/PLATFORM ERROR:\n$error', stack);
            return true;
          };

      // Paint immediately — never block runApp on Firebase/localization/etc.
      runApp(const _BootstrapApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('runZonedGuarded error: $error\n$stack');
      _reportFatal('ZONE ERROR:\n$error', stack);
    },
  );
}

void _reportFatal(String message, StackTrace? stack) {
  final text = '$message\n\n${stack ?? ''}';
  if (_bootstrapState != null) {
    _bootstrapState!._setFatal(text);
  } else {
    runApp(_ErrorApp(message: message, stack: stack));
  }
}

/// Boots the real app after painting a visible phase screen (avoids white void).
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  String _phase = 'PHASE 0: FLUTTER ENGINE ALIVE';
  Widget? _app;
  String? _fatal;

  @override
  void initState() {
    super.initState();
    _bootstrapState = this;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runBootSequence());
  }

  @override
  void dispose() {
    if (_bootstrapState == this) {
      _bootstrapState = null;
    }
    super.dispose();
  }

  void _setPhase(String phase) {
    if (!mounted) return;
    setState(() => _phase = phase);
  }

  void _setFatal(String message) {
    if (!mounted) return;
    setState(() {
      _fatal = message;
      _app = null;
    });
  }

  Future<void> _runBootSequence() async {
    try {
      _setPhase('PHASE 1: LOADING .ENV...');
      try {
        await dotenv.load();
      } catch (e) {
        debugPrint('Warning: .env not loaded — $e');
      }

      _setPhase('PHASE 2: FIREBASE INIT...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _setPhase('PHASE 3: THEME...');
      await AppTheme.initTheme();

      _setPhase('PHASE 4: LOCALIZATION...');
      await EasyLocalization.ensureInitialized();

      if (!mounted) return;
      setState(() {
        _phase = 'PHASE 5: LAUNCHING APP...';
        _app = EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: const MyApp(),
        );
      });

      // Non-blocking: defer services until after first real frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDeferredServices();
      });
    } catch (e, stack) {
      debugPrint('Fatal startup error: $e\n$stack');
      _setFatal('FATAL STARTUP ERROR:\n$e\n\n$stack');
    }
  }

  Future<void> _startDeferredServices() async {
    _setPhase('PHASE 6: NOTIFICATIONS...');
    try {
      await NotificationService.instance.init();
    } catch (e) {
      debugPrint('Warning: Notifications init failed — $e');
    }

    _setPhase('PHASE 7: LOCATION SYNC...');
    UserLocationSyncService.instance.start();

    _setPhase('PHASE 8: CONNECTIVITY...');
    ConnectivityService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    if (_fatal != null) {
      return _ErrorApp(message: _fatal!, stack: null);
    }
    if (_app != null) {
      return _app!;
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _DiagnosticLoadingScreen(phaseLabel: _phase),
    );
  }
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
        phaseLabel: 'CHECKING ONBOARDING & PERMISSIONS...',
      );
    }
    if (!_onboardingDone!) {
      return FutureBuilder<bool>(
        future: SharedPreferences.getInstance().then(
          (p) => p.getBool('onboarding_complete') ?? false,
        ),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
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
              if (!user.emailVerified &&
                  user.providerData.any((p) => p.providerId == 'password')) {
                return const LoginScreen();
              }

              if (needsSocialProfileCompletion) {
                return const LoginScreen();
              }

              NotificationService.instance.updateFcmToken();

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
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
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
