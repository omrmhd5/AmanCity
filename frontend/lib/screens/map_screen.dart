import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../widgets/map/map_filter_section.dart';

import '../widgets/map/poi_detail_sheet.dart';
import '../widgets/map/map_loading_indicator.dart';
import '../widgets/map/nearby_alerts_sheet.dart';
import '../models/map_incident.dart';
import '../models/emergency_poi.dart';
import '../models/danger_zone.dart';
import '../services/backend_api/incident_api_service.dart';
import 'incident_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key, this.onReportPressed}) : super(key: key);

  final VoidCallback? onReportPressed;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  String? selectedFilter;

  // Map data
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  List<MapIncident> _incidents = [];
  List<EmergencyPOI> _pois = [];
  List<DangerZone> _dangerZones = [];

  // Cairo initial position
  static const LatLng _cairoCenter = LatLng(30.0444, 31.2357);
  static const double _initialZoom = 14.0;

  // User location
  LatLng? _userLocation;
  bool _isLoadingLocation = false;

  // Cache for custom marker icons
  final Map<String, BitmapDescriptor> _markerIconCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadIncidents();
    _getUserLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh incidents when app comes back to foreground
      _loadIncidents();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    try {
      final incidents = await IncidentApiService.getIncidents();
      setState(() {
        _incidents = incidents;
      });
      _updateMapElements();
    } catch (e) {
      print('❌ Error loading incidents: $e');
    }
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Animate camera to user location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 15.0),
      );

      _updateMapElements();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint('Error getting location: $e');
    }
  }

  void _updateMapElements() {
    _markers.clear();
    _circles.clear();

    // Add incident markers with custom icons
    for (var incident in _incidents) {
      _markers.add(
        Marker(
          markerId: MarkerId(incident.id),
          position: incident.position,
          icon: _getCustomIncidentMarker(incident),
          consumeTapEvents: true,
          onTap: () => _onIncidentTapped(incident),
        ),
      );
    }

    // Add POI markers
    for (var poi in _pois) {
      _markers.add(
        Marker(
          markerId: MarkerId(poi.id),
          position: poi.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getHueFromColor(poi.markerColor),
          ),
          consumeTapEvents: true,
          onTap: () => _onPOITapped(poi),
        ),
      );
    }

    // Add user location marker if available
    if (_userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    // Add danger zones as circles
    for (var zone in _dangerZones) {
      _circles.add(
        Circle(
          circleId: CircleId(zone.id),
          center: zone.center,
          radius: zone.radiusMeters,
          fillColor: zone.zoneColor,
          strokeColor: zone.strokeColor,
          strokeWidth: 2,
        ),
      );
    }

    setState(() {});
  }

  /// Creates a custom map marker icon with incident type icon
  BitmapDescriptor _getCustomIncidentMarker(MapIncident incident) {
    // Check cache first
    final cacheKey = '${incident.type}_${incident.typeColor.value}';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    // Create new icon (will be cached after rendering)
    final iconData = incident.typeIcon;
    final iconColor = Colors.white;
    final backgroundColor = incident.typeColor;

    // We'll create the icon asynchronously and store in cache
    // For now, return a default and let it update
    _createAndCacheMarkerIcon(cacheKey, iconData, iconColor, backgroundColor);

    return BitmapDescriptor.defaultMarkerWithHue(
      _getHueFromColor(backgroundColor),
    );
  }

  /// Renders an icon to a bitmap and caches it
  Future<void> _createAndCacheMarkerIcon(
    String cacheKey,
    IconData iconData,
    Color iconColor,
    Color backgroundColor,
  ) async {
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = 120.0;

      // Draw circular background with shadow
      final paint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;

      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      // Draw shadow
      canvas.drawCircle(
        const Offset(size / 2, size / 2 + 2),
        size / 2,
        shadowPaint,
      );

      // Draw background circle
      canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        borderPaint,
      );

      // Draw icon
      final textPainter = TextPainter(textDirection: TextDirection.ltr);

      textPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          color: iconColor,
          fontSize: 55,
          fontFamily: iconData.fontFamily,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size / 2) - (textPainter.width / 2),
          (size / 2) - (textPainter.height / 2),
        ),
      );

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      final bitmapDescriptor = BitmapDescriptor.fromBytes(
        bytes!.buffer.asUint8List(),
      );

      // Cache the result
      _markerIconCache[cacheKey] = bitmapDescriptor;

      // Rebuild markers with cached icon
      if (mounted) {
        _updateMapElements();
      }
    } catch (e) {
      debugPrint('Error creating marker icon: $e');
    }
  }

  double _getHueFromColor(Color color) {
    if (color == AppColors.danger || color.value == Colors.red.value) {
      return BitmapDescriptor.hueRed;
    } else if (color.value == Colors.amber.value ||
        color.value == Colors.orange.value) {
      return BitmapDescriptor.hueOrange;
    } else if (color.value == Colors.green.value) {
      return BitmapDescriptor.hueGreen;
    } else if (color == AppColors.secondary) {
      return BitmapDescriptor.hueCyan;
    } else if (color.value == Colors.blue.value) {
      return BitmapDescriptor.hueBlue;
    }
    return BitmapDescriptor.hueRed;
  }

  void _onIncidentTapped(MapIncident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentDetailScreen(
        incident: incident,
        timeAgo: _getTimeAgo(incident.timestamp),
      ),
    );
  }

  void _onPOITapped(EmergencyPOI poi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => POIDetailSheet(poi: poi),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Mock data for nearby alerts carousel
  List<Map<String, dynamic>> get nearbyAlerts {
    return _incidents.take(3).map((incident) {
      return {
        'incident': incident,
        'type': incident.type,
        'title': incident.title,
        'description': incident.description,
        'timeAgo': _getTimeAgo(incident.timestamp),
        'distance':
            '${((incident.position.latitude - _cairoCenter.latitude).abs() * 111).toStringAsFixed(1)}km away',
        'color': incident.typeColor,
        'icon': incident.typeIcon,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _cairoCenter,
            zoom: _initialZoom,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            // Apply dark/light theme to map
            _setMapStyle();
          },
          markers: _markers,
          circles: _circles,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          trafficEnabled: false,
          buildingsEnabled: true,
        ),

        // Filter section
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                MapFilterSection(
                  onFilterChanged: (filter) {
                    setState(() => selectedFilter = filter);
                    _applyFilter(filter);
                  },
                ),
              ],
            ),
          ),
        ),

        // Report button
        Positioned(
          right: 16,
          bottom: 180,
          child: FloatingActionButton(
            heroTag: 'report_button',
            backgroundColor: Colors.red.shade500,
            onPressed: widget.onReportPressed,
            child: const Icon(
              Icons.announcement,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),

        // My Location button
        Positioned(
          right: 16,
          bottom: 110,
          child: FloatingActionButton(
            heroTag: 'my_location_button',
            backgroundColor: Colors.blue.shade400,
            onPressed: () {
              if (_userLocation != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation!, 15.0),
                );
              } else {
                _getUserLocation();
              }
            },
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),

        // Nearby alerts section at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildNearbyAlertsSection(),
        ),

        // Loading indicator
        if (_isLoadingLocation)
          const Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: MapLoadingIndicator(),
          ),
      ],
    );
  }

  Future<void> _setMapStyle() async {
    if (_mapController == null) return;

    // Apply different styles based on theme
    if (AppTheme.currentMode == AppThemeMode.dark) {
      const String darkMapStyle = '''
      [
        {
          "elementType": "geometry",
          "stylers": [{"color": "#212121"}]
        },
        {
          "elementType": "labels.icon",
          "stylers": [{"visibility": "off"}]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#757575"}]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#212121"}]
        },
        {
          "featureType": "administrative",
          "elementType": "geometry",
          "stylers": [{"color": "#757575"}]
        },
        {
          "featureType": "poi",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#757575"}]
        },
        {
          "featureType": "poi.park",
          "elementType": "geometry",
          "stylers": [{"color": "#181818"}]
        },
        {
          "featureType": "road",
          "elementType": "geometry.fill",
          "stylers": [{"color": "#5a5a5a"}]
        },
        {
          "featureType": "road",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#b0b0b0"}]
        },
        {
          "featureType": "water",
          "elementType": "geometry",
          "stylers": [{"color": "#000000"}]
        },
        {
          "featureType": "water",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#3d3d3d"}]
        }
      ]
      ''';
      await _mapController?.setMapStyle(darkMapStyle);
    } else {
      await _mapController?.setMapStyle(null); // Use default light style
    }
  }

  void _applyFilter(String? filter) {
    // Filter logic - could filter markers/circles based on selection
    // For now, just reload all data
    // In production, this would filter _incidents, _pois based on type
    if (filter != null) {
      // Example: filter by type
      setState(() {
        // Could filter _incidents, _pois here
      });
    }
    _updateMapElements();
  }

  Widget _buildNearbyAlertsSection() {
    return NearbyAlertsSheet(
      alerts: nearbyAlerts,
      onScrollControllerReady: (controller) {
        // Scroll controller callback
      },
    );
  }
}
