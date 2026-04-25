import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _useCurrentLocation = widget.useCurrentLocation;
    _selectedLocation = widget.currentLocation;
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
              _selectedCity = city;
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
          Text(
            'Location',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.getSecondaryTextColor(),
              letterSpacing: 0.5,
            ),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _useCurrentLocation
                          ? AppColors.secondary.withOpacity(0.2)
                          : AppTheme.currentMode == AppThemeMode.dark
                          ? AppColors.primary
                          : AppColors.white,
                      border: Border.all(
                        color: _useCurrentLocation
                            ? AppColors.secondary
                            : AppTheme.getBorderColor(),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: !_useCurrentLocation
                          ? AppColors.secondary.withOpacity(0.2)
                          : AppTheme.currentMode == AppThemeMode.dark
                          ? AppColors.primary
                          : AppColors.white,
                      border: Border.all(
                        color: !_useCurrentLocation
                            ? AppColors.secondary
                            : AppTheme.getBorderColor(),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
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
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.currentMode == AppThemeMode.dark
                      ? AppColors.primary
                      : AppColors.white,
                  border: Border.all(color: AppTheme.getBorderColor()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tap to open map',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getSecondaryTextColor(),
                            ),
                          ),
                          if (_selectedAddressText != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  _selectedAddressText!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.getPrimaryTextColor(),
                                  ),
                                ),
                                if (_selectedCity != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'City: ${_selectedCity!}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: AppTheme.getSecondaryTextColor(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.getSecondaryTextColor(),
                      size: 14,
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
