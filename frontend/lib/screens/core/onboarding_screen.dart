import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../services/core/connectivity_service.dart';
import 'permissions_screen.dart';

// ─── Data models ────────────────────────────────────────────────────────────

class _PageData {
  final String imagePath;
  final String title;
  final String description;
  const _PageData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    // Bypass connectivity checks — onboarding doesn't need the backend.
    ConnectivityService.instance.setBypass(true);
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  List<_PageData> get _pages => [
    _PageData(
      imagePath: 'assets/images/Onboarding_1.png',
      title: 'onboarding.page1_title'.tr(),
      description: 'onboarding.page1_desc'.tr(),
    ),
    _PageData(
      imagePath: 'assets/images/Onboarding_2.png',
      title: 'onboarding.page2_title'.tr(),
      description: 'onboarding.page2_desc'.tr(),
    ),
    _PageData(
      imagePath: 'assets/images/Onboarding_3.png',
      title: 'onboarding.page3_title'.tr(),
      description: 'onboarding.page3_desc'.tr(),
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToPermissions();
    }
  }

  void _goToPermissions() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PermissionsScreen()),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    _pageController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: logo + skip ───────────────────────────────
            _animated(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logos/AmanCity_Logo_Only.png',
                        height: 34,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _goToPermissions,
                      child: Text(
                        'onboarding.skip'.tr(),
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              start: 0.0,
              end: 0.5,
            ),

            // ── Pages ────────────────────────────────────────────
            Expanded(
              child: _animated(
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _OnboardingPageWidget(data: _pages[i]),
                ),
                start: 0.1,
                end: 0.65,
              ),
            ),

            // ── Footer: dots + button ─────────────────────────────
            _animated(
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.secondary
                                : AppTheme.getBorderColor(),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),

                    // Next / Get Started
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'onboarding.get_started'.tr()
                                  : 'common.next'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              start: 0.25,
              end: 0.8,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page widget ─────────────────────────────────────────────────────────────

class _OnboardingPageWidget extends StatelessWidget {
  final _PageData data;
  const _OnboardingPageWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        children: [
          // Illustration
          Expanded(flex: 5, child: _IllustrationCard(data: data)),
          const SizedBox(height: 28),

          // Text
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: AppTheme.getPrimaryTextColor(),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  data.description,
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(),
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Illustration card ────────────────────────────────────────────────────────

class _IllustrationCard extends StatelessWidget {
  final _PageData data;
  const _IllustrationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.getCardBackgroundColor(),
        border: Border.all(color: AppTheme.getBorderColor()),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          data.imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
