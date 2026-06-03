import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

enum NavItem { map, report, home, ai, sos, profile, news }

class BottomNavBar extends StatelessWidget {
  final NavItem currentItem;
  final Function(NavItem) onItemTapped;
  final Map<NavItem, GlobalKey>? navKeys;

  const BottomNavBar({
    Key? key,
    required this.currentItem,
    required this.onItemTapped,
    this.navKeys,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Register dependency so this widget rebuilds on locale change
    context.locale;
    final isDark = AppTheme.currentMode == AppThemeMode.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Stack(
              children: [
                // ── Base glass fill ──────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.primary.withOpacity(0.52),
                              AppColors.primary.withOpacity(0.40),
                            ]
                          : [
                              Colors.white.withOpacity(0.68),
                              Colors.white.withOpacity(0.50),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
                        blurRadius: 36,
                        spreadRadius: 0,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.08),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: _buildNavItem(
                          icon: Icons.map_outlined,
                          activeIcon: Icons.map,
                          label: 'map.title'.tr(),
                          item: NavItem.map,
                          isDark: isDark,
                        ),
                      ),
                      Flexible(
                        child: _buildNavItem(
                          icon: Icons.flag_outlined,
                          activeIcon: Icons.flag,
                          label: 'report.title'.tr(),
                          item: NavItem.report,
                          isDark: isDark,
                        ),
                      ),
                      _buildHomeButton(isDark: isDark),
                      Flexible(
                        child: _buildNavItem(
                          icon: Icons.psychology_outlined,
                          activeIcon: Icons.psychology,
                          label: 'ai.title'.tr(),
                          item: NavItem.ai,
                          isDark: isDark,
                        ),
                      ),
                      Flexible(
                        child: _buildNavItem(
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          label: 'profile.title'.tr(),
                          item: NavItem.profile,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Inner sheen: top-left corner glow ────────────────────
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(isDark ? 0.07 : 0.22),
                            Colors.transparent,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.40, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Specular highlight: top edge bright line ─────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(isDark ? 0.35 : 0.80),
                            Colors.white.withOpacity(isDark ? 0.18 : 0.55),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.25, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Border overlay ────────────────────────────────────────
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.white.withOpacity(0.65),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required NavItem item,
    required bool isDark,
  }) {
    final isSelected = currentItem == item;
    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.60)
        : AppColors.slateGray;

    return GestureDetector(
      key: navKeys?[item],
      onTap: () => onItemTapped(item),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.secondary : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.secondary : inactiveColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: isSelected ? 0.3 : 0.0,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeButton({required bool isDark}) {
    final isSelected = currentItem == NavItem.home;

    return GestureDetector(
      onTap: () => onItemTapped(NavItem.home),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [AppColors.secondary, AppColors.secondary.withOpacity(0.70)]
                : [
                    AppColors.secondary.withOpacity(isDark ? 0.16 : 0.12),
                    AppColors.secondary.withOpacity(isDark ? 0.08 : 0.06),
                  ],
          ),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.25)
                : AppColors.secondary.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.20),
                    blurRadius: 36,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(14),
        child: AnimatedScale(
          scale: isSelected ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: Icon(
            Icons.home_rounded,
            color: isSelected ? Colors.white : AppColors.secondary,
            size: 30,
          ),
        ),
      ),
    );
  }
}
