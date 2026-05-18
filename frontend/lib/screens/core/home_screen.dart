import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/shared/bottom_navbar.dart';
import '../profile/profile_screen.dart';
import '../incidents/news_screen.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../map/map_screen.dart';
import '../incidents/report_incident_screen.dart';
import '../ai_chat/ai_screen.dart';
import '../sos/sos_screen.dart';
import '../alerts/alerts_screen.dart';
import '../../services/notifications/notification_service.dart';

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
  // SOS pulse animation
  late AnimationController _sosController;
  late Animation<double> _sosPulse;

  // Card press states
  bool _mapPressed = false;
  bool _reportPressed = false;
  bool _newsPressed = false;
  bool _sosPressed = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _sosPulse = Tween<double>(
      begin: 1.0,
      end: 1.35,
    ).animate(CurvedAnimation(parent: _sosController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _sosController.dispose();
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
        ),
        // 5 — Profile
        const ProfileScreen(),
        // 6 — News
        NewsScreen(onBack: () => _onNavItemTapped(NavItem.home)),
      ],
    );
  }

  // ─── Greeting helper ─────────────────────────────────────────────────────
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
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

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        // Circular logo
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/logos/AmanCity_Logo_Only.png',
            width: 42,
            height: 42,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        // Greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.getPrimaryTextColor(),
                ),
              ),
            ],
          ),
        ),
        // Bell icon
        ValueListenableBuilder<int>(
          valueListenable: NotificationService.instance.unreadCount,
          builder: (context, count, _) {
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppTheme.getBackgroundColor().withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.getBorderColor().withOpacity(0.15),
                        width: 0.75,
                      ),
                    ),
                    child: Icon(
                      count > 0
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_outlined,
                      color: count > 0
                          ? AppColors.secondary
                          : AppTheme.getSecondaryTextColor(),
                      size: 24,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Hero Banner ─────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Column(
      children: [
        // Logo with teal glow
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.28),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/logos/AmanCity_Logo_Only.png',
              width: 76,
              height: 76,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Gradient title
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.secondary, AppTheme.getPrimaryTextColor()],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'AmanCity',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        // Pill badge subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.secondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Your Safety, Our Priority',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Quick Action 2-column grid ───────────────────────────────────────────
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.map_rounded,
            title: 'Explore Map',
            subtitle: 'View live incidents near you',
            isPressed: _mapPressed,
            onTapDown: () => setState(() => _mapPressed = true),
            onTapUp: () {
              setState(() => _mapPressed = false);
              _onNavItemTapped(NavItem.map);
            },
            onTapCancel: () => setState(() => _mapPressed = false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.report_rounded,
            title: 'Report',
            subtitle: 'Submit an incident report',
            isPressed: _reportPressed,
            onTapDown: () => setState(() => _reportPressed = true),
            onTapUp: () {
              setState(() => _reportPressed = false);
              _onNavItemTapped(NavItem.report);
            },
            onTapCancel: () => setState(() => _reportPressed = false),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTapCancel,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: isPressed ? 0.96 : 1.0,
        duration: isPressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 300),
        curve: isPressed ? Curves.easeIn : Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundColor().withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.getBorderColor().withOpacity(0.15),
              width: 0.75,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.15),
                    width: 0.75,
                  ),
                ),
                child: Icon(icon, color: AppColors.secondary, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getPrimaryTextColor(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                  height: 1.4,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── News Card ────────────────────────────────────────────────────────────
  Widget _buildNewsCard() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _newsPressed = true),
      onTapUp: (_) {
        setState(() => _newsPressed = false);
        _onNavItemTapped(NavItem.news);
      },
      onTapCancel: () => setState(() => _newsPressed = false),
      child: AnimatedScale(
        scale: _newsPressed ? 0.97 : 1.0,
        duration: _newsPressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 300),
        curve: _newsPressed ? Curves.easeIn : Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.secondary.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.2),
                    width: 0.75,
                  ),
                ),
                child: Icon(
                  Icons.dynamic_feed_rounded,
                  color: AppColors.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVE FEED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'X / Twitter Intelligence',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Real-time incidents detected by Grok AI',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SOS Card ─────────────────────────────────────────────────────────────
  Widget _buildSosCard() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _sosPressed = true),
      onTapUp: (_) {
        setState(() => _sosPressed = false);
        _onNavItemTapped(NavItem.sos);
      },
      onTapCancel: () => setState(() => _sosPressed = false),
      child: AnimatedScale(
        scale: _sosPressed ? 0.97 : 1.0,
        duration: _sosPressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 300),
        curve: _sosPressed ? Curves.easeIn : Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.danger.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Pulsing SOS icon
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _sosPulse,
                      builder: (_, __) => Transform.scale(
                        scale: _sosPulse.value,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.sos_rounded,
                        color: AppColors.danger,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMERGENCY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Emergency SOS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Hold to activate emergency alert & recording',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.danger,
                size: 22,
              ),
            ],
          ),
        ),
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
            _animated(_buildHeader(), start: 0.0, end: 0.5),
            const SizedBox(height: 36),
            // Hero
            _animated(_buildHero(), start: 0.1, end: 0.65),
            const SizedBox(height: 36),
            // Quick action section label
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
                      'QUICK ACTIONS',
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
            // Quick actions grid
            _animated(_buildQuickActions(), start: 0.2, end: 0.8),
            const SizedBox(height: 28),
            // Explore section label
            _animated(
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(
                      Icons.explore_rounded,
                      size: 15,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'EXPLORE',
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
              start: 0.3,
              end: 0.85,
            ),
            const SizedBox(height: 10),
            // News card
            _animated(_buildNewsCard(), start: 0.3, end: 0.9),
            const SizedBox(height: 12),
            // SOS card
            _animated(_buildSosCard(), start: 0.35, end: 1.0),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
