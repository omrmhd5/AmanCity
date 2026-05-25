import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as Math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
import '../../services/map/geocoding_api_service.dart';
import '../../services/map/places_api_service.dart';
import '../../services/map/location_stream_service.dart';
import '../map/navigation/search_results_dropdown.dart';

class LocationPickerMap extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;
  final Function(String?, String?)? onAddressUpdated;

  const LocationPickerMap({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
    this.onAddressUpdated,
  }) : super(key: key);

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _geoLocationText;
  String? _geoLocationCity;
  LatLng?
  _lastGeocodeLocation; // Track last geocoded location for distance check
  static const double _geocodeReloadDistanceM = 10.0; // 10 meters
  StreamSubscription<Position>? _locationStreamSubscription;
  bool _confirmPressed = false;

  // Search state
  final searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;

  static const LatLng _cairoCenter = LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? _cairoCenter;
    _updateMarker();
    // Update initial location preview immediately (fast)
    _updateLocationPreview();
    // Set loading to false so map shows immediately
    setState(() => _isLoading = false);
    // Load fresh user location in background (won't block UI)
    _getUserLocationInBackground();
    // Start following location in real-time
    _startFollowingLocation();
  }

  @override
  void dispose() {
    searchController.dispose();
    _locationStreamSubscription?.cancel();
    super.dispose();
  }

  /// Get user location in background without blocking UI
  Future<void> _getUserLocationInBackground() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      // Get position with timeout to prevent hanging
      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 5),
      );

      final userLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _selectedLocation = userLocation;
          _updateMarker();
        });

        // Update location preview for new position
        await _updateLocationPreview();

        // Animate to user location
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(userLocation, 15.0),
        );
      }
    } catch (e) {
      // Error getting location or timeout, silently fail - keep initial location
    }
  }

  /// Start following user location in real-time
  void _startFollowingLocation() {
    _locationStreamSubscription?.cancel();
    try {
      _locationStreamSubscription =
          LocationStreamService.startLocationTracking(
                onLocationUpdate: (newLocation) {
                  if (mounted) {
                    setState(() => _selectedLocation = newLocation);
                    _updateMarker();
                    _updateLocationPreview();
                    // Auto-animate camera to follow
                    _mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(newLocation, 15.0),
                    );
                  }
                },
                distanceFilterMeters: 10,
              )
              as StreamSubscription<Position>?;
    } catch (e) {
      // Location tracking failed, continue with one-time location
    }
  }

  void _updateMarker() {
    if (_selectedLocation != null) {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
            });
            _updateLocationPreview();
          },
        ),
      );
    }
  }

  /// Fetch geocoded address for current location (with distance-based caching)
  Future<void> _updateLocationPreview() async {
    if (_selectedLocation == null) return;

    // Skip if we already geocoded this location (within 10m)
    if (_geoLocationText != null &&
        _lastGeocodeLocation != null &&
        _calculateDistanceMeters(_lastGeocodeLocation!, _selectedLocation!) <
            _geocodeReloadDistanceM) {
      return; // Cache valid
    }

    final result = await GeocodingService.reverseGeocode(
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    );

    if (mounted) {
      setState(() {
        _geoLocationText = result['text'];
        _geoLocationCity = result['city'];
        _lastGeocodeLocation = _selectedLocation; // Update reference
      });
      // Notify parent about address update
      widget.onAddressUpdated?.call(_geoLocationText, _geoLocationCity);
    }
  }

  /// Calculate distance between two LatLng points in meters
  double _calculateDistanceMeters(LatLng point1, LatLng point2) {
    const earthRadius = 6371000; // meters
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

  void _onMapTapped(LatLng tappedPosition) {
    setState(() {
      _selectedLocation = tappedPosition;
      _updateMarker();
    });
    _updateLocationPreview();
  }

  /// Search for places (general places + POIs)
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || _selectedLocation == null) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final searchResults = await PlacesApiService.searchPlaces(
        query,
        _selectedLocation!,
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

  /// Handle search result selection
  Future<void> _selectSearchResult(Map<String, dynamic> place) async {
    final lat = place['lat'] as double?;
    final lng = place['lng'] as double?;

    if (lat == null || lng == null) return;

    final selectedLocation = LatLng(lat, lng);

    setState(() {
      _selectedLocation = selectedLocation;
      _updateMarker();
      _showSearchResults = false;
    });

    // Animate camera to selected location
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(selectedLocation, 15.0),
    );

    // Update preview with selected place info
    await _updateLocationPreview();
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!);
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  /// Apply map style based on current app theme
  Future<void> _applyMapStyle(GoogleMapController controller) async {
    try {
      if (AppTheme.currentMode == AppThemeMode.dark) {
        await controller.setMapStyle(AppColors.darkMapStyle);
      } else {
        await controller.setMapStyle(
          AppColors.lightMapStyle.isEmpty ? null : AppColors.lightMapStyle,
        );
      }
    } catch (e) {
      // Silently fail - map will use default style
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getPrimaryTextColor()),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Location',
          style: TextStyle(
            color: AppTheme.getPrimaryTextColor(),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            )
          else
            RepaintBoundary(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation ?? _cairoCenter,
                  zoom: 14.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _applyMapStyle(controller);
                },
                markers: _markers,
                onTap: _onMapTapped,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
                compassEnabled: true,
              ),
            ),
          // Search bar
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.currentMode == AppThemeMode.dark
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorderColor()),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (query) {
                  if (query.isEmpty) {
                    setState(() => _showSearchResults = false);
                  } else {
                    _searchPlaces(query);
                    setState(() => _showSearchResults = true);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  hintStyle: TextStyle(
                    color: AppTheme.getSecondaryTextColor(),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.getSecondaryTextColor(),
                    size: 20,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            searchController.clear();
                            setState(() => _showSearchResults = false);
                          },
                          child: Icon(
                            Icons.close,
                            color: AppTheme.getSecondaryTextColor(),
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 0,
                  ),
                  isDense: true,
                ),
                style: TextStyle(
                  color: AppTheme.getPrimaryTextColor(),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Search results dropdown
          if (_showSearchResults && _searchResults.isNotEmpty)
            Positioned(
              top: 68,
              left: 16,
              right: 16,
              child: SearchResultsDropdown(
                results: _searchResults,
                onResultTap: (place) {
                  _selectSearchResult(place);
                },
              ),
            ),
          // Tap outside to close dropdown
          if (_showSearchResults && _searchResults.isNotEmpty)
            Positioned.fill(
              top: 100,
              child: GestureDetector(
                onTap: () {
                  setState(() => _showSearchResults = false);
                },
                child: const SizedBox.expand(),
              ),
            ),
          // Bottom info card
          if (!_isLoading && _selectedLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.getBackgroundColor(),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 10),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.getBorderColor(),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Selected location label
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 15,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SELECTED LOCATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.getSecondaryTextColor(),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    // Teal gradient divider
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 10),
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
                    if (_geoLocationText != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _geoLocationText!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getPrimaryTextColor(),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_geoLocationCity != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'City: ${_geoLocationCity!}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 13,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Tap on the map to choose another location or drag the marker',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Animated confirm button
                    GestureDetector(
                      onTapDown: (_) => setState(() => _confirmPressed = true),
                      onTapUp: (_) {
                        setState(() => _confirmPressed = false);
                        _confirmLocation();
                      },
                      onTapCancel: () =>
                          setState(() => _confirmPressed = false),
                      child: AnimatedScale(
                        scale: _confirmPressed ? 0.96 : 1.0,
                        duration: _confirmPressed
                            ? const Duration(milliseconds: 80)
                            : const Duration(milliseconds: 300),
                        curve: _confirmPressed
                            ? Curves.easeIn
                            : Curves.easeOutBack,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondary,
                                AppColors.secondary.withOpacity(0.72),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Confirm Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
