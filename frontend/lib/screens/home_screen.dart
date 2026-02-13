import 'package:flutter/material.dart';
import '../widgets/bottom_navbar.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NavItem _currentNavItem = NavItem.home;

  void _onNavItemTapped(NavItem item) {
    setState(() {
      _currentNavItem = item;
    });
    // TODO: Navigate to different screens based on selected item
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
      bottomNavigationBar: BottomNavBar(
        currentItem: _currentNavItem,
        onItemTapped: _onNavItemTapped,
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentNavItem) {
      case NavItem.map:
        return const MapScreen();
      case NavItem.report:
        return _buildPlaceholder('Report Incident');
      case NavItem.home:
        return _buildWelcomePage();
      case NavItem.alerts:
        return _buildPlaceholder('Safety Alerts');
      case NavItem.profile:
        return _buildPlaceholder('User Profile');
    }
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 16),
          _buildFeatureCard(
            icon: Icons.sos,
            title: 'SOS Emergency',
            description: 'One-tap emergency alert to trusted contacts',
          ),
        ],
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

  Widget _buildPlaceholder(String screenName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.construction,
              color: AppColors.secondary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            screenName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
        ],
      ),
    );
  }
}
