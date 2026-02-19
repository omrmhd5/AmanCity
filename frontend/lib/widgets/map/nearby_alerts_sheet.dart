import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/app_theme.dart';
import '../../models/map_incident.dart';
import '../custom_text.dart';
import '../custom_search_bar.dart';
import '../custom_filter_chips.dart';
import 'nearby_alert_card.dart';
import 'incident_detail_sheet.dart';

class NearbyAlertsSheet extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;
  final Function(ScrollController)? onScrollControllerReady;
  final Function(VoidCallback)? onSheetReady;

  const NearbyAlertsSheet({
    Key? key,
    required this.alerts,
    this.onScrollControllerReady,
    this.onSheetReady,
  }) : super(key: key);

  @override
  State<NearbyAlertsSheet> createState() => _NearbyAlertsSheetState();
}

class _NearbyAlertsSheetState extends State<NearbyAlertsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  bool _isExpanded = false;
  String _searchQuery = '';
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scrollController = ScrollController();
    widget.onScrollControllerReady?.call(_scrollController);
    widget.onSheetReady?.call(_toggleSheet);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSheet() {
    if (_isExpanded) {
      _animationController.reverse();
      _isExpanded = false;
    } else {
      _animationController.forward();
      _isExpanded = true;
    }
  }

  List<Map<String, dynamic>> _getFilteredAlerts() {
    return widget.alerts.where((alert) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          alert['type'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          alert['description'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesFilter =
          _selectedFilter == null ||
          alert['type'].toLowerCase() == _selectedFilter!.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Set<String> _getAlertTypes() {
    return widget.alerts.map((alert) => alert['type'] as String).toSet();
  }

  MapIncident _alertToIncident(Map<String, dynamic> alert) {
    // Convert alert type string to IncidentType enum
    final typeString = (alert['type'] as String).toLowerCase();
    IncidentType incidentType = IncidentType.other;

    if (typeString.contains('harass')) {
      incidentType = IncidentType.harassment;
    } else if (typeString.contains('theft')) {
      incidentType = IncidentType.theft;
    } else if (typeString.contains('assault')) {
      incidentType = IncidentType.assault;
    } else if (typeString.contains('suspicious')) {
      incidentType = IncidentType.suspicious;
    }

    // Determine severity based on alert color intensity
    final color = alert['color'] as Color;
    SeverityLevel severity = SeverityLevel.low;
    if (color.value == const Color(0xFFB91C1C).value) {
      severity = SeverityLevel.critical;
    } else if (color.value == const Color(0xFFEF4444).value) {
      severity = SeverityLevel.high;
    } else if (color.value == Colors.orange.value) {
      severity = SeverityLevel.medium;
    } else if (color.value == Colors.amber.value) {
      severity = SeverityLevel.low;
    }

    return MapIncident(
      id: alert['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: incidentType,
      severity: severity,
      position: const LatLng(30.0444, 31.2357), // Default Cairo coordinates
      title: alert['type'] as String,
      description: alert['description'] as String,
      timestamp: DateTime.now(),
    );
  }

  void _showIncidentDetails(Map<String, dynamic> alert) {
    final incident = _alertToIncident(alert);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return IncidentDetailSheet(
          incident: incident,
          timeAgo: alert['timeAgo'] as String,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85;
    final minHeight = 100.0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final currentHeight =
            minHeight + (_animationController.value * (maxHeight - minHeight));

        return SizedBox(
          height: currentHeight,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 5 && _isExpanded) {
                _animationController.reverse();
                _isExpanded = false;
              } else if (details.delta.dy < -5 && !_isExpanded) {
                _animationController.forward();
                _isExpanded = true;
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.getBackgroundColor(),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle + Header
                  GestureDetector(
                    onTap: _toggleSheet,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.getBorderColor(),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: 'Nearby Alerts',
                                    size: 16,
                                    weight: FontWeight.w800,
                                    color: AppTheme.getPrimaryTextColor(),
                                  ),
                                  const SizedBox(height: 2),
                                  CustomText(
                                    text:
                                        '${_getFilteredAlerts().length} of ${widget.alerts.length} incidents',
                                    size: 11,
                                    weight: FontWeight.w400,
                                    color: AppTheme.getSecondaryTextColor(),
                                  ),
                                ],
                              ),
                              Icon(
                                _isExpanded
                                    ? Icons.unfold_less
                                    : Icons.unfold_more,
                                color: AppTheme.getSecondaryTextColor(),
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Divider
                  Divider(color: AppTheme.getBorderColor(), height: 0.5),
                  // Scrollable content area with search, filters, and alerts
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: CustomSearchBar(
                              hintText: 'Search incidents...',
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                            ),
                          ),
                          // Filter Chips
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: SizedBox(
                              height: 40,
                              child: CustomFilterChips(
                                filters: [
                                  {'label': 'All', 'icon': null},
                                  ..._getAlertTypes()
                                      .map(
                                        (type) => {'label': type, 'icon': null},
                                      )
                                      .toList(),
                                ],
                                selectedFilter: _selectedFilter ?? 'All',
                                onFilterChanged: (selected) {
                                  setState(() {
                                    _selectedFilter = selected == 'All'
                                        ? null
                                        : selected;
                                  });
                                },
                                showIcon: false,
                                selectedColor: const Color(0xFF00A86B),
                              ),
                            ),
                          ),
                          // Alerts list
                          if (_getFilteredAlerts().isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: CustomText(
                                text: 'No alerts found',
                                size: 14,
                                weight: FontWeight.w500,
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                24,
                              ),
                              child: Column(
                                children: List.generate(
                                  _getFilteredAlerts().length,
                                  (index) {
                                    final alert = _getFilteredAlerts()[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: NearbyAlertCard(
                                        alertType: alert['type'],
                                        description: alert['description'],
                                        timeAgo: alert['timeAgo'],
                                        distance: alert['distance'],
                                        borderColor: alert['color'],
                                        icon: alert['icon'],
                                        onTap: () =>
                                            _showIncidentDetails(alert),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
