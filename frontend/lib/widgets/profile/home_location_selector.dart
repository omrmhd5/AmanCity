import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../report/location_picker_map.dart';

class HomeLocationSelector extends StatefulWidget {
  final bool isCompact;

  const HomeLocationSelector({Key? key, this.isCompact = false})
    : super(key: key);

  @override
  State<HomeLocationSelector> createState() => _HomeLocationSelectorState();
}

class _HomeLocationSelectorState extends State<HomeLocationSelector> {
  LatLng? _homeLocation;
  String? _homeAddress;
  String? _homeCity;
  bool _isLoading = true;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _loadHomeLocation();
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    super.dispose();
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
            content: Text('profile.home_location_saved'.tr()),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile.home_location_save_error'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
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
          SnackBar(
            content: Text('profile.home_location_cleared'.tr()),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile.error_clearing_location'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    }
  }

  /// Open map picker to set/edit home location
  Future<void> _openMapPicker() async {
    LatLng? initialLocation = _homeLocation;

    if (initialLocation == null) {
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          initialLocation = const LatLng(30.0444, 31.2357);
        } else {
          final position = await Geolocator.getCurrentPosition().timeout(
            const Duration(seconds: 5),
          );
          initialLocation = LatLng(position.latitude, position.longitude);
        }
      } catch (e) {
        initialLocation = const LatLng(30.0444, 31.2357);
      }
    }

    if (!mounted) return;

    String? pendingAddress;
    String? pendingCity;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerMap(
          initialLocation: initialLocation,
          onLocationSelected: (selectedLocation) {
            _saveHomeLocation(selectedLocation, pendingAddress, pendingCity);
          },
          onAddressUpdated: (address, city) {
            pendingAddress = address;
            pendingCity = city;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactTile();
    } else {
      return _buildFullTile();
    }
  }

  Widget _buildCompactTile() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
        ),
      );
    }

    return GestureDetector(
      onTap: _openMapPicker,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: Duration(milliseconds: _pressed ? 90 : 300),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.getCardBackgroundColor(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.getBorderColor(), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.20),
                        width: 0.75,
                      ),
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'profile.home_location'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getPrimaryTextColor(),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _homeLocation != null
                              ? (_homeAddress ??
                                    _homeCity ??
                                    'profile.location_set'.tr())
                              : 'profile.set_home_location_prompt'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_homeCity != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.25),
                          width: 0.75,
                        ),
                      ),
                      child: Text(
                        _homeCity!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullTile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.home_location'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 12),
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
                                  'profile.home'.tr(),
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
                          'common.edit'.tr(),
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
                          'common.clear'.tr(),
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
                    'profile.no_home_location'.tr(),
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
                      label: Text('profile.set_home_location'.tr()),
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
