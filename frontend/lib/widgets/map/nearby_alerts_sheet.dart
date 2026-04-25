import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/app_theme.dart';
import '../../data/incident_types_config.dart';
import '../../models/map_incident.dart';
import '../shared/custom_text.dart';
import '../shared/custom_search_bar.dart';
import 'nearby_alert_card.dart';
import '../../screens/incident_detail_sheet.dart';

class NearbyAlertsSheet extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;
  final Function(ScrollController)? onScrollControllerReady;
  final Function(VoidCallback)? onSheetReady;
  final Future<void> Function(MapIncident)? onIncidentTapped;

  const NearbyAlertsSheet({
    Key? key,
    required this.alerts,
    this.onScrollControllerReady,
    this.onSheetReady,
    this.onIncidentTapped,
  }) : super(key: key);

  @override
  State<NearbyAlertsSheet> createState() => _NearbyAlertsSheetState();
}

class _NearbyAlertsSheetState extends State<NearbyAlertsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  bool _isExpanded = false;
  bool _showAllTypes = false;
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
          alert['title'].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter =
          _selectedFilter == null ||
          alert['type'].toLowerCase() == _selectedFilter!.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  MapIncident _alertToIncident(Map<String, dynamic> alert) {
    // If the full incident object is passed, use it directly
    if (alert['incident'] != null) {
      return alert['incident'] as MapIncident;
    }

    // Fallback for backward compatibility - map color to incident type
    var typeString = alert['type'] as String;
    final color = alert['color'] as Color;

    if (color.value == const Color(0xFFB91C1C).value ||
        color.value == const Color(0xFFEF4444).value) {
      typeString = 'Fire';
    } else if (color.value == Colors.orange.value) {
      typeString = 'Accident';
    } else if (color.value == Colors.amber.value) {
      typeString = 'Public Issue';
    }

    return MapIncident(
      id: alert['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: typeString,
      position: const LatLng(30.0444, 31.2357), // Default Cairo coordinates
      title: alert['title'] as String? ?? '',
      description: alert['description'] as String,
      timestamp: DateTime.now(),
      addressText: alert['location']?['text'] as String?,
      city: alert['location']?['city'] as String?,
    );
  }

  void _showIncidentDetails(Map<String, dynamic> alert) {
    final incident = _alertToIncident(alert);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return IncidentDetailScreen(
          incident: incident,
          timeAgo: alert['timeAgo'] as String,
          onNavigate: widget.onIncidentTapped,
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
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // "All" button
                                  FilterChip(
                                    label: const Text(
                                      'All',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                    selected: _selectedFilter == null,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedFilter = null;
                                      });
                                    },
                                    selectedColor: const Color(0xFF00A86B),
                                    backgroundColor:
                                        AppTheme.getCardBackgroundColor(),
                                    side: BorderSide(
                                      color: _selectedFilter == null
                                          ? const Color(0xFF00A86B)
                                          : AppTheme.getBorderColor(),
                                      width: _selectedFilter == null ? 2 : 1,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Incident types (limited to 9 or all if expanded)
                                  ...List.generate(
                                    _showAllTypes
                                        ? IncidentTypesConfig.allTypes.length
                                        : 9,
                                    (index) {
                                      final config =
                                          IncidentTypesConfig.allTypes[index];
                                      final isSelected =
                                          _selectedFilter == config.key;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                        ),
                                        child: FilterChip(
                                          label: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                config.icon,
                                                size: 14,
                                                color: isSelected
                                                    ? Colors.white
                                                    : config.color,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                config.displayName,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : AppTheme.getPrimaryTextColor(),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(() {
                                              _selectedFilter = selected
                                                  ? config.key
                                                  : null;
                                            });
                                          },
                                          selectedColor: config.color,
                                          backgroundColor:
                                              AppTheme.getCardBackgroundColor(),
                                          side: BorderSide(
                                            color: isSelected
                                                ? config.color
                                                : AppTheme.getBorderColor(),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Show More button
                                  if (!_showAllTypes &&
                                      IncidentTypesConfig.allTypes.length > 9)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => _showAllTypes = true);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color:
                                                  AppTheme.getSecondaryTextColor(),
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: CustomText(
                                            text:
                                                '+${IncidentTypesConfig.allTypes.length - 9}',
                                            size: 11,
                                            weight: FontWeight.w600,
                                            color:
                                                AppTheme.getSecondaryTextColor(),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
                                        incidentType: alert['type'],
                                        title: alert['title'],
                                        timeAgo: alert['timeAgo'],
                                        distance: alert['distance'],
                                        borderColor: alert['color'],
                                        icon: alert['icon'],
                                        confidence: alert['confidence'] ?? 0.0,
                                        locationText:
                                            alert['location']?['text']
                                                as String?,
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
