import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

enum AuthorityNavItem { dashboard, incidents, sos, profile }

class AuthorityBottomNavBar extends StatelessWidget {
  final AuthorityNavItem currentItem;
  final Function(AuthorityNavItem) onItemTapped;

  const AuthorityBottomNavBar({
    Key? key,
    required this.currentItem,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                      _buildNavItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        label: 'authority.dashboard'.tr(),
                        item: AuthorityNavItem.dashboard,
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        icon: Icons.list_alt_outlined,
                        activeIcon: Icons.list_alt,
                        label: 'authority.incidents'.tr(),
                        item: AuthorityNavItem.incidents,
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        icon: Icons.emergency_outlined,
                        activeIcon: Icons.emergency,
                        label: 'sos.title'.tr(),
                        item: AuthorityNavItem.sos,
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'profile.title'.tr(),
                        item: AuthorityNavItem.profile,
                        isDark: isDark,
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
    required AuthorityNavItem item,
    required bool isDark,
  }) {
    final isSelected = currentItem == item;
    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.60)
        : AppColors.slateGray;

    return GestureDetector(
      onTap: () => onItemTapped(item),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
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
}
