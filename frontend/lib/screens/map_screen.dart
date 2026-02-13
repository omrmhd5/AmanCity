import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_text.dart';
import '../widgets/map/map_view_background.dart';
import '../widgets/map/alert_card.dart';
import '../widgets/map/map_filter_section.dart';
import '../widgets/map/map_sos_button.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  String? selectedFilter;
  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late AnimationController _userMarkerController;

  @override
  void initState() {
    super.initState();
    _pulseController1 = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseController2 = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _userMarkerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController1.dispose();
    _pulseController2.dispose();
    _userMarkerController.dispose();
    super.dispose();
  }

  // Mock data for nearby alerts
  final List<Map<String, dynamic>> nearbyAlerts = [
    {
      'type': 'Verbal Harassment',
      'description': 'Reported near central area. Large group gathering.',
      'timeAgo': '2m ago',
      'distance': '200m away',
      'color': AppColors.danger,
      'icon': Icons.record_voice_over,
    },
    {
      'type': 'Caution Area',
      'description': 'Low lighting reported on main street walkway.',
      'timeAgo': '15m ago',
      'distance': '0.5km away',
      'color': Colors.amber,
      'icon': Icons.warning,
    },
    {
      'type': 'Safe Zone Active',
      'description': 'Police presence increased near main bridge entrance.',
      'timeAgo': 'Now',
      'distance': '1.2km away',
      'color': AppColors.secondary,
      'icon': Icons.thumb_up,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map background
        const MapViewBackground(),

        // Incident markers on map
        _buildMapMarkers(),

        // Filter section
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                MapFilterSection(
                  onFilterChanged: (filter) {
                    setState(() => selectedFilter = filter);
                  },
                ),
              ],
            ),
          ),
        ),

        // SOS button
        Positioned(
          right: 16,
          bottom: 140,
          child: MapSOSButton(
            onPressed: () {
              // SOS action
            },
          ),
        ),

        // Nearby alerts section at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildNearbyAlertsSection(),
        ),
      ],
    );
  }

  Widget _buildMapMarkers() {
    return Stack(
      children: [
        // Red danger marker with pulsing effect
        Positioned(
          top: MediaQuery.of(context).size.height * 0.35,
          left: MediaQuery.of(context).size.width * 0.25,
          child: _buildIncidentMarker(
            icon: Icons.priority_high,
            label: 'Harassment',
            color: AppColors.danger,
            isPulsing: true,
          ),
        ),
        // Safe zone marker
        Positioned(
          top: MediaQuery.of(context).size.height * 0.62,
          right: MediaQuery.of(context).size.width * 0.15,
          child: _buildIncidentMarker(
            icon: Icons.verified_user,
            label: '',
            color: AppColors.secondary,
            size: 32,
          ),
        ),
        // User location marker (center)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.5,
          left: MediaQuery.of(context).size.width * 0.5,
          child: Transform.translate(
            offset: const Offset(-8, -8),
            child: _buildUserMarker(),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentMarker({
    required IconData icon,
    required String label,
    required Color color,
    double size = 40,
    bool isPulsing = false,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isPulsing)
              FadeTransition(
                opacity: Tween<double>(begin: 0.3, end: 0.0).animate(
                  CurvedAnimation(
                    parent: _pulseController1,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  width: size * 1.5,
                  height: size * 1.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.6),
                  ),
                ),
              ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: size * 0.5),
            ),
          ],
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomText(
              text: label,
              size: 10,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing ring
        SizedBox(
          width: 64,
          height: 64,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.2).animate(
              CurvedAnimation(
                parent: _userMarkerController,
                curve: Curves.easeInOut,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.2),
              ),
            ),
          ),
        ),
        // Inner marker
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.withOpacity(0.2),
          ),
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.secondary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyAlertsSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        color: AppTheme.getCardBackgroundColor(),
        border: Border(
          top: BorderSide(color: AppTheme.getBorderColor(), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Nearby Alerts',
                size: 13,
                weight: FontWeight.w600,
                color: AppTheme.getPrimaryTextColor(),
              ),
              GestureDetector(
                onTap: () {},
                child: CustomText(
                  text: 'View all',
                  size: 11,
                  weight: FontWeight.w500,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Alert cards carousel
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nearbyAlerts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final alert = nearbyAlerts[index];
                return AlertCard(
                  alertType: alert['type'],
                  description: alert['description'],
                  timeAgo: alert['timeAgo'],
                  distance: alert['distance'],
                  borderColor: alert['color'],
                  icon: alert['icon'],
                  onTap: () {
                    // Handle alert tap
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
