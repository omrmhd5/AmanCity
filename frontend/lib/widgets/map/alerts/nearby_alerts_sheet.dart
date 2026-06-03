import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../../data/incident_types_config.dart';
import '../../../models/incidents/map_incident.dart';
import '../../../models/incidents/bulk_incident.dart';
import '../../../services/map/location_service.dart';
import '../../shared/custom_text.dart';
import '../../shared/custom_search_bar.dart';
import '../../shared/custom_filter_chips.dart';
import 'nearby_alert_card.dart';
import 'nearby_bulk_alert_card.dart';
import '../../../screens/incidents/incident_detail_sheet.dart';
import '../../../screens/incidents/bulk_incident_detail_sheet.dart';
import '../../../utils/localization_formatter.dart';

class NearbyAlertsSheet extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;
  final List<BulkIncident> bulkIncidents;
  final LatLng? userLocation;
  final Function(ScrollController)? onScrollControllerReady;
  final Function(VoidCallback)? onSheetReady;
  final Future<void> Function(MapIncident)? onIncidentTapped;

  const NearbyAlertsSheet({
    Key? key,
    required this.alerts,
    this.bulkIncidents = const [],
    this.userLocation,
    this.onScrollControllerReady,
    this.onSheetReady,
    this.onIncidentTapped,
  }) : super(key: key);

  @override
  State<NearbyAlertsSheet> createState() => _NearbyAlertsSheetState();
}

class _NearbyAlertsSheetState extends State<NearbyAlertsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  late ScrollController _scrollController;
  bool _isExpanded = false;
  bool _showAllTypes = false;
  String _searchQuery = '';
  String? _selectedFilter;

  static const double _minHeight = 90.0;

  double get _maxHeight => MediaQuery.of(context).size.height * 0.8;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _staggerController.forward();
    });
    _scrollController = ScrollController();
    widget.onScrollControllerReady?.call(_scrollController);
    widget.onSheetReady?.call(_toggleSheet);
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, {double start = 0.0, double end = 1.0}) {
    final anim = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  void _toggleSheet() {
    final wasExpanded = _isExpanded;
    setState(() => _isExpanded = !_isExpanded);
    if (!wasExpanded) {
      // Replays stagger every time the sheet opens
      _staggerController.forward(from: 0);
    }
  }

  List<dynamic> _getAllAlertsWithin10km() {
    // Get all individual incidents
    final allIndividual = widget.alerts.toList();

    // Get all bulk incidents within 10km
    final allBulksWithin10km = widget.bulkIncidents.where((bulk) {
      if (widget.userLocation != null) {
        final distanceKm = LocationService.calculateDistance(
          lat1: widget.userLocation!.latitude,
          lng1: widget.userLocation!.longitude,
          lat2: bulk.center.latitude,
          lng2: bulk.center.longitude,
        );
        return distanceKm <= 10.0;
      }
      return true;
    }).toList();

    return [...allIndividual, ...allBulksWithin10km];
  }

  List<dynamic> _getFilteredAlerts() {
    // Filter individual incidents
    final filteredIndividual = widget.alerts.where((alert) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          alert['title'].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter =
          _selectedFilter == null ||
          alert['type'].toLowerCase() == _selectedFilter!.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();

    // Filter bulk incidents (only within 10km + search/type filters)
    final filteredBulks = widget.bulkIncidents.where((bulk) {
      // Filter by distance (10km range)
      if (widget.userLocation != null) {
        final distanceKm = LocationService.calculateDistance(
          lat1: widget.userLocation!.latitude,
          lng1: widget.userLocation!.longitude,
          lat2: bulk.center.latitude,
          lng2: bulk.center.longitude,
        );
        if (distanceKm > 10.0) return false;
      }

      final matchesSearch =
          _searchQuery.isEmpty ||
          bulk.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (bulk.locationText?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      final matchesFilter =
          _selectedFilter == null ||
          bulk.type.toLowerCase() == _selectedFilter!.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();

    // Combine both lists
    final combined = [...filteredIndividual, ...filteredBulks];

    // Sort by distance
    combined.sort((a, b) {
      if (widget.userLocation == null) return 0;

      // Get distance for item a
      double distanceA = 999.0;
      if (a is BulkIncident) {
        distanceA = LocationService.calculateDistance(
          lat1: widget.userLocation!.latitude,
          lng1: widget.userLocation!.longitude,
          lat2: a.center.latitude,
          lng2: a.center.longitude,
        );
      } else if (a is Map) {
        // For individual incidents, recalculate from position if available
        if (a['incident'] != null) {
          final incident = a['incident'] as MapIncident;
          distanceA = LocationService.calculateDistance(
            lat1: widget.userLocation!.latitude,
            lng1: widget.userLocation!.longitude,
            lat2: incident.position.latitude,
            lng2: incident.position.longitude,
          );
        }
      }

      // Get distance for item b
      double distanceB = 999.0;
      if (b is BulkIncident) {
        distanceB = LocationService.calculateDistance(
          lat1: widget.userLocation!.latitude,
          lng1: widget.userLocation!.longitude,
          lat2: b.center.latitude,
          lng2: b.center.longitude,
        );
      } else if (b is Map) {
        // For individual incidents, recalculate from position if available
        if (b['incident'] != null) {
          final incident = b['incident'] as MapIncident;
          distanceB = LocationService.calculateDistance(
            lat1: widget.userLocation!.latitude,
            lng1: widget.userLocation!.longitude,
            lat2: incident.position.latitude,
            lng2: incident.position.longitude,
          );
        }
      }

      return distanceA.compareTo(distanceB);
    });

    return combined;
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

  void _showBulkDetails(BulkIncident bulk) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BulkIncidentDetailSheet(bulk: bulk);
      },
    );
  }

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.getSecondaryTextColor(),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = _maxHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: _isExpanded ? maxH : _minHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Base glass fill
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.getBackgroundColor().withOpacity(0.8),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                  ),
                ),
                // Inner sheen gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35],
                      ),
                    ),
                  ),
                ),
                // Specular top strip
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Column(
                  children: [
                    // Handle + Header
                    _animated(
                      GestureDetector(
                        onTap: _toggleSheet,
                        onVerticalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity < -300 && !_isExpanded) {
                            _toggleSheet();
                          } else if (velocity > 300 && _isExpanded) {
                            _toggleSheet();
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                          child: Column(
                            children: [
                              // Handle bar
                              Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.getBorderColor(),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications_active_rounded,
                                    size: 18,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          text: 'map.nearby_alerts'.tr(),
                                          size: 16,
                                          weight: FontWeight.w800,
                                          color: AppTheme.getPrimaryTextColor(),
                                        ),
                                        const SizedBox(height: 2),
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color:
                                                  AppTheme.getSecondaryTextColor(),
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'map.alerts_count'.tr(
                                                  namedArgs: {
                                                    'filtered':
                                                        '${_getFilteredAlerts().length}',
                                                    'total':
                                                        '${_getAllAlertsWithin10km().length}',
                                                  },
                                                ),
                                                style: TextStyle(
                                                  color:
                                                      AppTheme.getSecondaryTextColor(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: _isExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    child: Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      color: AppColors.secondary,
                                      size: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      start: 0.0,
                      end: 0.5,
                    ),
                    // Teal gradient divider
                    _animated(
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary.withOpacity(0.0),
                              AppColors.secondary.withOpacity(0.3),
                              AppColors.secondary.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      start: 0.05,
                      end: 0.55,
                    ),
                    // Scrollable content
                    Expanded(
                      child: _animated(
                        SingleChildScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search Bar
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  8,
                                ),
                                child: CustomSearchBar(
                                  hintText: 'map.search_incidents'.tr(),
                                  onChanged: (value) {
                                    setState(() => _searchQuery = value);
                                  },
                                ),
                              ),
                              // Filters section label
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  8,
                                ),
                                child: _sectionLabel(
                                  Icons.tune_rounded,
                                  'map.filters'.tr(),
                                ),
                              ),
                              // Filter Chips
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      // "All" chip
                                      CustomFilterChip(
                                        label: 'map.all'.tr(),
                                        isSelected: _selectedFilter == null,
                                        selectedColor: AppColors.secondary,
                                        onTap: () => setState(
                                          () => _selectedFilter = null,
                                        ),
                                        fontSize: 12,
                                        iconSize: 14,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 9,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Incident type chips
                                      ...List.generate(
                                        _showAllTypes
                                            ? IncidentTypesConfig
                                                  .allTypes
                                                  .length
                                            : (IncidentTypesConfig
                                                          .allTypes
                                                          .length <
                                                      9
                                                  ? IncidentTypesConfig
                                                        .allTypes
                                                        .length
                                                  : 9),
                                        (index) {
                                          final config = IncidentTypesConfig
                                              .allTypes[index];
                                          final isSelected =
                                              _selectedFilter == config.key;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            child: CustomFilterChip(
                                              label: config.localizedName,
                                              icon: config.icon,
                                              isSelected: isSelected,
                                              selectedColor: config.color,
                                              iconColor: config.color,
                                              onTap: () => setState(() {
                                                _selectedFilter = isSelected
                                                    ? null
                                                    : config.key;
                                              }),
                                              fontSize: 12,
                                              iconSize: 14,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 9,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Show More button
                                      if (!_showAllTypes &&
                                          IncidentTypesConfig.allTypes.length >
                                              9)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          child: GestureDetector(
                                            onTap: () => setState(
                                              () => _showAllTypes = true,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 7,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: AppColors.secondary,
                                                  width: 1.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                '+${IncidentTypesConfig.allTypes.length - 9}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.secondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Alerts section label
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  10,
                                ),
                                child: _sectionLabel(
                                  Icons.warning_amber_rounded,
                                  'map.alerts'.tr(),
                                ),
                              ),
                              // Alerts list
                              if (_getFilteredAlerts().isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 32,
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.search_off_rounded,
                                          size: 36,
                                          color:
                                              AppTheme.getSecondaryTextColor()
                                                  .withOpacity(0.4),
                                        ),
                                        const SizedBox(height: 8),
                                        CustomText(
                                          text: 'map.no_alerts_found'.tr(),
                                          size: 14,
                                          weight: FontWeight.w500,
                                          color:
                                              AppTheme.getSecondaryTextColor(),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    100,
                                  ),
                                  child: Column(
                                    children: List.generate(
                                      _getFilteredAlerts().length,
                                      (index) {
                                        final item =
                                            _getFilteredAlerts()[index];

                                        if (item is BulkIncident) {
                                          final bulk = item;
                                          final distanceKm =
                                              widget.userLocation != null
                                              ? LocationService.calculateDistance(
                                                  lat1: widget
                                                      .userLocation!
                                                      .latitude,
                                                  lng1: widget
                                                      .userLocation!
                                                      .longitude,
                                                  lat2: bulk.center.latitude,
                                                  lng2: bulk.center.longitude,
                                                )
                                              : 0.0;

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: NearbyBulkAlertCard(
                                              incidentType:
                                                  IncidentTypesConfig.getByKey(
                                                    bulk.type,
                                                  ).localizedName,
                                              count: bulk.count,
                                              timeAgo: LocalizationFormatter.formatTimeAgo(
                                                context,
                                                bulk.lastUpdatedAt,
                                              ),
                                              distance: 'map.away_suffix'.tr(
                                                namedArgs: {
                                                  'distance': LocalizationFormatter.formatDistance(
                                                    context,
                                                    LocationService.formatDistance(distanceKm),
                                                  ),
                                                },
                                              ),
                                              borderColor: bulk.typeColor,
                                              icon: bulk.typeIcon,
                                              avgConfidence: bulk.avgConfidence,
                                              locationText: bulk.locationText,
                                              hasHumanReports:
                                                  bulk.hasHumanReports,
                                              hasOsintReports:
                                                  bulk.hasOsintReports,
                                              onTap: () =>
                                                  _showBulkDetails(bulk),
                                            ),
                                          );
                                        } else {
                                          final alert =
                                              item as Map<String, dynamic>;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: NearbyAlertCard(
                                              incidentType:
                                                  IncidentTypesConfig.getByKey(
                                                    alert['type'],
                                                  ).localizedName,
                                              title: alert['title'],
                                              timeAgo: alert['timeAgo'],
                                              distance: alert['distance'],
                                              borderColor: alert['color'],
                                              icon: alert['icon'],
                                              confidence:
                                                  alert['confidence'] ?? 0.0,
                                              locationText:
                                                  alert['location']?['text']
                                                      as String?,
                                              onTap: () =>
                                                  _showIncidentDetails(alert),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        start: 0.1,
                        end: 0.85,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
