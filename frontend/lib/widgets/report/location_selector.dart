import 'package:easy_localization/easy_localization.dart';
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

  @override
  void initState() {
    super.initState();
    _useCurrentLocation = widget.useCurrentLocation;
    _selectedLocation = widget.currentLocation;
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
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
    AppTheme.themeNotifier.removeListener(_onThemeChange);
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
                'map.location'.tr(),
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
                          : AppTheme.getCardBackgroundColor(),
                      border: Border.all(
                        color: _useCurrentLocation
                            ? AppColors.secondary
                            : AppTheme.getBorderColor(),
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
                          'report.current_location'.tr(),
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
                          : AppTheme.getCardBackgroundColor(),
                      border: Border.all(
                        color: !_useCurrentLocation
                            ? AppColors.secondary
                            : AppTheme.getBorderColor(),
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
                          'map.pick_on_map'.tr(),
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
                  color: AppTheme.getCardBackgroundColor(),
                  border: Border.all(
                    color: AppTheme.getBorderColor(),
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
                                ? 'report.location_selected'.tr()
                                : 'report.tap_to_open_map'.tr(),
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
                              'report.choose_location'.tr(),
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
