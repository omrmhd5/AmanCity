import 'package:flutter/material.dart';
import '../widgets/shared/bottom_navbar.dart';
import 'profile_screen.dart';
import 'news_screen.dart';
import '../data/app_colors.dart';
import '../utils/app_theme.dart';
import 'map_screen.dart';
import 'report_incident_screen.dart';
import 'ai_screen.dart';
import 'sos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NavItem _currentNavItem = NavItem.home;
  bool _sosActive = false;

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
          // Main content
          SafeArea(child: _buildContent()),
        ],
      ),
      bottomNavigationBar: !_sosActive
          ? BottomNavBar(
              currentItem: _currentNavItem,
              onItemTapped: _onNavItemTapped,
            )
          : null,
    );
  }

  Widget _buildContent() {
    switch (_currentNavItem) {
      case NavItem.map:
        return MapScreen(
          onReportPressed: () => _onNavItemTapped(NavItem.report),
        );
      case NavItem.report:
        return const ReportIncidentScreen();
      case NavItem.home:
        return _buildWelcomePage();
      case NavItem.ai:
        return AiScreen();
      case NavItem.sos:
        return SosScreen(
          onBack: () => _onNavItemTapped(NavItem.home),
          onActiveStateChanged: (isActive) {
            setState(() => _sosActive = isActive);
          },
        );
      case NavItem.profile:
        return const ProfileScreen();
      case NavItem.news:
        return NewsScreen(onBack: () => _onNavItemTapped(NavItem.home));
    }
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Welcome Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),
            // Welcome Text
            Text(
              'Welcome to AmanCity',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.getPrimaryTextColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Subtitle
            Text(
              'Your Safety, Our Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.getSecondaryTextColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Description
            Text(
              'Stay safe with real-time community alerts, incident reporting, and emergency SOS features. Together, we build a safer neighborhood.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.getSecondaryTextColor(),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // Feature Cards
            _buildFeatureCard(
              icon: Icons.location_on,
              title: 'Real-time Alerts',
              description:
                  'Get instant notifications of safety incidents near you',
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.report,
              title: 'Easy Reporting',
              description: 'Report incidents quickly with photos and location',
            ),
            const SizedBox(height: 32),
            // Latest News Card
            GestureDetector(
              onTap: () => _onNavItemTapped(NavItem.news),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.1),
                      Colors.blue.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.newspaper,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Latest Twitter News',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getPrimaryTextColor(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View real-time incidents detected by Grok AI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.getSecondaryTextColor(),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Emergency SOS Card
            GestureDetector(
              onTap: () => _onNavItemTapped(NavItem.sos),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.danger.withOpacity(0.1),
                      const Color(0xFFEF4444).withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.sos, color: AppColors.danger, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency SOS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getPrimaryTextColor(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hold to activate emergency alert & audio recording',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.getSecondaryTextColor(),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.danger,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
