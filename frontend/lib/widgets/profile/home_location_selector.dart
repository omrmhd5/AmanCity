import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../report/location_picker_map.dart';

class HomeLocationSelector extends StatefulWidget {
  const HomeLocationSelector({Key? key}) : super(key: key);

  @override
  State<HomeLocationSelector> createState() => _HomeLocationSelectorState();
}

class _HomeLocationSelectorState extends State<HomeLocationSelector> {
  LatLng? _homeLocation;
  String? _homeAddress;
  String? _homeCity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeLocation();
  }

  /// Load saved home location from SharedPreferences
  Future<void> _loadHomeLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('home_location_lat');
      final lng = prefs.getDouble('home_location_lng');
      final address = prefs.getString('home_location_address');
      final city = prefs.getString('home_location_city');

      if (lat != null && lng != null) {
        setState(() {
          _homeLocation = LatLng(lat, lng);
          _homeAddress = address;
          _homeCity = city;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Save home location to SharedPreferences
  Future<void> _saveHomeLocation(
    LatLng location,
    String? address,
    String? city,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('home_location_lat', location.latitude);
      await prefs.setDouble('home_location_lng', location.longitude);
      if (address != null) {
        await prefs.setString('home_location_address', address);
      }
      if (city != null) {
        await prefs.setString('home_location_city', city);
      }

      setState(() {
        _homeLocation = location;
        _homeAddress = address;
        _homeCity = city;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Home location saved successfully'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving location: $e')));
      }
    }
  }

  /// Clear saved home location
  Future<void> _clearHomeLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('home_location_lat');
      await prefs.remove('home_location_lng');
      await prefs.remove('home_location_address');
      await prefs.remove('home_location_city');

      setState(() {
        _homeLocation = null;
        _homeAddress = null;
        _homeCity = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Home location cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing location: $e')));
      }
    }
  }

  /// Open map picker to set/edit home location
  Future<void> _openMapPicker() async {
    // Get current location as initial
    LatLng? initialLocation = _homeLocation;

    if (initialLocation == null) {
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          initialLocation = const LatLng(30.0444, 31.2357); // Cairo center
        } else {
          final position = await Geolocator.getCurrentPosition().timeout(
            const Duration(seconds: 5),
          );
          initialLocation = LatLng(position.latitude, position.longitude);
        }
      } catch (e) {
        initialLocation = const LatLng(30.0444, 31.2357); // Fallback to Cairo
      }
    }

    if (!mounted) return;

    // Track address/city during preview, but don't save yet
    String? pendingAddress;
    String? pendingCity;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerMap(
          initialLocation: initialLocation,
          onLocationSelected: (selectedLocation) {
            // ONLY save when user presses Confirm Location
            _saveHomeLocation(selectedLocation, pendingAddress, pendingCity);
          },
          onAddressUpdated: (address, city) {
            // Update pending values but don't save yet
            pendingAddress = address;
            pendingCity = city;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Home Location',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 12),

          // Home location card
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            )
          else if (_homeLocation != null)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.currentMode == AppThemeMode.dark
                        ? AppColors.primary
                        : AppColors.white,
                    border: Border.all(color: AppTheme.getBorderColor()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.home,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Home',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.getPrimaryTextColor(),
                                  ),
                                ),
                                if (_homeAddress != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _homeAddress!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.getSecondaryTextColor(),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (_homeCity != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'City: $_homeCity',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.getSecondaryTextColor(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Coordinates: ${_homeLocation!.latitude.toStringAsFixed(4)}, ${_homeLocation!.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.getSecondaryTextColor(),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(
                          'Edit',
                          style: TextStyle(
                            color: AppTheme.getPrimaryTextColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.secondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearHomeLocation,
                        icon: const Icon(Icons.delete, size: 16),
                        label: Text(
                          'Clear',
                          style: TextStyle(
                            color: AppTheme.getPrimaryTextColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade400),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.currentMode == AppThemeMode.dark
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.white,
                border: Border.all(
                  color: AppTheme.getBorderColor(),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.location_off,
                    color: AppTheme.getSecondaryTextColor(),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No home location saved',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Set Home Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
