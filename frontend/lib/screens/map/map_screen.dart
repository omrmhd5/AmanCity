import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/app_colors.dart';
import '../../data/incident_types_config.dart';
import '../../widgets/map/filters/map_filter_section.dart';
import '../../widgets/map/filters/filter_options_sheet.dart';
import '../../widgets/map/navigation/poi_detail_sheet.dart';
import '../../widgets/map/hotspots/hotspot_detail_sheet.dart';
import '../../widgets/map/map_loading_indicator.dart';
import '../../widgets/map/alerts/nearby_alerts_sheet.dart';
import '../../widgets/map/navigation/route_info_card.dart';
import '../../widgets/map/navigation/search_results_dropdown.dart';
import '../../models/incidents/map_incident.dart';
import '../../models/map/emergency_poi.dart';
import '../../models/map/danger_zone.dart';
import '../../models/map/hotspot_zone.dart';
import '../../services/map/geocoding_api_service.dart';
import '../../services/incidents/incident_api_service.dart';
import '../../services/map/places_api_service.dart';
import '../../services/map/directions_service.dart';
import '../../services/map/hotspot_api_service.dart';
import '../../services/map/location_service.dart';
import '../../services/map/location_stream_service.dart';
import '../../services/map/marker_icon_service.dart';
import '../../utils/safe_route_scorer.dart';
import '../../utils/app_theme.dart';
import '../../models/incidents/bulk_incident.dart';
import '../../services/incidents/bulk_incident_api_service.dart';
import '../../widgets/map/map_action_buttons.dart';
import '../incidents/incident_detail_sheet.dart';
import '../incidents/bulk_incident_detail_sheet.dart';
import '../../utils/localization_formatter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key, this.onReportPressed}) : super(key: key);

  final VoidCallback? onReportPressed;

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  String? selectedFilter;

  // Map layer (isolated from UI state rebuilds)
  final _mapLayerCtrl = _MapLayerController();
  Widget? _mapLayerWidget;

  // Map data
  List<MapIncident> _incidents = [];
  List<EmergencyPOI> _pois = [];
  List<DangerZone> _dangerZones = [];
  List<HotspotZone> _hotspots = [];
  List<BulkIncident> _bulkIncidents = [];
  bool _isLoadingBulkIncidents = false;

  // Hotspot settings
  bool _showHotspots = true;

  // POI filtering
  // 'all', 'hospital', 'police', 'fire', or pipe-separated like 'hospital|police'
  Set<String> _selectedPoiFilters = {}; // Track which filters are selected
  bool _showPOIs = true;
  DateTime? _poisCachedTime;
  LatLng?
  _lastPoiReloadLocation; // Track last POI reload location for distance check
  static const double _poiReloadDistanceKm = 7.0; // Reload POI if moved > 7km
  // POI cache is unlimited - only invalidated by: distance (7km), radius change, or background refresh
  static const String _poiCacheKey = 'cached_pois';
  static const String _poiCacheTimeKey = 'cached_pois_time';

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

  // Custom marker icon service (canvas rendering + caching)
  late final MarkerIconService _markerIcons;

  // Location cache
  DateTime? _locationCachedTime;
  static const int _locationCacheDurationMinutes =
      60; // Cache location for 60 minutes

  // Real-time location tracking
  StreamSubscription<Position>? _locationStreamSubscription;
  static const int _locationDistanceFilterMeters =
      10; // Only update if moved 10m+

  // Route/Navigation state
  LatLng? _routeDestination;
  String? _routeDestinationName;
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  Color? _routeColor;
  double? _routeDangerScore;
  String? _routeIncidentType;
  String? _routeLocationText;
  bool _isNavigatingToIncident = false;
  // Fastest alternative
  bool _hasFastestAlternative = false;
  String? _fastestDistance;
  String? _fastestDuration;
  double? _fastestDangerScore;
  // Points for both routes (for live polyline swap on card tap)
  List<LatLng>? _safestRoutePoints;
  List<LatLng>? _fastestRoutePoints;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;

  // Tapped destination (long-press anywhere on map)
  LatLng? _tappedDestination;

  // ─── In-flight guards (prevent concurrent duplicate requests) ──────────────
  bool _isLoadingIncidents = false;
  bool _isLoadingPOIs = false;
  bool _isLoadingHotspots = false;

  // ─── Auto-refresh polling timers ───────────────────────────────────────────
  Timer? _incidentPollTimer;
  Timer? _hotspotPollTimer;
  static const Duration _incidentPollInterval = Duration(seconds: 30);
  static const Duration _hotspotPollInterval = Duration(seconds: 60);

  // ─── Map theme preference listener ─────────────────────────────────────────
  // (driven by AppTheme.themeNotifier — no polling timer needed)

  // ─── Debounce: collapse rapid _updateMapElements calls into one frame ──────
  bool _mapUpdateScheduled = false;

  /// Called after a new incident is reported — immediately fetches fresh incidents and hotspots.
  void refreshAfterReport() {
    _loadIncidents();
    _loadHotspots();
    _loadBulkIncidents();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _markerIcons = MarkerIconService(onIconReady: _scheduleMapUpdate);
    // Initialize with all POI types selected by default
    _selectedPoiFilters = {'hospital', 'police', 'fire'};
    _updatePoiFilter();

    // Initialize with all incident types selected by default
    _selectedIncidentTypes = IncidentTypesConfig.allTypes
        .map((t) => t.key)
        .toSet();

    _loadIncidents();
    _loadBulkIncidents();
    unawaited(
      _loadPersistedPOIs(),
    ); // Load POIs from cache (must load before location)
    _loadUserLocationFromCache(); // Try to load cached location first (required before building map)
    _startRealTimeLocationTracking(); // Start listening for location updates
    _loadPersistedHotspots(); // Show last-known hotspots instantly
    _loadHotspots(); // Fetch fresh hotspots in background
    _startPolling(); // Auto-refresh every 30s (incidents) / 60s (hotspots)
    AppTheme.themeNotifier.addListener(
      _setMapStyle,
    ); // Rebuild map style on theme change
  }

  /// Listen for map theme preference changes and rebuild map when changed
  // (removed — now handled via AppTheme.themeNotifier)

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh incidents when app comes back to foreground
      _loadIncidents();
      _loadBulkIncidents();
      // Only fetch new location if cache is old
      _refreshLocationIfNeeded();
      // Reload hotspots only if cache has expired (don't invalidate manually)
      _loadHotspots();
      // Don't reload POIs - let cache handle it
    }
  }

  void _startPolling() {
    _incidentPollTimer?.cancel();
    _hotspotPollTimer?.cancel();
    _incidentPollTimer = Timer.periodic(_incidentPollInterval, (_) {
      _loadIncidents();
      _loadBulkIncidents();
    });
    _hotspotPollTimer = Timer.periodic(
      _hotspotPollInterval,
      (_) => _loadHotspots(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    _mapLayerCtrl.dispose();
    _locationStreamSubscription?.cancel();
    _incidentPollTimer?.cancel();
    _hotspotPollTimer?.cancel();
    AppTheme.themeNotifier.removeListener(_setMapStyle);
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    // Skip if already in-flight
    if (_isLoadingIncidents) return;

    _isLoadingIncidents = true;
    try {
      final incidents = await IncidentApiService.getIncidents();
      if (!mounted) return;
      setState(() => _incidents = incidents);
      _scheduleMapUpdate();
    } catch (e) {
      // Error loading incidents
    } finally {
      _isLoadingIncidents = false;
    }
  }

  Future<void> _loadBulkIncidents() async {
    if (_isLoadingBulkIncidents) return;
    _isLoadingBulkIncidents = true;
    try {
      final bulks = await BulkIncidentApiService.getBulkIncidents();
      if (!mounted) return;
      setState(() => _bulkIncidents = bulks);
      _scheduleMapUpdate();
    } catch (_) {
      // Bulk incidents are optional
    } finally {
      _isLoadingBulkIncidents = false;
    }
  }

  /// Start real-time location tracking stream
  void _startRealTimeLocationTracking() {
    // Cancel any existing subscription
    _locationStreamSubscription?.cancel();

    try {
      _locationStreamSubscription = LocationStreamService.startLocationTracking(
        onLocationUpdate: (newLocation) {
          setState(() {
            _userLocation = newLocation;
            _locationCachedTime = DateTime.now();
          });
          _cacheLocation(
            Position(
              latitude: newLocation.latitude,
              longitude: newLocation.longitude,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              headingAccuracy: 0,
              altitudeAccuracy: 0,
            ),
          );

          // Only reload POIs if user moved > 7km from last POI reload location
          if (_lastPoiReloadLocation != null) {
            final distance = _calculateDistance(
              _lastPoiReloadLocation!,
              newLocation,
            );
            if (distance >= _poiReloadDistanceKm) {
              _poisCachedTime = null;
              _lastPoiReloadLocation = newLocation;
              _loadPOIs();
            }
          } else {
            // First time, set the location for next comparison
            _lastPoiReloadLocation = newLocation;
          }

          _scheduleMapUpdate();
        },
        distanceFilterMeters: _locationDistanceFilterMeters,
      );
    } catch (e) {
      // Location permissions or service disabled - not critical
    }
  }

  /// Calculate distance between two LatLng points in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371; // km
    final dLat = (point2.latitude - point1.latitude) * (3.14159 / 180);
    final dLng = (point2.longitude - point1.longitude) * (3.14159 / 180);
    final a =
        (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        Math.cos(point1.latitude * (3.14159 / 180)) *
            Math.cos(point2.latitude * (3.14159 / 180)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2);
    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Cache location to SharedPreferences
  Future<void> _cacheLocation(Position position) async {
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
          _mapLayerWidget ??= _MapLayerWidget(
            controller: _mapLayerCtrl,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (ctrl) {
              _mapController = ctrl;
              _setMapStyle();
            },
            onLongPress: _onMapLongPressed,
          );

          // Animate camera to cached location
          await Future.delayed(const Duration(milliseconds: 500));
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_userLocation!, 15.0),
          );

          _lastPoiReloadLocation = LatLng(
            cachedLat,
            cachedLng,
          ); // Set reference for 7km check
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
      _mapLayerWidget ??= _MapLayerWidget(
        controller: _mapLayerCtrl,
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (ctrl) {
          _mapController = ctrl;
          _setMapStyle();
        },
        onLongPress: _onMapLongPressed,
      );

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
      _lastPoiReloadLocation = newLocation; // Set reference for 7km check
      await _loadPOIs();

      _updateMapElements();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      // Error getting location
    }
  }

  Future<void> _loadPOIs() async {
    // Skip if already in-flight
    if (_isLoadingPOIs) return;

    // Skip if we already have cached POIs (unlimited cache)
    if (_poisCachedTime != null) return;

    // Don't load if no location
    if (_userLocation == null) return;

    // No filters → clear and skip fetch
    if (_selectedPoiFilters.isEmpty) {
      setState(() => _pois = []);
      _scheduleMapUpdate();
      return;
    }

    _isLoadingPOIs = true;
    final locationSnapshot = _userLocation!;
    try {
      final pois = await PlacesApiService.getNearbyPlaces(
        locationSnapshot,
        type: 'all',
        radiusKm: _radiusKm,
      );
      if (!mounted) return;
      setState(() {
        _pois = pois;
        // Only mark as cached if API actually returned POIs
        if (pois.isNotEmpty) {
          _poisCachedTime = DateTime.now();
        }
      });
      _persistPOIs(pois); // Save to SharedPreferences (fire-and-forget)
      _scheduleMapUpdate();
    } catch (e) {
      // Error loading POIs
    } finally {
      _isLoadingPOIs = false;
    }
  }

  Future<void> _loadHotspots() async {
    // Skip if already in-flight
    if (_isLoadingHotspots) return;
    if (!_showHotspots) return;

    _isLoadingHotspots = true;
    try {
      final hotspots = await HotspotApiService.getHotspots();
      if (!mounted) return;
      setState(() => _hotspots = hotspots);
      _scheduleMapUpdate();
      _persistHotspots(hotspots); // Fire-and-forget persistence
    } catch (e) {
      // Hotspots are optional — silently ignore errors
    } finally {
      _isLoadingHotspots = false;
    }
  }

  // ─── Hotspot SharedPreferences persistence ──────────────────────────────────

  static const String _hotspotsPrefsKey = 'cached_hotspots';
  static const String _hotspotsPrefsTimeKey = 'cached_hotspots_time';

  Future<void> _persistHotspots(List<HotspotZone> hotspots) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(hotspots.map((h) => h.toJson()).toList());
      await prefs.setString(_hotspotsPrefsKey, json);
      await prefs.setString(
        _hotspotsPrefsTimeKey,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  /// Load persisted hotspots on cold start — shown instantly while fetch runs.
  Future<void> _loadPersistedHotspots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_hotspotsPrefsKey);
      final timeStr = prefs.getString(_hotspotsPrefsTimeKey);
      if (json == null || timeStr == null) return;

      // Only use persisted data if it's less than 24 hours old
      final age = DateTime.now().difference(DateTime.parse(timeStr));
      if (age.inHours >= 24) return;

      final list = (jsonDecode(json) as List)
          .map((e) => HotspotZone.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _hotspots = list;
        // Don't set _hotspotsCachedTime here — still fetch fresh data in background
      });
      _scheduleMapUpdate();
    } catch (_) {}
  }

  /// Load persisted POIs from SharedPreferences (survives hot reload)
  Future<void> _loadPersistedPOIs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_poiCacheKey);
      final timeStr = prefs.getString(_poiCacheTimeKey);
      if (json == null || timeStr == null) return;

      final list = (jsonDecode(json) as List)
          .map((e) => EmergencyPOI.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _pois = list;
        // Only mark as cached if we actually loaded POIs (not empty)
        if (list.isNotEmpty) {
          _poisCachedTime = DateTime.parse(timeStr); // Mark as cached
        }
      });
      _scheduleMapUpdate();
    } catch (_) {}
  }

  /// Save POIs to SharedPreferences (survives hot reload/app restart)
  Future<void> _persistPOIs(List<EmergencyPOI> pois) async {
    if (pois.isEmpty) return; // Don't persist empty results
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(pois.map((p) => p.toJson()).toList());
      await prefs.setString(_poiCacheKey, json);
      await prefs.setString(_poiCacheTimeKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  /// Schedules a map element rebuild, collapsing rapid successive calls into
  /// a single microtask so multiple loader completions produce one rebuild.
  void _scheduleMapUpdate() {
    if (_mapUpdateScheduled) return;
    _mapUpdateScheduled = true;
    Future.microtask(() {
      _mapUpdateScheduled = false;
      if (mounted) _updateMapElements();
    });
  }

  void _updateMapElements() {
    final newMarkers = <Marker>{};
    final newCircles = <Circle>{};

    // Filter incidents by selected types (if filters are applied)
    // Only show individual incidents that are NOT merged into a BulkIncident
    List<MapIncident> visibleIncidents = _incidents.where((incident) {
      if (incident.isMerged) return false;
      if (_selectedIncidentTypes.isEmpty) {
        return true; // Show all if no filters selected
      }
      return _selectedIncidentTypes.contains(incident.type);
    }).toList();

    // Add individual incident markers
    for (var incident in visibleIncidents) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(incident.id),
          position: incident.position,
          icon: _markerIcons.getIncidentMarker(incident),
          consumeTapEvents: true,
          onTap: () => _onIncidentTapped(incident),
        ),
      );
    }

    // Add bulk incident markers (aggregated groups)
    for (final bulk in _bulkIncidents) {
      if (_selectedIncidentTypes.isNotEmpty &&
          !_selectedIncidentTypes.contains(bulk.type))
        continue;
      newMarkers.add(
        Marker(
          markerId: MarkerId('bulk_${bulk.id}'),
          position: bulk.center,
          icon: _markerIcons.getBulkMarker(bulk),
          consumeTapEvents: true,
          onTap: () => _onBulkIncidentTapped(bulk),
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
        newMarkers.add(
          Marker(
            markerId: MarkerId('poi_${poi.id}'),
            position: poi.position,
            icon: _markerIcons.getPOIMarker(poi),
            consumeTapEvents: true,
            onTap: () => _onPOITapped(poi),
          ),
        );
      }
    }

    // Add user location marker if available
    if (_userLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: _markerIcons.getUserLocationMarker(),
        ),
      );
    }

    // Add tapped destination marker
    if (_tappedDestination != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('tapped_destination'),
          position: _tappedDestination!,
          icon: _markerIcons.getTappedDestinationMarker(),
          consumeTapEvents: true,
          onTap: _clearRoute,
        ),
      );
    }

    // Add danger zones as circles
    for (var zone in _dangerZones) {
      newCircles.add(
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
        newCircles.add(
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
        newMarkers.add(
          Marker(
            markerId: MarkerId('hotspot_marker_${hotspot.id}'),
            position: hotspot.center,
            icon: _markerIcons.getHotspotMarker(hotspot),
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

    _mapLayerCtrl.update(newMarkers, newCircles);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'map.search_failed'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
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
      final routeData = await DirectionsService.getSafeRoute(
        _userLocation!,
        destination,
        _hotspots,
        incidents: _incidents.where((i) => !i.isMerged).toList(),
        bulkIncidents: _bulkIncidents,
      );

      final points = routeData['points'] as List<LatLng>;
      final dangerScore = routeData['dangerScore'] as double;
      final fastestPoints = routeData['fastestPoints'] as List<LatLng>?;

      setState(() {
        _routeDistance = routeData['distance'];
        _routeDuration = routeData['duration'];
        _routeDangerScore = dangerScore;
        _hasFastestAlternative =
            routeData['hasFastestAlternative'] as bool? ?? false;
        _fastestDistance = routeData['fastestDistance'] as String?;
        _fastestDuration = routeData['fastestDuration'] as String?;
        _fastestDangerScore = routeData['fastestDangerScore'] as double?;
        _safestRoutePoints = points;
        _fastestRoutePoints = fastestPoints;
        _isLoadingRoute = false;
      });
      _updateRoutePolylines(safestSelected: true);

      // Animate camera to show full route
      _animateCameraToRoute(points);

      _updateMapElements();
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'map.cant_calculate_route'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
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
      final routeData = await DirectionsService.getSafeRoute(
        _userLocation!,
        poi.position,
        _hotspots,
        incidents: _incidents.where((i) => !i.isMerged).toList(),
        bulkIncidents: _bulkIncidents,
      );

      final points = routeData['points'] as List<LatLng>;
      final dangerScore = routeData['dangerScore'] as double;
      final fastestPoints = routeData['fastestPoints'] as List<LatLng>?;

      setState(() {
        _routeDistance = routeData['distance'];
        _routeDuration = routeData['duration'];
        _routeDangerScore = dangerScore;
        _hasFastestAlternative =
            routeData['hasFastestAlternative'] as bool? ?? false;
        _fastestDistance = routeData['fastestDistance'] as String?;
        _fastestDuration = routeData['fastestDuration'] as String?;
        _fastestDangerScore = routeData['fastestDangerScore'] as double?;
        _safestRoutePoints = points;
        _fastestRoutePoints = fastestPoints;
        _isLoadingRoute = false;
      });
      _updateRoutePolylines(safestSelected: true);

      // Animate camera to show full route
      _animateCameraToRoute(points);

      _updateMapElements();
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'map.cant_calculate_route'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
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
      final routeData = await DirectionsService.getSafeRoute(
        _userLocation!,
        incident.position,
        _hotspots,
        incidents: _incidents.where((i) => !i.isMerged).toList(),
        bulkIncidents: _bulkIncidents,
      );

      final points = routeData['points'] as List<LatLng>;
      final dangerScore = routeData['dangerScore'] as double;
      final fastestPoints = routeData['fastestPoints'] as List<LatLng>?;

      setState(() {
        _routeDistance = routeData['distance'];
        _routeDuration = routeData['duration'];
        _routeDangerScore = dangerScore;
        _hasFastestAlternative =
            routeData['hasFastestAlternative'] as bool? ?? false;
        _fastestDistance = routeData['fastestDistance'] as String?;
        _fastestDuration = routeData['fastestDuration'] as String?;
        _fastestDangerScore = routeData['fastestDangerScore'] as double?;
        _safestRoutePoints = points;
        _fastestRoutePoints = fastestPoints;
        _isLoadingRoute = false;
      });
      _updateRoutePolylines(safestSelected: true);

      // Animate camera to show full route
      _animateCameraToRoute(points);

      _updateMapElements();
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'map.cant_calculate_route'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
      }
    }
  }

  // ─── Long-press anywhere on map ────────────────────────────────────────────

  void _onMapLongPressed(LatLng latLng) {
    setState(() => _tappedDestination = latLng);
    _updateMapElements();
    _drawRouteToTappedLocation(latLng);
  }

  Future<void> _drawRouteToTappedLocation(LatLng destination) async {
    if (_userLocation == null) return;

    setState(() {
      _isLoadingRoute = true;
      _routeDestination = destination;
      _routeDestinationName = 'Selected Location';
      _routeIncidentType = 'Destination';
      _routeLocationText =
          '${destination.latitude.toStringAsFixed(5)}, ${destination.longitude.toStringAsFixed(5)}';
      _routeColor = AppColors.secondary;
      _isNavigatingToIncident = false;
      _showSearchResults = false;
    });

    // Reverse geocode in parallel with route calculation
    GeocodingService.reverseGeocode(
      destination.latitude,
      destination.longitude,
    ).then((geo) {
      final address = geo['text'];
      if (address != null && address.isNotEmpty && mounted) {
        setState(() => _routeLocationText = address);
      }
    });

    try {
      final routeData = await DirectionsService.getSafeRoute(
        _userLocation!,
        destination,
        _hotspots,
        incidents: _incidents.where((i) => !i.isMerged).toList(),
        bulkIncidents: _bulkIncidents,
      );

      final points = routeData['points'] as List<LatLng>;
      final dangerScore = routeData['dangerScore'] as double;
      final fastestPoints = routeData['fastestPoints'] as List<LatLng>?;

      setState(() {
        _routeDistance = routeData['distance'];
        _routeDuration = routeData['duration'];
        _routeDangerScore = dangerScore;
        _hasFastestAlternative =
            routeData['hasFastestAlternative'] as bool? ?? false;
        _fastestDistance = routeData['fastestDistance'] as String?;
        _fastestDuration = routeData['fastestDuration'] as String?;
        _fastestDangerScore = routeData['fastestDangerScore'] as double?;
        _safestRoutePoints = points;
        _fastestRoutePoints = fastestPoints;
        _isLoadingRoute = false;
      });
      _updateRoutePolylines(safestSelected: true);
      _animateCameraToRoute(points);
      _updateMapElements();
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
        _tappedDestination = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'map.cant_calculate_route'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
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

  /// Rebuild polylines based on which route is selected
  void _updateRoutePolylines({required bool safestSelected}) {
    final safestColor =
        SafeRouteScorer.getDangerLevelInfo(_routeDangerScore ?? 0)['color']
            as Color;
    final fastestColor = _fastestDangerScore != null
        ? (SafeRouteScorer.getDangerLevelInfo(_fastestDangerScore!)['color']
              as Color)
        : const Color(0xFF3B82F6);

    final polylines = <Polyline>{};

    if (_safestRoutePoints != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('safest'),
          color: safestSelected ? safestColor : safestColor.withOpacity(0.3),
          width: safestSelected ? 6 : 4,
          points: _safestRoutePoints!,
        ),
      );
    }

    if (_fastestRoutePoints != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('fastest'),
          color: safestSelected ? fastestColor.withOpacity(0.3) : fastestColor,
          width: safestSelected ? 4 : 6,
          points: _fastestRoutePoints!,
        ),
      );
    }

    _mapLayerCtrl.updatePolylines(polylines);
  }

  /// Called when user taps a route card
  void _onRouteSelectionChanged(bool safestSelected) {
    _updateRoutePolylines(safestSelected: safestSelected);
  }

  /// Clear the current route
  void _clearRoute() {
    _mapLayerCtrl.updatePolylines({});
    setState(() {
      _routeDestination = null;
      _routeDestinationName = null;
      _routeDistance = null;
      _routeDuration = null;
      _routeColor = null;
      _routeIncidentType = null;
      _routeLocationText = null;
      _isNavigatingToIncident = false;
      _routeDangerScore = null;
      _hasFastestAlternative = false;
      _fastestDistance = null;
      _fastestDuration = null;
      _fastestDangerScore = null;
      _safestRoutePoints = null;
      _fastestRoutePoints = null;
      _searchResults = [];
      _showSearchResults = false;
      _tappedDestination = null;
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('map.cant_open_maps'.tr())));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'common.error'.tr()}: $e')));
      }
    }
  }

  /// Open the safe route in Google Maps with sampled waypoints
  Future<void> _openSafeRouteInGoogleMaps() async {
    if (_routeDestination == null || _mapLayerCtrl.polylines.isEmpty) return;

    // Get the polyline points
    final polyline = _mapLayerCtrl.polylines.first;
    final points = polyline.points;

    if (points.isEmpty) return;

    // Sample waypoints from the polyline (every Nth point, max 8 intermediate waypoints)
    final waypointCount = 8;
    final sampleRate = (points.length / (waypointCount + 1)).ceil();
    final waypoints = <String>[];

    for (int i = sampleRate; i < points.length - 1; i += sampleRate) {
      if (waypoints.length < waypointCount) {
        waypoints.add('${points[i].latitude},${points[i].longitude}');
      }
    }

    // Build Google Maps URL with origin, waypoints, and destination
    String url =
        'https://www.google.com/maps/dir/?api=1&origin=${_userLocation!.latitude},${_userLocation!.longitude}&destination=${_routeDestination!.latitude},${_routeDestination!.longitude}&travelmode=driving';

    if (waypoints.isNotEmpty) {
      url += '&waypoints=${waypoints.join('|')}';
    }

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('map.cant_open_maps'.tr())));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'common.error'.tr()}: $e')));
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
        timeAgo: LocalizationFormatter.formatTimeAgo(context, incident.timestamp),
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

  void _onBulkIncidentTapped(BulkIncident bulk) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BulkIncidentDetailSheet(
        bulk: bulk,
        onNavigate: (selectedBulk) async {
          await _drawRouteToIncident(
            MapIncident(
              id: selectedBulk.id,
              type: selectedBulk.type,
              position: selectedBulk.center,
              title: selectedBulk.type,
              description: '',
              timestamp: selectedBulk.firstReportedAt,
              addressText: selectedBulk.locationText,
              city: selectedBulk.city,
              isMerged: false,
            ),
          );
        },
      ),
    );
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
            'timeAgo': LocalizationFormatter.formatTimeAgo(context, incident.timestamp),
            'distance': 'map.away_suffix'.tr(namedArgs: {
              'distance': LocalizationFormatter.formatDistance(
                context,
                LocationService.formatDistance(distanceKm),
              ),
            }),
            'color': incident.typeColor,
            'icon': incident.typeIcon,
            'confidence': incident.confidence,
            'location': {'text': incident.addressText},
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
        if (_locationLoaded && _mapLayerWidget != null)
          _mapLayerWidget!
        else
          Container(
            color: AppColors.primary,
            child: const MapLoadingIndicator(),
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

        MapActionButtons(
          onReportPressed: widget.onReportPressed,
          onMyLocationPressed: () {
            if (_userLocation != null) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_userLocation!, 15.0),
              );
            } else {
              _getUserLocation();
            }
          },
        ),

        // Route info card (if route selected)
        if (_routeDestination != null)
          Positioned(
            bottom: 20 - MediaQuery.of(context).viewInsets.bottom,
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
              dangerScore: _routeDangerScore,
              hasFastestAlternative: _hasFastestAlternative,
              fastestDistance: _fastestDistance,
              fastestDuration: _fastestDuration,
              fastestDangerScore: _fastestDangerScore,
              onRouteSelectionChanged: _onRouteSelectionChanged,
              onNavigate: _openInGoogleMaps,
              onNavigateSafeRoute: _openSafeRouteInGoogleMaps,
              onClose: _clearRoute,
            ),
          ),

        // Nearby alerts section at bottom
        Positioned(
          bottom: -MediaQuery.of(context).viewInsets.bottom,
          left: 0,
          right: 0,
          child: _buildNearbyAlertsSection(),
        ),

      ],
    );
  }

  Future<void> _setMapStyle() async {
    if (_mapController == null) return;
    if (AppTheme.currentMode == AppThemeMode.dark) {
      await _mapController?.setMapStyle(AppColors.darkMapStyle);
    } else {
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
      bulkIncidents: _bulkIncidents,
      userLocation: _userLocation,
      onScrollControllerReady: (controller) {
        // Scroll controller callback
      },
      onIncidentTapped: (incident) async {
        await _drawRouteToIncident(incident);
      },
    );
  }
}

// ─── Map Layer: Controller + Widget ─────────────────────────────────────────
// These classes isolate the GoogleMap widget from MapScreen's UI state.
// Only map data changes (markers, circles, polylines) cause GoogleMap to rebuild.
// UI-only setState calls (search, loading, route card) are completely ignored.

/// Holds the data the GoogleMap widget needs.
/// Call [update] or [updatePolylines] to push new data — only [_MapLayerWidget]
/// will rebuild, not the full MapScreen.
class _MapLayerController extends ChangeNotifier {
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  Set<Polyline> polylines = {};

  void update(Set<Marker> m, Set<Circle> c, [Set<Polyline>? p]) {
    markers = m;
    circles = c;
    if (p != null) polylines = p;
    notifyListeners();
  }

  void updatePolylines(Set<Polyline> p) {
    polylines = p;
    notifyListeners();
  }
}

/// Isolated GoogleMap widget — only rebuilds when [_MapLayerController] fires.
///
/// MapScreen stores a single instance in [MapScreenState._mapLayerWidget].
/// Returning the same Widget object reference from build() makes Flutter's
/// reconciler skip element.update() entirely → GoogleMap never rebuilds from
/// parent setState().
class _MapLayerWidget extends StatefulWidget {
  const _MapLayerWidget({
    required this.controller,
    required this.initialCameraPosition,
    required this.onMapCreated,
    required this.onLongPress,
  });

  final _MapLayerController controller;
  final CameraPosition initialCameraPosition;
  final void Function(GoogleMapController) onMapCreated;
  final void Function(LatLng) onLongPress;

  @override
  State<_MapLayerWidget> createState() => _MapLayerWidgetState();
}

class _MapLayerWidgetState extends State<_MapLayerWidget> {
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onDataChanged);
  }

  @override
  void didUpdateWidget(_MapLayerWidget old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onDataChanged);
      widget.controller.addListener(_onDataChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    if (mounted) {
      setState(() => _mapReady = true);
    }
    widget.onMapCreated(controller);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: widget.initialCameraPosition,
          onMapCreated: _onMapCreated,
          markers: widget.controller.markers,
          circles: widget.controller.circles,
          polylines: widget.controller.polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          trafficEnabled: false,
          buildingsEnabled: true,
          onLongPress: widget.onLongPress,
        ),
        if (!_mapReady)
          Container(
            color: AppTheme.getBackgroundColor().withOpacity(0.8),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.secondary),
              ),
            ),
          ),
      ],
    );
  }
}
