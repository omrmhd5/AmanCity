import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/shared/bottom_navbar.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/home_hero.dart';
import '../../widgets/home/home_report_card.dart';
import '../../widgets/home/home_sos_card.dart';
import '../../widgets/home/home_community_tools.dart';
import '../profile/profile_screen.dart';
import '../incidents/news_screen.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../map/map_screen.dart';
import '../incidents/report_incident_screen.dart';
import '../ai_chat/ai_screen.dart';
import '../sos/sos_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sos/trusted_app_contacts_screen.dart';
import '../../widgets/home/home_incoming_sos_tile.dart';
import 'home_tour_guide.dart';
import '../../services/notifications/notification_service.dart';
import '../sos/incoming_sos_alert_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  NavItem _currentNavItem = NavItem.home;
  bool _sosActive = false;
  final _mapKey = GlobalKey<MapScreenState>();

  // Track which tab indices have been visited — unvisited screens are not built yet
  final Set<int> _visited = {2}; // 2 = home tab, pre-visited

  // Entry animation
  late AnimationController _entryController;
  // Horizontal page slide controller — value == navIndex of visible screen
  late AnimationController _pageSlideController;

  // SOS activation signal — set to true to auto-activate SosScreen
  final ValueNotifier<bool> _sosActivateSignal = ValueNotifier(false);
  // SOS view signal — set to 'history' to navigate to recordings sub-view
  final ValueNotifier<String?> _sosViewSignal = ValueNotifier(null);
  // Incremented each time the SOS tab becomes active — triggers stagger replay
  final ValueNotifier<int> _sosActivationSignal = ValueNotifier(0);
  // Incremented each time the Report tab becomes active
  final ValueNotifier<int> _reportActivationSignal = ValueNotifier(0);
  // Incremented each time the AI tab becomes active
  final ValueNotifier<int> _aiActivationSignal = ValueNotifier(0);
  // Incremented each time the Profile tab becomes active
  final ValueNotifier<int> _profileActivationSignal = ValueNotifier(0);
  // Incremented each time the News tab becomes active
  final ValueNotifier<int> _newsActivationSignal = ValueNotifier(0);

  final GlobalKey _navMapKey = GlobalKey();
  final GlobalKey _navReportKey = GlobalKey();
  final GlobalKey _navAiKey = GlobalKey();
  final GlobalKey _navProfileKey = GlobalKey();
  final GlobalKey _newsCardKey = GlobalKey();
  final GlobalKey _sosCardKey = GlobalKey();

  // Guards against double-pushing IncomingSosAlertScreen when the
  // activeIncomingSession listener fires multiple times for the same session.
  bool _sosPushPending = false;
  String? _lastSosPushedSessionId;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _pageSlideController = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 6.0,
      value: 2.0, // home tab is index 2
      duration: const Duration(milliseconds: 400),
    );
    AppTheme.themeNotifier.addListener(_onThemeChange);
    _applySystemUI();

    // Listen for incoming SOS sessions — push IncomingSosAlertScreen reactively.
    // This is more reliable than using navigatorKey.currentState on iOS, where
    // the global key can be null when FCM fires (foreground or background resume).
    NotificationService.instance.activeIncomingSession
        .addListener(_onIncomingSosSession);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTourGuide();
      // Handle any session that was already set before this screen mounted
      // (e.g. app opened from terminated state via notification tap).
      _onIncomingSosSession();
    });
  }

  void _onThemeChange() {
    _applySystemUI();
    if (mounted) setState(() {});
  }

  Future<void> _checkTourGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTour = prefs.getBool('has_seen_tour') ?? false;
    if (!hasSeenTour && mounted) {
      // Small delay to ensure the UI has finished drawing its animations
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          HomeTourGuide.show(
            context: context,
            navMapKey: _navMapKey,
            navReportKey: _navReportKey,
            navAiKey: _navAiKey,
            navProfileKey: _navProfileKey,
            newsCardKey: _newsCardKey,
            sosCardKey: _sosCardKey,
          );
        }
      });
    }
  }

  void _applySystemUI() {
    final isDark = AppTheme.currentMode == AppThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.primary,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: AppColors.lightBackground,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    NotificationService.instance.activeIncomingSession
        .removeListener(_onIncomingSosSession);
    _entryController.dispose();
    _pageSlideController.dispose();
    _sosActivateSignal.dispose();
    _sosViewSignal.dispose();
    super.dispose();
  }

  /// Called whenever [NotificationService.instance.activeIncomingSession] changes.
  /// Pushes [IncomingSosAlertScreen] using the local BuildContext, which is
  /// always valid here — avoiding the iOS issue where the global navigatorKey
  /// is null when FCM delivers a message.
  void _onIncomingSosSession() {
    final session = NotificationService.instance.activeIncomingSession.value;
    if (session == null || !mounted) return;
    // Don't push again if we already pushed this exact session
    if (session.sessionId == _lastSosPushedSessionId) return;
    // Don't push again if a push is already queued for this frame
    if (_sosPushPending) return;
    _sosPushPending = true;

    // Post-frame so the navigator is guaranteed ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sosPushPending = false;
      if (!mounted) return;
      // Re-read in case the session was cleared during this frame.
      final s = NotificationService.instance.activeIncomingSession.value;
      if (s == null) return;
      if (s.sessionId == _lastSosPushedSessionId) return;
      _lastSosPushedSessionId = s.sessionId;
      NotificationService.instance.reopenIncomingAlert();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IncomingSosAlertScreen(
            sessionId: s.sessionId,
            triggerUserName: s.senderName,
            triggerUserPhone: s.senderPhone,
            lat: s.lat,
            lng: s.lng,
          ),
          fullscreenDialog: true,
        ),
      );
    });
  }

  void _onIncidentReported() {
    // Switch to map tab and force-refresh incidents + hotspots
    _onIncidentReportedSlide();
  }

  void _onNavItemTapped(NavItem item) {
    if (item == _currentNavItem) return;

    final newIndex = _navIndex(item);

    // Mark as visited so the screen gets built
    if (!_visited.contains(newIndex)) {
      setState(() => _visited.add(newIndex));
    }

    // Slide to new tab
    _pageSlideController.animateTo(
      _navIndex(item).toDouble(),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );

    setState(() {
      _currentNavItem = item;
    });

    // Signal SOS screen to replay stagger when its tab becomes active
    if (item == NavItem.sos) {
      _sosActivationSignal.value++;
    }
    if (item == NavItem.report) {
      _reportActivationSignal.value++;
    }
    if (item == NavItem.ai) {
      _aiActivationSignal.value++;
    }
    if (item == NavItem.profile) {
      _profileActivationSignal.value++;
    }
    if (item == NavItem.news) {
      _newsActivationSignal.value++;
    }
    if (item == NavItem.home) {
      _entryController.forward(from: 0);
    }
  }

  void _onIncidentReportedSlide() {
    setState(() {
      _currentNavItem = NavItem.map;
      _visited.add(_navIndex(NavItem.map));
    });
    _pageSlideController.animateTo(
      _navIndex(NavItem.map).toDouble(),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    _mapKey.currentState?.refreshAfterReport();
  }

  int _navIndex(NavItem item) {
    switch (item) {
      case NavItem.map:
        return 0;
      case NavItem.report:
        return 1;
      case NavItem.home:
        return 2;
      case NavItem.ai:
        return 3;
      case NavItem.sos:
        return 4;
      case NavItem.profile:
        return 5;
      case NavItem.news:
        return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Register dependency so this widget rebuilds on locale change
    context.locale;
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.getBackgroundColor(),
                  AppTheme.getBackgroundColor().withOpacity(0.95),
                ],
              ),
            ),
          ),
          // Main content — padded so nothing hides behind the floating navbar
          // No padding when SOS is active (navbar is hidden)
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: (_sosActive || MediaQuery.of(context).viewInsets.bottom > 0)
                    ? 0
                    : 85,
              ),
              child: _buildContent(),
            ),
          ),
          // Floating navbar — true overlay, zero background behind it
          if (!_sosActive)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNavBar(
                currentItem: _currentNavItem,
                onItemTapped: _onNavItemTapped,
                navKeys: {
                  NavItem.map: _navMapKey,
                  NavItem.report: _navReportKey,
                  NavItem.ai: _navAiKey,
                  NavItem.profile: _navProfileKey,
                },
              ),
            ),
        ],
      ),
    );
  }

  // IndexedStack replaced by animated horizontal slide stack.
  // All screens stay alive in memory; AnimatedBuilder repositions them on every
  // animation frame using Transform.translate.
  Widget _buildContent() {
    final screens = [
      // 0 — Map
      MapScreen(
        key: _mapKey,
        onReportPressed: () => _onNavItemTapped(NavItem.report),
      ),
      // 1 — Report
      ReportIncidentScreen(
        onReported: _onIncidentReported,
        activationSignal: _reportActivationSignal,
      ),
      // 2 — Home / Welcome
      _buildWelcomePage(),
      // 3 — AI
      AiScreen(activationSignal: _aiActivationSignal),
      // 4 — SOS
      SosScreen(
        onBack: () => _onNavItemTapped(NavItem.home),
        onActiveStateChanged: (isActive) {
          setState(() => _sosActive = isActive);
        },
        activateSignal: _sosActivateSignal,
        viewSignal: _sosViewSignal,
        activationSignal: _sosActivationSignal,
      ),
      // 5 — Profile
      ProfileScreen(activationSignal: _profileActivationSignal),
      // 6 — News
      NewsScreen(
        onBack: () => _onNavItemTapped(NavItem.home),
        activationSignal: _newsActivationSignal,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ClipRect(
          child: AnimatedBuilder(
            animation: _pageSlideController,
            builder: (context, _) {
              final offset = _pageSlideController.value;
              final isRtl = context.locale.languageCode == 'ar';
              final multiplier = isRtl ? -1 : 1;
              return Stack(
                children: List.generate(screens.length, (i) {
                  // Only build screens that have been visited at least once
                  final child = _visited.contains(i)
                      ? screens[i]
                      : const SizedBox.shrink();
                  return Transform.translate(
                    offset: Offset((i - offset) * width * multiplier, 0),
                    child: SizedBox(width: width, child: child),
                  );
                }),
              );
            },
          ),
        );
      },
    );
  }

  // ─── Animated section wrapper ─────────────────────────────────────────────
  Widget _animated(Widget child, {double start = 0.0, double end = 1.0}) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  // ─── Welcome Page ─────────────────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            _animated(const HomeHeader(), start: 0.0, end: 0.5),
            const SizedBox(height: 36),
            // Hero
            _animated(const HomeHero(), start: 0.1, end: 0.65),
            const SizedBox(height: 36),

            // ── LIVE HUB ──────────────────────────────────────────────────
            _animated(
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 15,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'home.live_hub'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getSecondaryTextColor(),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              start: 0.2,
              end: 0.75,
            ),
            const SizedBox(height: 10),
            _animated(const HomeIncomingSosTile(), start: 0.2, end: 0.8),
            const SizedBox(height: 12),
            _animated(
              HomeReportCard(
                key: _newsCardKey,
                onTap: () => _onNavItemTapped(NavItem.news),
              ),
              start: 0.2,
              end: 0.8,
            ),
            const SizedBox(height: 12),
            _animated(
              HomeSosCard(
                key: _sosCardKey,
                onActivate: () {
                  _onNavItemTapped(NavItem.sos);
                  Future.delayed(const Duration(milliseconds: 80), () {
                    _sosActivateSignal.value = true;
                  });
                },
                onOpenSos: () => _onNavItemTapped(NavItem.sos),
                onContactsTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TrustedAppContactsScreen(),
                    ),
                  );
                },
                onRecordingsTap: () {
                  _sosViewSignal.value = 'history';
                  _onNavItemTapped(NavItem.sos);
                },
              ),
              start: 0.25,
              end: 0.85,
            ),
            const SizedBox(height: 28),

            // ── COMMUNITY TOOLS ──────────────────────────────────────────
            _animated(
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(
                      Icons.handshake_rounded,
                      size: 15,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'home.community_tools'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getSecondaryTextColor(),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              start: 0.35,
              end: 0.9,
            ),
            const SizedBox(height: 10),
            _animated(
              HomeCommunityTools(
                onMapTap: () => _onNavItemTapped(NavItem.map),
                onNewsTap: () => _onNavItemTapped(NavItem.report),
              ),
              start: 0.35,
              end: 1.0,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
