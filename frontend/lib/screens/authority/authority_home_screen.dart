import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../widgets/authority/authority_bottom_navbar.dart';
import '../../widgets/shared/custom_text.dart';
import '../../services/auth/auth_service.dart';
import '../profile/profile_screen.dart';
import 'authority_dashboard_screen.dart';
import 'authority_incidents_screen.dart';
import 'authority_sos_screen.dart';

class AuthorityHomeScreen extends StatefulWidget {
  const AuthorityHomeScreen({Key? key}) : super(key: key);

  @override
  State<AuthorityHomeScreen> createState() => _AuthorityHomeScreenState();
}

class _AuthorityHomeScreenState extends State<AuthorityHomeScreen>
    with SingleTickerProviderStateMixin {
  AuthorityNavItem _current = AuthorityNavItem.dashboard;

  Map<AuthorityNavItem, String> get _titles => {
    AuthorityNavItem.dashboard: 'authority.dashboard'.tr(),
    AuthorityNavItem.incidents: 'authority.incidents'.tr(),
    AuthorityNavItem.sos: 'authority.sos_monitor'.tr(),
    AuthorityNavItem.profile: 'profile.title'.tr(),
  };

  void _onNavTapped(AuthorityNavItem item) {
    if (_current != item) setState(() => _current = item);
  }

  Widget _buildBody() {
    switch (_current) {
      case AuthorityNavItem.dashboard:
        return const AuthorityDashboardScreen();
      case AuthorityNavItem.incidents:
        return const AuthorityIncidentsScreen();
      case AuthorityNavItem.sos:
        return const AuthoritySosScreen();
      case AuthorityNavItem.profile:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            if (_current != AuthorityNavItem.profile)
              _AuthorityHeader(title: _titles[_current]!),
            // ── Content ──────────────────────────────────────────────────
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : AuthorityBottomNavBar(
              currentItem: _current,
              onItemTapped: _onNavTapped,
            ),
    );
  }
}

class _AuthorityHeader extends StatelessWidget {
  final String title;

  const _AuthorityHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          // Authority badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.secondary,
                  size: 14,
                ),
                const SizedBox(width: 5),
                CustomText(
                  text: 'authority.title'.tr(),
                  size: 10,
                  weight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Screen title
          Expanded(
            child: CustomText(text: title, size: 20, weight: FontWeight.w800),
          ),
          // Logout button
          GestureDetector(
            onTap: () async {
              await AuthService.instance.signOut();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.getCardBackgroundColor(),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.getBorderColor()),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: AppTheme.getSecondaryTextColor(),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
