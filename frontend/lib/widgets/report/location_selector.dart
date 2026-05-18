import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import 'location_picker_map.dart';

class LocationSelector extends StatefulWidget {
  final bool useCurrentLocation;
  final LatLng? currentLocation;
  final Function(LatLng) onLocationSelected;

  const LocationSelector({
    Key? key,
    required this.useCurrentLocation,
    this.currentLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  late bool _useCurrentLocation;
  LatLng? _selectedLocation;
  String? _selectedAddressText;
  late String _lastMapStylePreference;
  late Timer _themePreferenceListener;

  @override
  void initState() {
    super.initState();
    _useCurrentLocation = widget.useCurrentLocation;
    _selectedLocation = widget.currentLocation;
    _lastMapStylePreference = 'dark';
    _startThemePreferenceListener();
  }

  /// Listen for map theme preference changes
  void _startThemePreferenceListener() {
    _themePreferenceListener = Timer.periodic(Duration(milliseconds: 500), (
      _,
    ) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final currentPreference =
            prefs.getString('map_style_preference') ?? 'dark';
        if (_lastMapStylePreference != currentPreference) {
          _lastMapStylePreference = currentPreference;
          if (mounted) setState(() {});
        }
      } catch (e) {
        // Silently ignore preference check errors
      }
    });
  }

  @override
  void didUpdateWidget(LocationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useCurrentLocation != widget.useCurrentLocation) {
      setState(() {
        _useCurrentLocation = widget.useCurrentLocation;
      });
    }
    if (oldWidget.currentLocation != widget.currentLocation) {
      _selectedLocation = widget.currentLocation;
    }
  }

  @override
  void dispose() {
    _themePreferenceListener.cancel();
    super.dispose();
  }

  void _openMapPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerMap(
          initialLocation: _selectedLocation ?? widget.currentLocation,
          onLocationSelected: (selectedLocation) {
            setState(() {
              _selectedLocation = selectedLocation;
            });
            widget.onLocationSelected(selectedLocation);
          },
          onAddressUpdated: (address, city) {
            setState(() {
              _selectedAddressText = address;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 15,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'LOCATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.getSecondaryTextColor(),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Toggle Current / Manual Location
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _useCurrentLocation = true);
                    if (widget.currentLocation != null) {
                      _selectedLocation = widget.currentLocation;
                      widget.onLocationSelected(widget.currentLocation!);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _useCurrentLocation
                          ? AppColors.secondary.withOpacity(0.12)
                          : AppTheme.getBackgroundColor().withOpacity(0.5),
                      border: Border.all(
                        color: _useCurrentLocation
                            ? AppColors.secondary
                            : AppTheme.getBorderColor().withOpacity(0.15),
                        width: _useCurrentLocation ? 1.5 : 0.75,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: _useCurrentLocation
                              ? AppColors.secondary
                              : AppTheme.getSecondaryTextColor(),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _useCurrentLocation
                                ? AppColors.secondary
                                : AppTheme.getSecondaryTextColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _useCurrentLocation = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: !_useCurrentLocation
                          ? AppColors.secondary.withOpacity(0.12)
                          : AppTheme.getBackgroundColor().withOpacity(0.5),
                      border: Border.all(
                        color: !_useCurrentLocation
                            ? AppColors.secondary
                            : AppTheme.getBorderColor().withOpacity(0.15),
                        width: !_useCurrentLocation ? 1.5 : 0.75,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          color: !_useCurrentLocation
                              ? AppColors.secondary
                              : AppTheme.getSecondaryTextColor(),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pick on Map',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !_useCurrentLocation
                                ? AppColors.secondary
                                : AppTheme.getSecondaryTextColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!_useCurrentLocation) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _openMapPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.getBackgroundColor().withOpacity(0.5),
                  border: Border.all(
                    color: AppTheme.getBorderColor().withOpacity(0.15),
                    width: 0.75,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.2),
                          width: 0.75,
                        ),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAddressText != null
                                ? 'Location Selected'
                                : 'Tap to open map',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _selectedAddressText != null
                                  ? AppColors.secondary
                                  : AppTheme.getSecondaryTextColor(),
                            ),
                          ),
                          if (_selectedAddressText != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              _selectedAddressText!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.getPrimaryTextColor(),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else ...[
                            const SizedBox(height: 3),
                            Text(
                              'Choose a custom location on the map',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.getSecondaryTextColor(),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
