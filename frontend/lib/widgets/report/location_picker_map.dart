import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../../services/backend_api/geocoding_api_service.dart';

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
  Marker? _selectedMarker;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _geoLocationText;
  String? _geoLocationCity;

  static const LatLng _cairoCenter = LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? _cairoCenter;
    _updateMarker();
    _updateLocationPreview();
    _getUserLocationIfAvailable();
  }

  Future<void> _getUserLocationIfAvailable() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = userLocation;
        _updateMarker();
        _isLoading = false;
      });

      await _updateLocationPreview();

      // Animate to user location
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation, 15.0),
      );
    } catch (e) {
      setState(() => _isLoading = false);
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

  void _confirmLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!);
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
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
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              onTap: _onMapTapped,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              compassEnabled: true,
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
