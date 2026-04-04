import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../widgets/map/map_filter_section.dart';
import '../widgets/map/filter_options_sheet.dart';
import '../widgets/map/poi_detail_sheet.dart';
import '../widgets/map/map_loading_indicator.dart';
import '../widgets/map/nearby_alerts_sheet.dart';
import '../models/map_incident.dart';
import '../models/emergency_poi.dart';
import '../models/danger_zone.dart';
import '../services/backend_api/incident_api_service.dart';
import '../services/backend_api/places_api_service.dart';
import '../services/location_service.dart';
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

  // POI filtering
  String _poiFilter =
      'all'; // 'all', 'hospital', 'police', 'fire', or pipe-separated like 'hospital|police'
  Set<String> _selectedPoiFilters = {}; // Track which filters are selected
  bool _showPOIs = true;
  DateTime? _poisCachedTime;
  static const int _poiCacheDurationMinutes = 5;

  // POI settings
  double _radiusKm = 5.0;

  // User location
  LatLng? _userLocation;
  bool _isLoadingLocation = false;

  // Initial camera position (will be set from user location)
  late CameraPosition _initialCameraPosition;
  bool _locationLoaded = false;

  // Cache for custom marker icons
  final Map<String, BitmapDescriptor> _markerIconCache = {};

  // Location cache
  DateTime? _locationCachedTime;
  static const int _locationCacheDurationMinutes =
      60; // Cache location for 60 minutes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize with all POI types selected by default
    _selectedPoiFilters = {'hospital', 'police', 'fire'};
    _updatePoiFilter();

    _loadIncidents();
    _loadUserLocationFromCache(); // Try to load cached location first (required before building map)
    _loadPOIs();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh incidents when app comes back to foreground
      _loadIncidents();
      // Only fetch new location if cache is old
      _refreshLocationIfNeeded();
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

  /// Load location from cache if available and fresh
  Future<void> _loadUserLocationFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLat = prefs.getDouble('user_location_lat');
      final cachedLng = prefs.getDouble('user_location_lng');
      final cachedTimeStr = prefs.getString('user_location_time');

      if (cachedLat != null && cachedLng != null && cachedTimeStr != null) {
        final cachedTime = DateTime.parse(cachedTimeStr);
        final age = DateTime.now().difference(cachedTime);

        if (age.inMinutes < _locationCacheDurationMinutes) {
          // Cache is fresh, use it
          setState(() {
            _userLocation = LatLng(cachedLat, cachedLng);
            _locationCachedTime = cachedTime;
            // Update initial camera position to user location
            _initialCameraPosition = CameraPosition(
              target: _userLocation!,
              zoom: 15.0,
            );
            _locationLoaded = true;
          });
          print('📍 Using cached location (${age.inSeconds}s old)');

          // Animate camera to cached location
          await Future.delayed(const Duration(milliseconds: 500));
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_userLocation!, 15.0),
          );

          _loadPOIs(); // Load POIs with cached location
          return;
        }
      }
    } catch (e) {
      print('⚠️ Error loading cached location: $e');
    }

    // No valid cache, fetch fresh location
    await _getUserLocation();
  }

  /// Refresh location only if cache is old
  Future<void> _refreshLocationIfNeeded() async {
    if (_locationCachedTime != null) {
      final age = DateTime.now().difference(_locationCachedTime!);
      if (age.inMinutes < _locationCacheDurationMinutes) {
        print('📍 Location cache still fresh, skipping refresh');
        return; // Cache still fresh
      }
    }

    // Cache is old or empty, fetch fresh location
    print('📍 Location cache expired, fetching fresh location...');
    await _getUserLocation();
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
      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = newLocation;
        _isLoadingLocation = false;
        _locationCachedTime = DateTime.now();
        // Update initial camera position to user location
        _initialCameraPosition = CameraPosition(
          target: _userLocation!,
          zoom: 15.0,
        );
        _locationLoaded = true;
      });

      // Cache the location
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('user_location_lat', position.latitude);
        await prefs.setDouble('user_location_lng', position.longitude);
        await prefs.setString(
          'user_location_time',
          DateTime.now().toIso8601String(),
        );
        print('✅ Location cached');
      } catch (e) {
        print('⚠️ Failed to cache location: $e');
      }

      // Animate camera to user location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 15.0),
      );

      // Reload POIs for user's location
      _poisCachedTime = null; // Invalidate cache
      await _loadPOIs();

      _updateMapElements();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadPOIs() async {
    // Check cache validity
    if (_poisCachedTime != null) {
      final age = DateTime.now().difference(_poisCachedTime!);
      if (age.inMinutes < _poiCacheDurationMinutes) {
        print('📍 Using cached POIs (${age.inSeconds}s old)');
        return;
      }
    }

    // Don't load if no location
    if (_userLocation == null) {
      print('⚠️ User location not available, cannot load POIs');
      return;
    }

    // Don't load if no filters selected
    if (_selectedPoiFilters.isEmpty) {
      setState(() {
        _pois = [];
      });
      _updateMapElements();
      return;
    }

    final initialLocation = _userLocation!;

    try {
      print(
        '📍 Loading POIs around lat=${initialLocation.latitude}, lng=${initialLocation.longitude}, radius=${_radiusKm}km',
      );

      final pois = await PlacesApiService.getNearbyPlaces(
        initialLocation,
        type: _poiFilter,
        radiusKm: _radiusKm,
      );

      setState(() {
        _pois = pois;
        _poisCachedTime = DateTime.now();
      });

      _updateMapElements();
    } catch (e) {
      print('❌ Error loading POIs: $e');
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

    // Add POI markers (if POI display is enabled)
    if (_showPOIs) {
      for (var poi in _pois) {
        _markers.add(
          Marker(
            markerId: MarkerId('poi_${poi.id}'),
            position: poi.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getHueFromColor(poi.markerColor),
            ),
            consumeTapEvents: true,
            onTap: () => _onPOITapped(poi),
          ),
        );
      }
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
    if (_userLocation == null) return []; // No alerts without user location

    return _incidents.take(3).map((incident) {
      return {
        'incident': incident,
        'type': incident.type,
        'title': incident.title,
        'description': incident.description,
        'timeAgo': _getTimeAgo(incident.timestamp),
        'distance':
            LocationService.formatDistance(
              LocationService.calculateDistance(
                lat1: _userLocation!.latitude,
                lng1: _userLocation!.longitude,
                lat2: incident.position.latitude,
                lng2: incident.position.longitude,
              ),
            ) +
            ' away',
        'color': incident.typeColor,
        'icon': incident.typeIcon,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map - only show when location is loaded
        if (_locationLoaded)
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
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
          )
        else
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red.shade700),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your location...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

        // Filter section
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                MapFilterSection(
                  currentRadius: _radiusKm,
                  onFilterChanged: (filter) {
                    setState(() => selectedFilter = filter);
                    _applyFilter(filter);
                  },
                  onSettingsChanged: _handleSettingsChanged,
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
            child: const Icon(Icons.my_location, color: Colors.white, size: 24),
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
    if (filter == null) return;

    // Map filter labels to POI types
    final poiFilterMap = {
      'Hospitals': 'hospital',
      'Police Stations': 'police',
      'Fire Stations': 'fire',
    };

    // Check if filter is a POI filter
    if (poiFilterMap.containsKey(filter)) {
      final poiType = poiFilterMap[filter]!;

      // Toggle the filter on/off
      setState(() {
        if (_selectedPoiFilters.contains(poiType)) {
          _selectedPoiFilters.remove(poiType);
        } else {
          _selectedPoiFilters.add(poiType);
        }
        _updatePoiFilter();
      });

      // Reload POIs with new filter
      _poisCachedTime = null;
      _loadPOIs();
    }
  }

  /// Update the _poiFilter string based on selected filters
  void _updatePoiFilter() {
    if (_selectedPoiFilters.isEmpty) {
      _poiFilter = 'none'; // No type selected
    } else if (_selectedPoiFilters.length == 1) {
      _poiFilter = _selectedPoiFilters.first;
    } else {
      // Multiple filters selected - join with pipe
      _poiFilter = _selectedPoiFilters.toList().join('|');
    }
  }

  /// Handle settings changes from filter sheet
  void _handleSettingsChanged(FilterSettings settings) {
    setState(() {
      _radiusKm = settings.radiusKm;
    });
    // Invalidate cache and reload with new settings
    _poisCachedTime = null;
    _loadPOIs();
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
