import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../utils/incident_types_config.dart';
import '../widgets/map/map_filter_section.dart';
import '../widgets/map/filter_options_sheet.dart';
import '../widgets/map/poi_detail_sheet.dart';
import '../widgets/map/hotspot_detail_sheet.dart';
import '../widgets/map/map_loading_indicator.dart';
import '../widgets/map/nearby_alerts_sheet.dart';
import '../widgets/map/route_info_card.dart';
import '../widgets/map/search_results_dropdown.dart';
import '../models/map_incident.dart';
import '../models/emergency_poi.dart';
import '../models/danger_zone.dart';
import '../models/hotspot_zone.dart';
import '../services/backend_api/incident_api_service.dart';
import '../services/backend_api/places_api_service.dart';
import '../services/backend_api/directions_service.dart';
import '../services/hotspot_api_service.dart';
import '../services/location_service.dart';
import 'incident_detail_sheet.dart';

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
  List<HotspotZone> _hotspots = [];

  // Hotspot settings
  bool _showHotspots = true;
  DateTime? _hotspotsCachedTime;
  static const int _hotspotsCacheDurationMinutes = 10;

  // POI filtering
  // 'all', 'hospital', 'police', 'fire', or pipe-separated like 'hospital|police'
  Set<String> _selectedPoiFilters = {}; // Track which filters are selected
  bool _showPOIs = true;
  DateTime? _poisCachedTime;
  static const int _poiCacheDurationMinutes = 5;

  // Incident filtering
  Set<String> _selectedIncidentTypes = {}; // Track which incident types to show

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

  // Route/Navigation state
  Set<Polyline> _routePolylines = {};
  LatLng? _routeDestination;
  String? _routeDestinationName;
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  Color? _routeColor;
  String? _routeIncidentType;
  String? _routeLocationText;
  bool _isNavigatingToIncident = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize with all POI types selected by default
    _selectedPoiFilters = {'hospital', 'police', 'fire'};
    _updatePoiFilter();

    // Initialize with all incident types selected by default
    _selectedIncidentTypes = IncidentTypesConfig.allTypes
        .map((t) => t.key)
        .toSet();

    _loadIncidents();
    _loadUserLocationFromCache(); // Try to load cached location first (required before building map)
    _loadPOIs();
    _loadHotspots();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh incidents when app comes back to foreground
      _loadIncidents();
      // Only fetch new location if cache is old
      _refreshLocationIfNeeded();
      // Refresh hotspots if cache expired
      _hotspotsCachedTime = null;
      _loadHotspots();
      // Don't reload POIs - let cache handle it
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
      // Error loading incidents
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
      // Error loading cached location
    }

    // No valid cache, fetch fresh location
    await _getUserLocation();
  }

  /// Refresh location only if cache is old
  Future<void> _refreshLocationIfNeeded() async {
    if (_locationCachedTime != null) {
      final age = DateTime.now().difference(_locationCachedTime!);
      if (age.inMinutes < _locationCacheDurationMinutes) {
        return; // Cache still fresh
      }
    }

    // Cache is old or empty, fetch fresh location
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
      } catch (e) {
        // Failed to cache location
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
      // Error getting location
    }
  }

  Future<void> _loadPOIs() async {
    // Check cache validity
    if (_poisCachedTime != null) {
      final age = DateTime.now().difference(_poisCachedTime!);
      if (age.inMinutes < _poiCacheDurationMinutes) {
        return;
      }
    }

    // Don't load if no location
    if (_userLocation == null) {
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
      final pois = await PlacesApiService.getNearbyPlaces(
        initialLocation,
        type: 'all',
        radiusKm: _radiusKm,
      );

      setState(() {
        _pois = pois;
        _poisCachedTime = DateTime.now();
      });

      _updateMapElements();
    } catch (e) {
      // Error loading POIs
    }
  }

  Future<void> _loadHotspots() async {
    // Check cache validity
    if (_hotspotsCachedTime != null) {
      final age = DateTime.now().difference(_hotspotsCachedTime!);
      if (age.inMinutes < _hotspotsCacheDurationMinutes) {
        return;
      }
    }

    // Don't load if hotspots are disabled
    if (!_showHotspots) {
      return;
    }

    try {
      final hotspots = await HotspotApiService.getHotspots();

      setState(() {
        _hotspots = hotspots;
        _hotspotsCachedTime = DateTime.now();
      });

      _updateMapElements();
    } catch (e) {
      // Error loading hotspots
      // Hotspots are optional UI enhancement
    }
  }

  void _updateMapElements() {
    _markers.clear();
    _circles.clear();

    // Filter incidents by selected types (if filters are applied)
    List<MapIncident> visibleIncidents = _incidents.where((incident) {
      if (_selectedIncidentTypes.isEmpty) {
        return true; // Show all if no filters selected
      }
      return _selectedIncidentTypes.contains(incident.type);
    }).toList();

    // Add incident markers with custom icons
    for (var incident in visibleIncidents) {
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
      // Filter POIs by selected types
      final visiblePOIs = _pois.where((poi) {
        if (_selectedPoiFilters.isEmpty) {
          return false; // Hide all POIs if no filters selected
        }
        // Map POI type to filter type string
        String poiTypeStr;
        if (poi.type == POIType.hospital) {
          poiTypeStr = 'hospital';
        } else if (poi.type == POIType.policeStation) {
          poiTypeStr = 'police';
        } else if (poi.type == POIType.fireStation) {
          poiTypeStr = 'fire';
        } else {
          return false; // Skip other POI types
        }
        return _selectedPoiFilters.contains(poiTypeStr);
      }).toList();

      for (var poi in visiblePOIs) {
        _markers.add(
          Marker(
            markerId: MarkerId('poi_${poi.id}'),
            position: poi.position,
            icon: _getCustomPOIMarker(poi),
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
          icon: _getUserLocationMarker(),
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

    // Add hotspot zones as circles (if enabled)
    if (_showHotspots) {
      for (var hotspot in _hotspots) {
        // Add circle for hotspot
        _circles.add(
          Circle(
            circleId: CircleId('hotspot_${hotspot.id}'),
            center: hotspot.center,
            radius: hotspot.radiusMeters,
            fillColor: hotspot.fillColor,
            strokeColor: hotspot.strokeColor,
            strokeWidth: 2,
          ),
        );

        // Add marker at hotspot center for interactivity
        _markers.add(
          Marker(
            markerId: MarkerId('hotspot_marker_${hotspot.id}'),
            position: hotspot.center,
            icon: _getHotspotMarker(hotspot),
            consumeTapEvents: true,
            onTap: () => _onHotspotTapped(hotspot),
            infoWindow: InfoWindow(
              title: '${hotspot.riskLevel} Risk Zone',
              snippet: '${hotspot.incidentCount} incidents',
            ),
          ),
        );
      }
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

    // We'll create the icon asynchronously and store in cache (medium size for incidents)
    _createAndCacheMarkerIcon(
      cacheKey,
      iconData,
      iconColor,
      backgroundColor,
      markerSize: 110.0,
    );

    return BitmapDescriptor.defaultMarkerWithHue(
      _getHueFromColor(backgroundColor),
    );
  }

  /// Creates a custom map marker icon with POI type icon
  BitmapDescriptor _getCustomPOIMarker(EmergencyPOI poi) {
    // Check cache first
    final cacheKey = 'poi_${poi.type}_${poi.markerColor.value}';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    // Create new icon (will be cached after rendering)
    final iconData = poi.icon;
    final iconColor = Colors.white;
    final backgroundColor = poi.markerColor;

    // We'll create the icon asynchronously and store in cache (smaller size for POI)
    _createAndCacheMarkerIcon(
      cacheKey,
      iconData,
      iconColor,
      backgroundColor,
      markerSize: 80.0,
    );

    return BitmapDescriptor.defaultMarkerWithHue(
      _getHueFromColor(backgroundColor),
    );
  }

  /// Renders an icon to a bitmap and caches it
  Future<void> _createAndCacheMarkerIcon(
    String cacheKey,
    IconData iconData,
    Color iconColor,
    Color backgroundColor, {
    double markerSize = 120.0,
  }) async {
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final size = markerSize;

      // Draw circular background with shadow
      final paint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;

      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      // Draw shadow
      canvas.drawCircle(Offset(size / 2, size / 2 + 2), size / 2, shadowPaint);

      // Draw background circle
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

      // Draw icon
      final textPainter = TextPainter(textDirection: TextDirection.ltr);

      textPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          color: iconColor,
          fontSize: markerSize * 0.45,
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
      // Error creating marker icon
    }
  }

  /// Creates a custom marker for user's current location
  BitmapDescriptor _getUserLocationMarker() {
    const cacheKey = 'user_location';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    // Create user location marker with my_location icon in cyan/teal
    const userColor = Color(0xFF06B6D4); // Cyan
    const iconData = Icons.my_location;
    const iconColor = Colors.white;

    _createAndCacheMarkerIcon(cacheKey, iconData, iconColor, userColor);

    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
  }

  /// Creates a hotspot marker icon (warning/alert style)
  BitmapDescriptor _getHotspotMarker(HotspotZone hotspot) {
    final cacheKey = 'hotspot_${hotspot.riskScore.toStringAsFixed(2)}';
    if (_markerIconCache.containsKey(cacheKey)) {
      return _markerIconCache[cacheKey]!;
    }

    // Use warning icon for hotspots
    const iconData = Icons.warning_amber;
    const iconColor = Colors.white;
    final backgroundColor = hotspot.riskColor;

    _createAndCacheMarkerIcon(
      cacheKey,
      iconData,
      iconColor,
      backgroundColor,
      markerSize: 90.0,
    );

    return BitmapDescriptor.defaultMarkerWithHue(
      _getHueFromColor(backgroundColor),
    );
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

  /// Search for nearby places matching the search query
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || _userLocation == null) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      // Use the new general search endpoint to find any places (POIs, streets, etc.)
      final searchResults = await PlacesApiService.searchPlaces(
        query,
        _userLocation!,
        radiusKm: 10.0,
      );

      setState(() => _searchResults = searchResults);
    } catch (e) {
      setState(() => _searchResults = []);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    }
  }

  /// Draw route to place (either POI or generic place)
  Future<void> _drawRouteToPlace(Map<String, dynamic> place) async {
    if (_userLocation == null) return;

    final lat = place['lat'] as double?;
    final lng = place['lng'] as double?;
    final name = place['name'] as String? ?? 'Unknown';
    final address = place['address'] as String? ?? '';
    final type = place['type'] as String?;

    if (lat == null || lng == null) return;

    final destination = LatLng(lat, lng);

    // Determine route color based on place type
    Color routeColor;
    String typeLabel;

    switch (type) {
      case 'hospital':
        routeColor = const Color(0xFFEF4444); // Red
        typeLabel = 'Hospital';
        break;
      case 'police':
        routeColor = const Color(0xFF3B82F6); // Blue
        typeLabel = 'Police Station';
        break;
      case 'fire':
        routeColor = const Color(0xFFF59E0B); // Orange
        typeLabel = 'Fire Station';
        break;
      default:
        // Generic place - use secondary color
        routeColor = AppColors.secondary;
        typeLabel = 'Location';
    }

    setState(() {
      _isLoadingRoute = true;
      _routeDestination = destination;
      _routeDestinationName = name;
      _routeIncidentType = typeLabel;
      _routeLocationText = address;
      _routeColor = routeColor;
      _isNavigatingToIncident = false;
      _showSearchResults = false;
    });

    try {
      final routeData = await DirectionsService.getRoute(
        _userLocation!,
        destination,
      );

      final points = routeData['points'] as List<LatLng>;

      setState(() {
        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: routeColor,
            width: 6,
            points: points,
          ),
        };
        _routeDistance = routeData['distance'];
        _routeDuration = routeData['duration'];
        _isLoadingRoute = false;
      });

      // Animate camera to show full route
      _animateCameraToRoute(points);

      _updateMapElements();
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to calculate route: $e')),
        );
      }
    }
  }

  /// Draw route to selected destination
  Future<void> _drawRouteTo(EmergencyPOI poi) async {
    if (_userLocation == null) return;

    // Determine route color based on POI type
    Color routeColor = const Color(0xFFEF4444); // Default red (hospital color)
    if (poi.type == POIType.hospital) {
      routeColor = const Color(0xFFEF4444); // Hospital red
    } else if (poi.type == POIType.policeStation) {
      routeColor = const Color(0xFF3B82F6); // Police blue
    } else if (poi.type == POIType.fireStation) {
      routeColor = const Color(0xFFF59E0B); // Fire orange
    } else if (poi.type == POIType.safeCafe) {
      routeColor = const Color(0xFF10B981); // Safe café green
    } else if (poi.type == POIType.safeZone) {
      routeColor = const Color(0xFF00B3A4); // Safe zone teal
    }

    setState(() {
      _isLoadingRoute = true;
      _routeDestination = poi.position;
      _routeDestinationName = poi.name;
      _routeIncidentType = poi.typeLabel;
      _routeLocationText = poi.address;
      _routeColor = routeColor;
      _isNavigatingToIncident = false;
      _showSearchResults = false;
    });

    try {
      final routeData = await DirectionsService.getRoute(
        _userLocation!,
        poi.position,
      );

      final points = routeData['points'] as List<LatLng>;

      setState(() {
        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: routeColor,
            width: 6,
            points: points,
          ),
        };
        _routeDistance = routeData['distance'];
        _routeDuration = routeData['duration'];
        _isLoadingRoute = false;
      });

      // Animate camera to show full route
      _animateCameraToRoute(points);

      _updateMapElements();
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to calculate route: $e')),
        );
      }
    }
  }

  /// Draw route to incident location
  Future<void> _drawRouteToIncident(MapIncident incident) async {
    if (_userLocation == null) return;

    // Get incident type color from config
    final incidentTypeConfig = IncidentTypesConfig.getByKey(incident.type);
    final routeColor = incidentTypeConfig.color;

    setState(() {
      _isLoadingRoute = true;
      _routeDestination = incident.position;
      _routeDestinationName = incident.title;
      _routeIncidentType = incident.type;
      _routeLocationText = incident.addressText ?? incident.city;
      _routeColor = routeColor;
      _isNavigatingToIncident = true;
      _showSearchResults = false;
    });

    try {
      final routeData = await DirectionsService.getRoute(
        _userLocation!,
        incident.position,
      );

      final points = routeData['points'] as List<LatLng>;

      setState(() {
        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: routeColor,
            width: 6,
            points: points,
          ),
        };
        _routeDistance = routeData['distance'];
        _routeDuration = routeData['duration'];
        _isLoadingRoute = false;
      });

      // Animate camera to show full route
      _animateCameraToRoute(points);

      _updateMapElements();
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to calculate route: $e')),
        );
      }
    }
  }

  /// Animate camera to show full route
  void _animateCameraToRoute(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      minLat = minLat > point.latitude ? point.latitude : minLat;
      maxLat = maxLat < point.latitude ? point.latitude : maxLat;
      minLng = minLng > point.longitude ? point.longitude : minLng;
      maxLng = maxLng < point.longitude ? point.longitude : maxLng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  /// Clear the current route
  void _clearRoute() {
    setState(() {
      _routePolylines = {};
      _routeDestination = null;
      _routeDestinationName = null;
      _routeDistance = null;
      _routeDuration = null;
      _routeColor = null;
      _routeIncidentType = null;
      _routeLocationText = null;
      _isNavigatingToIncident = false;
      _searchResults = [];
      _showSearchResults = false;
    });
    _updateMapElements();
  }

  /// Open Google Maps for navigation
  Future<void> _openInGoogleMaps() async {
    if (_routeDestination == null) return;

    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${_routeDestination!.latitude},${_routeDestination!.longitude}&travelmode=driving';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open Google Maps')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onIncidentTapped(MapIncident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentDetailScreen(
        incident: incident,
        timeAgo: _getTimeAgo(incident.timestamp),
        onNavigate: (selectedIncident) async {
          await _drawRouteToIncident(selectedIncident);
        },
      ),
    );
  }

  void _onPOITapped(EmergencyPOI poi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => POIDetailSheet(
        poi: poi,
        onNavigate: (selectedPoi) async {
          await _drawRouteTo(selectedPoi);
        },
      ),
    );
  }

  void _onHotspotTapped(HotspotZone hotspot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HotspotDetailSheet(hotspot: hotspot),
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

    // Filter incidents by selected types
    final filteredIncidents = _incidents.where((incident) {
      if (_selectedIncidentTypes.isEmpty) {
        return true; // Show all if no filters selected
      }
      return _selectedIncidentTypes.contains(incident.type);
    }).toList();

    // Calculate distance for each incident and filter by 10km range
    final alertsWithDistance = filteredIncidents
        .map((incident) {
          final distanceKm = LocationService.calculateDistance(
            lat1: _userLocation!.latitude,
            lng1: _userLocation!.longitude,
            lat2: incident.position.latitude,
            lng2: incident.position.longitude,
          );
          return {
            'incident': incident,
            'distanceKm': distanceKm,
            'type': incident.type,
            'title': incident.title,
            'description': incident.description,
            'timeAgo': _getTimeAgo(incident.timestamp),
            'distance': LocationService.formatDistance(distanceKm) + ' away',
            'color': incident.typeColor,
            'icon': incident.typeIcon,
          };
        })
        .where(
          (alert) =>
              (alert['distanceKm'] as num?) != null &&
              (alert['distanceKm'] as num) <= 10.0,
        ) // Filter: 10km range
        .toList();

    // Sort by distance (closest first)
    alertsWithDistance.sort(
      (a, b) => (a['distanceKm'] as num).compareTo(b['distanceKm'] as num),
    );

    // Remove the distanceKm key before returning
    return alertsWithDistance.map((alert) {
      alert.remove('distanceKm');
      return alert;
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
            polylines: _routePolylines,
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

        // Search results dropdown (overlay)
        if (_showSearchResults && _searchResults.isNotEmpty)
          GestureDetector(
            onTap: () {
              setState(() => _showSearchResults = false);
            },
            child: Container(color: Colors.transparent),
          ),

        if (_showSearchResults && _searchResults.isNotEmpty)
          Positioned(
            top: 56,
            left: 16,
            right: 16,
            child: SearchResultsDropdown(
              results: _searchResults,
              onResultTap: (place) {
                _drawRouteToPlace(place);
              },
            ),
          ),

        // Filter section
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                MapFilterSection(
                  currentRadius: _radiusKm,
                  selectedIncidentTypes: _selectedIncidentTypes,
                  hideFilters: _showSearchResults,
                  onFilterChanged: (filter) {
                    setState(() => selectedFilter = filter);
                    _applyFilter(filter);
                  },
                  onSettingsChanged: _handleSettingsChanged,
                  onSearch: (query) {
                    if (query.isEmpty) {
                      setState(() => _searchResults = []);
                    } else {
                      _searchPlaces(query);
                      setState(() => _showSearchResults = true);
                    }
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
            child: const Icon(Icons.my_location, color: Colors.white, size: 24),
          ),
        ),

        // Route info card (if route selected)
        if (_routeDestination != null)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: RouteInfoCard(
              destinationName: _routeDestinationName,
              distance: _routeDistance,
              duration: _routeDuration,
              isLoading: _isLoadingRoute,
              routeColor: _routeColor,
              incidentType: _routeIncidentType,
              locationText: _routeLocationText,
              isIncident: _isNavigatingToIncident,
              onNavigate: _openInGoogleMaps,
              onClose: _clearRoute,
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

    // Get map style preference from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final mapStylePreference =
        prefs.getString('map_style_preference') ?? 'dark';

    // Apply style based on user preference
    if (mapStylePreference == 'dark') {
      await _mapController?.setMapStyle(AppColors.darkMapStyle);
    } else {
      // Light style uses empty string (default Google Maps light style)
      await _mapController?.setMapStyle(
        AppColors.lightMapStyle.isEmpty ? null : AppColors.lightMapStyle,
      );
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

      // Just update markers - no backend call unless radius changes
      _updateMapElements();
    }
  }

  /// Update the _poiFilter string based on selected filters
  void _updatePoiFilter() {
    if (_selectedPoiFilters.isEmpty) {
      // No type selected
    } else if (_selectedPoiFilters.length == 1) {
    } else {
      // Multiple filters selected - join with pipe
    }
  }

  /// Handle settings changes from filter sheet
  void _handleSettingsChanged(FilterSettings settings) {
    final radiusChanged = settings.radiusKm != _radiusKm;

    setState(() {
      _radiusKm = settings.radiusKm;
      _selectedIncidentTypes = settings.selectedIncidentTypes;
    });

    // Update map with filtered incidents
    _updateMapElements();

    // Only reload POIs if radius changed
    if (radiusChanged) {
      _poisCachedTime = null;
      _loadPOIs();
    }
  }

  Widget _buildNearbyAlertsSection() {
    // Hide nearby alerts when route is active
    if (_routeDestination != null) {
      return const SizedBox.shrink();
    }

    return NearbyAlertsSheet(
      alerts: nearbyAlerts,
      onScrollControllerReady: (controller) {
        // Scroll controller callback
      },
      onIncidentTapped: (incident) async {
        await _drawRouteToIncident(incident);
      },
    );
  }
}
