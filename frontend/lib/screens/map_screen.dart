import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../widgets/map/map_filter_section.dart';
import '../widgets/map/incident_detail_sheet.dart';
import '../widgets/map/poi_detail_sheet.dart';
import '../widgets/map/map_loading_indicator.dart';
import '../widgets/map/nearby_alerts_sheet.dart';
import '../models/map_incident.dart';
import '../models/emergency_poi.dart';
import '../models/danger_zone.dart';
import '../services/mock_map_data_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _getUserLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _loadMockData() {
    setState(() {
      _incidents = MockMapDataService.getMockIncidents();
      _pois = MockMapDataService.getMockPOIs();
      _dangerZones = MockMapDataService.getMockDangerZones();
    });
    _updateMapElements();
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

      _updateMapElements();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint('Error getting location: $e');
    }
  }

  void _updateMapElements() {
    _markers.clear();
    _circles.clear();

    // Add incident markers
    for (var incident in _incidents) {
      _markers.add(
        Marker(
          markerId: MarkerId(incident.id),
          position: incident.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getHueFromColor(incident.severityColor),
          ),
          infoWindow: InfoWindow(
            title: incident.title,
            snippet: incident.description,
          ),
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
          infoWindow: InfoWindow(title: poi.name, snippet: poi.typeLabel),
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
          infoWindow: const InfoWindow(title: 'Your Location'),
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
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentDetailSheet(
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
        'type': incident.title,
        'description': incident.description,
        'timeAgo': _getTimeAgo(incident.timestamp),
        'distance':
            '${((incident.position.latitude - _cairoCenter.latitude).abs() * 111).toStringAsFixed(1)}km away',
        'color': incident.severityColor,
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

        // My Location button
        Positioned(
          right: 16,
          bottom: 100,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: AppTheme.getCardBackgroundColor().withOpacity(
              0.85,
            ),
            onPressed: () {
              if (_userLocation != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation!, 15.0),
                );
              } else {
                _getUserLocation();
              }
            },
            child: Icon(
              Icons.my_location,
              color: AppColors.secondary,
              size: 20,
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
          "stylers": [{"color": "#2c2c2c"}]
        },
        {
          "featureType": "road",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#8a8a8a"}]
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
