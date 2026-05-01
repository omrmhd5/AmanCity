import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
import '../../services/backend_api/geocoding_api_service.dart';
import '../../services/backend_api/places_api_service.dart';
import '../map/search_results_dropdown.dart';

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
  }

  @override
  void dispose() {
    searchController.dispose();
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

  /// Fetch geocoded address for current location
  Future<void> _updateLocationPreview() async {
    if (_selectedLocation == null) return;

    final result = await GeocodingService.reverseGeocode(
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    );

    if (mounted) {
      setState(() {
        _geoLocationText = result['text'];
        _geoLocationCity = result['city'];
      });
      // Notify parent about address update
      widget.onAddressUpdated?.call(_geoLocationText, _geoLocationCity);
    }
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

  /// Apply map style based on SharedPreferences preference
  Future<void> _applyMapStyle(GoogleMapController controller) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapStylePreference =
          prefs.getString('map_style_preference') ?? 'dark';

      if (mapStylePreference == 'dark') {
        await controller.setMapStyle(AppColors.darkMapStyle);
      } else {
        // Light style uses empty string (default Google Maps light style)
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
            GoogleMap(
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
                    top: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 12),
                    Text(
                      'Tap on the map to choose another location or drag the marker',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Confirm Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
