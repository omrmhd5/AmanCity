import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../models/report_incident_model.dart';
import '../widgets/report/incident_type_button.dart';
import '../widgets/report/location_context_card.dart';
import '../widgets/report/evidence_type_selector.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({Key? key}) : super(key: key);

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  IncidentCategory? _selectedCategory;
  EvidenceType? _selectedEvidenceType;
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      // Default to Cairo if location fails
      setState(() {
        _currentLocation = const LatLng(30.0444, 31.2357);
      });
    }
  }

  void _onIncidentTypeSelected(IncidentCategory category) {
    setState(() {
      _selectedCategory = category;
    });
    // TODO: Navigate to next step with selected category
  }

  void _onEvidenceTypeSelected(EvidenceType type) {
    setState(() {
      _selectedEvidenceType = type;
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
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Text(
                    'Report Incident',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                  ),
                ),
                // Location Context Card
                if (_currentLocation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: LocationContextCard(
                      latitude: _currentLocation!.latitude,
                      longitude: _currentLocation!.longitude,
                      isLoading: _isLoadingLocation,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildLocationLoadingShimmer(),
                  ),
                // Evidence Type Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evidence Type',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getSecondaryTextColor(),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      EvidenceTypeSelector(
                        selectedType: _selectedEvidenceType,
                        onTypeSelected: _onEvidenceTypeSelected,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Incident Categories Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'What happened?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getSecondaryTextColor(),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Grid of incident categories
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        IncidentTypeButton(
                          category: IncidentCategory.harassment,
                          title: 'Harassment',
                          subtitle: 'Verbal or physical advances',
                          icon: Icons.back_hand,
                          iconColor: const Color(0xFF4F46E5),
                          backgroundColor: const Color(
                            0xFF4F46E5,
                          ).withOpacity(0.1),
                          isSelected:
                              _selectedCategory == IncidentCategory.harassment,
                          onTap: () => _onIncidentTypeSelected(
                            IncidentCategory.harassment,
                          ),
                        ),
                        IncidentTypeButton(
                          category: IncidentCategory.suspicious,
                          title: 'Suspicious',
                          subtitle: 'Unusual behavior or objects',
                          icon: Icons.visibility,
                          iconColor: const Color(0xFFD97706),
                          backgroundColor: const Color(
                            0xFFD97706,
                          ).withOpacity(0.1),
                          isSelected:
                              _selectedCategory == IncidentCategory.suspicious,
                          onTap: () => _onIncidentTypeSelected(
                            IncidentCategory.suspicious,
                          ),
                        ),
                        IncidentTypeButton(
                          category: IncidentCategory.theft,
                          title: 'Theft',
                          subtitle: 'Lost property or robbery',
                          icon: Icons.local_mall,
                          iconColor: const Color(0xFF9333EA),
                          backgroundColor: const Color(
                            0xFF9333EA,
                          ).withOpacity(0.1),
                          isSelected:
                              _selectedCategory == IncidentCategory.theft,
                          onTap: () =>
                              _onIncidentTypeSelected(IncidentCategory.theft),
                        ),
                        IncidentTypeButton(
                          category: IncidentCategory.medical,
                          title: 'Medical',
                          subtitle: 'Injury or health crisis',
                          icon: Icons.medical_services,
                          iconColor: const Color(0xFF10B981),
                          backgroundColor: const Color(
                            0xFF10B981,
                          ).withOpacity(0.1),
                          isSelected:
                              _selectedCategory == IncidentCategory.medical,
                          onTap: () =>
                              _onIncidentTypeSelected(IncidentCategory.medical),
                        ),
                        IncidentTypeButton(
                          category: IncidentCategory.fire,
                          title: 'Fire',
                          subtitle: 'Smoke or flames sighted',
                          icon: Icons.local_fire_department,
                          iconColor: const Color(0xFFEA580C),
                          backgroundColor: const Color(
                            0xFFEA580C,
                          ).withOpacity(0.1),
                          isSelected:
                              _selectedCategory == IncidentCategory.fire,
                          onTap: () =>
                              _onIncidentTypeSelected(IncidentCategory.fire),
                        ),
                        IncidentTypeButton(
                          category: IncidentCategory.other,
                          title: 'Other',
                          subtitle: 'Domestic or unspecified',
                          icon: Icons.more_horiz,
                          iconColor: const Color(0xFF64748B),
                          backgroundColor: const Color(
                            0xFF64748B,
                          ).withOpacity(0.05),
                          isSelected:
                              _selectedCategory == IncidentCategory.other,
                          onTap: () =>
                              _onIncidentTypeSelected(IncidentCategory.other),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationLoadingShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.currentMode == AppThemeMode.dark
            ? AppColors.primary
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Shimmer.fromColors(
              baseColor: Colors.grey,
              highlightColor: Colors.white,
              child: SizedBox.expand(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Shimmer extends StatefulWidget {
  final Color baseColor;
  final Color highlightColor;
  final Widget child;

  const Shimmer.fromColors({
    required this.baseColor,
    required this.highlightColor,
    required this.child,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(
                -1.0 - _shimmerController.value * 2,
                _shimmerController.value * 2,
              ),
              end: Alignment(
                2.0 - _shimmerController.value * 2,
                _shimmerController.value * 2,
              ),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
