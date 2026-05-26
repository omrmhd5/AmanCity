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
import '../sos/trusted_app_contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  NavItem _currentNavItem = NavItem.home;
  bool _sosActive = false;
  final _mapKey = GlobalKey<MapScreenState>();

  // Entry animation
  late AnimationController _entryController;

  // SOS activation signal — set to true to auto-activate SosScreen
  final ValueNotifier<bool> _sosActivateSignal = ValueNotifier(false);
  // SOS view signal — set to 'history' to navigate to recordings sub-view
  final ValueNotifier<String?> _sosViewSignal = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    AppTheme.themeNotifier.addListener(_onThemeChange);
    _applySystemUI();
  }

  void _onThemeChange() {
    _applySystemUI();
    if (mounted) setState(() {});
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
    _entryController.dispose();
    _sosActivateSignal.dispose();
    _sosViewSignal.dispose();
    super.dispose();
  }

  void _onIncidentReported() {
    // Switch to map tab and force-refresh incidents + hotspots
    setState(() => _currentNavItem = NavItem.map);
    _mapKey.currentState?.refreshAfterReport();
  }

  void _onNavItemTapped(NavItem item) {
    if (item == _currentNavItem) return;

    // Switch tabs without navigation stack buildup
    setState(() {
      _currentNavItem = item;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
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
              padding: EdgeInsets.only(bottom: _sosActive ? 0 : 85),
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
              ),
            ),
        ],
      ),
    );
  }

  // Maps NavItem to its IndexedStack index (must match children order below)
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

  // IndexedStack keeps every screen alive in memory — no rebuild/reload on tab switch.
  // Screens are built once on first HomeScreen mount, then toggled visible/hidden.
  Widget _buildContent() {
    return IndexedStack(
      index: _navIndex(_currentNavItem),
      children: [
        // 0 — Map
        MapScreen(
          key: _mapKey,
          onReportPressed: () => _onNavItemTapped(NavItem.report),
        ),
        // 1 — Report
        ReportIncidentScreen(onReported: _onIncidentReported),
        // 2 — Home / Welcome
        _buildWelcomePage(),
        // 3 — AI
        AiScreen(),
        // 4 — SOS
        SosScreen(
          onBack: () => _onNavItemTapped(NavItem.home),
          onActiveStateChanged: (isActive) {
            setState(() => _sosActive = isActive);
          },
          activateSignal: _sosActivateSignal,
          viewSignal: _sosViewSignal,
        ),
        // 5 — Profile
        const ProfileScreen(),
        // 6 — News
        NewsScreen(onBack: () => _onNavItemTapped(NavItem.home)),
      ],
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
                      'LIVE HUB',
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
            _animated(
              HomeReportCard(onTap: () => _onNavItemTapped(NavItem.news)),
              start: 0.2,
              end: 0.8,
            ),
            const SizedBox(height: 12),
            _animated(
              HomeSosCard(
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
                      'COMMUNITY TOOLS',
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
