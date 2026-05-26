import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class ProfileCard extends StatefulWidget {
  final User? user;

  const ProfileCard({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;
  String? _homeCity;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _loadHomeCity();
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadHomeCity() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('home_location_city');
    if (mounted) setState(() => _homeCity = city);
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 14,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'ACCOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Glass card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.getCardBackgroundColor(),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.getBorderColor(),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Avatar with blinking status dot
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondary.withOpacity(0.12),
                              border: Border.all(
                                color: AppColors.secondary,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: AppColors.secondary,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: FadeTransition(
                              opacity: _blinkAnim,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        widget.user?.displayName ?? 'User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Email
                      if (widget.user?.email != null)
                        Text(
                          widget.user!.email!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Location row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _homeCity ?? 'Location not set',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.getSecondaryTextColor(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Inner gradient divider
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.10),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Verified Guardian badge — fixed: secondary teal (was invisible primary navy)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.secondary.withOpacity(0.30),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Verified Guardian',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
