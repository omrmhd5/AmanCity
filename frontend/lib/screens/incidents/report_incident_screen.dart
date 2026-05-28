import 'dart:io';
import 'dart:async';
import 'dart:math' as Math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../models/incidents/report_incident_model.dart' hide LatLng;
import '../../models/prediction/prediction_result_model.dart';
import '../../services/prediction/prediction_api_service.dart';
import '../../services/incidents/incident_api_service.dart';
import '../../services/map/geocoding_api_service.dart';
import '../../services/map/location_stream_service.dart';
import '../../widgets/report/location_context_card.dart';
import '../../widgets/report/evidence_type_selector.dart';
import '../../widgets/report/prediction_result_dialog.dart';
import '../../widgets/report/location_selector.dart';

class ReportIncidentScreen extends StatefulWidget {
  final VoidCallback? onReported;
  final ValueNotifier<int>? activationSignal;

  const ReportIncidentScreen({Key? key, this.onReported, this.activationSignal})
    : super(key: key);

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  EvidenceType? _selectedEvidenceType;
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  bool _isLoadingLocation = false;
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitPressed = false;
  File? _selectedFile;
  bool _isPickingFile = false;
  String? _geoLocationText;
  String? _geoLocationCity;

  // Geocoding cache (distance-based, unlimited — no time expiry)
  // Cache is valid when _geoLocationText != null AND location within 10m
  LatLng? _lastGeocodeLocation;
  static const double _geocodeReloadDistanceM = 10.0; // 10 meters
  static const String _geocodeCacheKey = 'cached_geocoding_text';
  static const String _geocodeCacheLocationKey = 'cached_geocoding_location';
  static const String _geocodeCacheCityKey = 'cached_geocoding_city';

  StreamSubscription<Position>? _locationStreamSubscription;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    widget.activationSignal?.addListener(_onActivation);
    _initialize();
  }

  void _onActivation() {
    _entryController.forward(from: 0);
  }

  Widget _animated(Widget child, {double start = 0.0, double end = 1.0}) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  /// Initialize screen - strictly sequential to avoid race conditions
  Future<void> _initialize() async {
    await _loadPersistedGeocoding(); // 1. Load geocoding cache from disk
    await _loadUserLocationFromCache(); // 2. Load location (cache already available)
    _startFollowingLocation(); // 3. Start stream (both caches loaded)
  }

  /// Start following user location in real-time
  void _startFollowingLocation() {
    _locationStreamSubscription?.cancel();
    try {
      _locationStreamSubscription =
          LocationStreamService.startLocationTracking(
                onLocationUpdate: (newLocation) {
                  setState(() {
                    _currentLocation = newLocation;
                    _selectedLocation =
                        newLocation; // Report location updates with user
                  });

                  // Only geocode if moved > 10m from last geocode location
                  if (_lastGeocodeLocation != null) {
                    final distanceM = _calculateDistanceMeters(
                      _lastGeocodeLocation!,
                      newLocation,
                    );
                    if (distanceM >= _geocodeReloadDistanceM) {
                      // Invalidate cache by clearing text
                      setState(() {
                        _geoLocationText = null;
                        _geoLocationCity = null;
                      });
                      _lastGeocodeLocation = newLocation;
                      _updateLocationPreview(newLocation);
                    }
                  } else {
                    // First time stream fires — lastGeocodeLocation not set yet
                    _lastGeocodeLocation = newLocation;
                    // Only geocode if we don't already have cached text
                    if (_geoLocationText == null)
                      _updateLocationPreview(newLocation);
                  }
                },
                distanceFilterMeters: 10,
              )
              as StreamSubscription<Position>?;
    } catch (e) {
      // Location tracking failed, continue with cached location
    }
  }

  @override
  void dispose() {
    widget.activationSignal?.removeListener(_onActivation);
    _entryController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationStreamSubscription?.cancel();
    super.dispose();
  }

  /// Load location from cache — unlimited, no time expiry (stream keeps it fresh)
  Future<void> _loadUserLocationFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLat = prefs.getDouble('user_location_lat');
      final cachedLng = prefs.getDouble('user_location_lng');

      if (cachedLat != null && cachedLng != null) {
        // Use cached location regardless of age — GPS stream will update it
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(cachedLat, cachedLng);
            _selectedLocation = _currentLocation;
            _isLoadingLocation = false;
            _lastGeocodeLocation =
                _currentLocation; // Set reference for 10m check
          });
        }
        // Only geocode if we don't have cached geocoding text
        if (_geoLocationText == null || _geoLocationCity == null) {
          await _updateLocationPreview(_currentLocation!);
        }
        return;
      }
    } catch (e) {
      // Error loading cached location
    }

    // No cached location at all — fetch fresh GPS
    await _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _selectedLocation = _currentLocation;
          _isLoadingLocation = false;
          _lastGeocodeLocation =
              _currentLocation; // Set reference for 10m check
        });
      }

      // Only geocode if we don't already have cached text
      if (_geoLocationText == null || _geoLocationCity == null) {
        await _updateLocationPreview(_currentLocation!);
      }

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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        // Default to Cairo if location fails
        setState(() {
          _currentLocation = const LatLng(30.0444, 31.2357);
          _selectedLocation = _currentLocation;
          _lastGeocodeLocation =
              _currentLocation; // Set reference for 10m check
        });
      }
      // Geocode the default location only if no cached text
      if (_geoLocationText == null || _geoLocationCity == null) {
        await _updateLocationPreview(_currentLocation!);
      }
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

  /// Update location preview with geocoded address and city
  Future<void> _updateLocationPreview(LatLng location) async {
    // Single guard: skip if we already have text AND location is within 10m
    if (_geoLocationText != null &&
        _geoLocationCity != null &&
        _lastGeocodeLocation != null &&
        _calculateDistanceMeters(_lastGeocodeLocation!, location) <
            _geocodeReloadDistanceM) {
      return; // Cache valid
    }

    final result = await GeocodingService.reverseGeocode(
      location.latitude,
      location.longitude,
    );
    if (mounted) {
      final text = result['text'];
      final city = result['city'];
      setState(() {
        _geoLocationText = text;
        _geoLocationCity = city;
        _lastGeocodeLocation = location; // Update reference
      });
      if (text != null && city != null) {
        await _persistGeocoding(text, city, location);
      }
    }
  }

  /// Load persisted geocoding from SharedPreferences (survives hot reload)
  Future<void> _loadPersistedGeocoding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(_geocodeCacheKey);
      final city = prefs.getString(_geocodeCacheCityKey);
      final locLat = prefs.getDouble(_geocodeCacheLocationKey + '_lat');
      final locLng = prefs.getDouble(_geocodeCacheLocationKey + '_lng');

      debugPrint(
        '[GeoCache] Load → text=$text city=$city lat=$locLat lng=$locLng',
      );

      if (text == null || city == null || locLat == null || locLng == null)
        return;

      if (!mounted) return;
      setState(() {
        _geoLocationText = text;
        _geoLocationCity = city;
        _lastGeocodeLocation = LatLng(locLat, locLng);
        // No _geocodingCachedTime needed — _geoLocationText != null is the sentinel
      });
    } catch (_) {}
  }

  /// Save geocoding to SharedPreferences (survives hot reload/app restart)
  Future<void> _persistGeocoding(
    String text,
    String city,
    LatLng location,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_geocodeCacheKey, text);
      await prefs.setString(_geocodeCacheCityKey, city);
      await prefs.setDouble(
        _geocodeCacheLocationKey + '_lat',
        location.latitude,
      );
      await prefs.setDouble(
        _geocodeCacheLocationKey + '_lng',
        location.longitude,
      );
      debugPrint(
        '[GeoCache] Saved → text=$text city=$city lat=${location.latitude} lng=${location.longitude}',
      );
    } catch (e) {
      debugPrint('[GeoCache] Save FAILED: $e');
    }
  }

  Future<void> _onEvidenceTypeSelected(EvidenceType type) async {
    // Show source picker bottom sheet
    final source = await _showSourcePicker(type);
    if (source == null) return; // user dismissed

    setState(() => _isPickingFile = true);

    try {
      final picker = ImagePicker();
      XFile? pickedFile;

      if (type == EvidenceType.photo) {
        pickedFile = await picker.pickImage(
          source: source,
          preferredCameraDevice: CameraDevice.rear,
          imageQuality: 90,
        );
      } else if (type == EvidenceType.video) {
        pickedFile = await picker.pickVideo(
          source: source,
          preferredCameraDevice: CameraDevice.rear,
        );
      }

      if (pickedFile != null) {
        setState(() {
          _selectedEvidenceType = type;
          _selectedFile = File(pickedFile!.path);
          _isPickingFile = false;
        });
      } else {
        setState(() => _isPickingFile = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to select file. Please try again.'),
        ),
      );
      setState(() => _isPickingFile = false);
    }
  }

  Future<ImageSource?> _showSourcePicker(EvidenceType type) async {
    final isPhoto = type == EvidenceType.photo;
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.getBackgroundColor().withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title row
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        isPhoto
                            ? Icons.photo_camera_rounded
                            : Icons.videocam_rounded,
                        size: 17,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPhoto ? 'Select Photo' : 'Select Video',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Teal gradient divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(bottom: 20),
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
                Row(
                  children: [
                    Expanded(
                      child: _sourceOption(
                        icon: isPhoto
                            ? Icons.camera_alt_rounded
                            : Icons.videocam_rounded,
                        label: 'Camera',
                        onTap: () => Navigator.pop(ctx, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sourceOption(
                        icon: isPhoto
                            ? Icons.photo_library_rounded
                            : Icons.video_library_rounded,
                        label: 'Gallery',
                        onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.secondary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.getPrimaryTextColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createIncidentFromPrediction(
    PredictionResult prediction,
  ) async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing file')));
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing location')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final incident = await IncidentApiService.createIncident(
        photo: _selectedFile!,
        title: _titleController.text.trim(),
        className: prediction.className,
        description: _descriptionController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        confidence: prediction.confidence,
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incident created: ${incident.title}'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _selectedEvidenceType = null;
          _selectedFile = null;
          _titleController.clear();
          _descriptionController.clear();
        });

        // Notify parent (switches to map + refreshes hotspots/incidents)
        widget.onReported?.call();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to save your report. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo or video')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add a title')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Send file to prediction API
      final prediction = await PredictionApiService.predictFromFile(
        _selectedFile!,
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        // Show prediction result dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PredictionResultDialog(
            prediction: prediction,
            onCreateIncident: (pred) => _createIncidentFromPrediction(pred),
            onDismiss: () {
              // Reset form on dismiss
              setState(() {
                _selectedEvidenceType = null;
                _selectedFile = null;
                _titleController.clear();
                _descriptionController.clear();
              });
            },
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (mounted) {
        // Extract just the error message without the exception wrapper
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring('Exception: '.length);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.getBackgroundColor(),
                  AppTheme.getBackgroundColor().withOpacity(0.95),
                ],
              ),
            ),
          ),
          // Main content
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _animated(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.report_rounded,
                              size: 20,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Report Incident',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.getPrimaryTextColor(),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Help keep your community safe',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.getSecondaryTextColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      start: 0.0,
                      end: 0.5,
                    ),
                    const SizedBox(height: 10),
                    // Teal gradient divider
                    _animated(
                      Container(
                        height: 1,
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
                      start: 0.05,
                      end: 0.5,
                    ),
                    const SizedBox(height: 4),
                    // Location Context Card
                    _animated(
                      _currentLocation != null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 16.0,
                              ),
                              child: LocationContextCard(
                                latitude: _currentLocation!.latitude,
                                longitude: _currentLocation!.longitude,
                                isLoading: _isLoadingLocation,
                                addressText: _geoLocationText,
                                city: _geoLocationCity,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildLocationLoadingShimmer(),
                            ),
                      start: 0.1,
                      end: 0.55,
                    ),
                    // Location Selector
                    _animated(
                      LocationSelector(
                        useCurrentLocation:
                            _selectedLocation == _currentLocation,
                        currentLocation: _currentLocation,
                        onLocationSelected: (location) {
                          setState(() => _selectedLocation = location);
                          _updateLocationPreview(location);
                        },
                      ),
                      start: 0.15,
                      end: 0.6,
                    ),
                    const SizedBox(height: 16),
                    // Title Section
                    _animated(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.title_rounded,
                                  size: 15,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'TITLE',
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
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText:
                                    'e.g., Car Accident, Fire Incident...',
                                hintStyle: TextStyle(
                                  color: AppTheme.getSecondaryTextColor(),
                                ),
                                filled: true,
                                fillColor:
                                    AppTheme.currentMode == AppThemeMode.dark
                                    ? AppColors.primary
                                    : AppColors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.getBorderColor(),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.getBorderColor(),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.secondary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                color: AppTheme.getPrimaryTextColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      start: 0.2,
                      end: 0.65,
                    ),
                    // Evidence Section
                    _animated(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.upload_file_rounded,
                                  size: 15,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'UPLOAD EVIDENCE',
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
                            if (_selectedFile == null)
                              _isPickingFile
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.secondary,
                                              ),
                                        ),
                                      ),
                                    )
                                  : EvidenceTypeSelector(
                                      selectedType: _selectedEvidenceType,
                                      onTypeSelected: _onEvidenceTypeSelected,
                                    )
                            else
                              _buildFilePreview(),
                          ],
                        ),
                      ),
                      start: 0.25,
                      end: 0.7,
                    ),
                    const SizedBox(height: 24),
                    // Description Section
                    _animated(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notes_rounded,
                                  size: 15,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'DESCRIPTION (OPTIONAL)',
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
                            TextField(
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Add additional details...',
                                hintStyle: TextStyle(
                                  color: AppTheme.getSecondaryTextColor(),
                                ),
                                filled: true,
                                fillColor:
                                    AppTheme.currentMode == AppThemeMode.dark
                                    ? AppColors.primary
                                    : AppColors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.getBorderColor(),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.getBorderColor(),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.secondary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                color: AppTheme.getPrimaryTextColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      start: 0.3,
                      end: 0.75,
                    ),
                    const SizedBox(height: 24),
                    // Report Button
                    _animated(
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GestureDetector(
                          onTapDown: _isSubmitting
                              ? null
                              : (_) => setState(() => _submitPressed = true),
                          onTapUp: _isSubmitting
                              ? null
                              : (_) {
                                  setState(() => _submitPressed = false);
                                  _submitReport();
                                },
                          onTapCancel: () =>
                              setState(() => _submitPressed = false),
                          child: AnimatedScale(
                            scale: _submitPressed ? 0.96 : 1.0,
                            duration: _submitPressed
                                ? const Duration(milliseconds: 80)
                                : const Duration(milliseconds: 300),
                            curve: _submitPressed
                                ? Curves.easeIn
                                : Curves.easeOutBack,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _isSubmitting
                                      ? [
                                          AppColors.danger.withOpacity(0.4),
                                          AppColors.danger.withOpacity(0.3),
                                        ]
                                      : [
                                          AppColors.danger,
                                          AppColors.danger.withOpacity(0.75),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _isSubmitting
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: AppColors.danger.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.report_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Report Incident',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      start: 0.4,
                      end: 0.85,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.currentMode == AppThemeMode.dark
            ? AppColors.primary
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary, width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (_selectedFile != null &&
              _selectedEvidenceType == EvidenceType.photo)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_selectedFile!, fit: BoxFit.cover),
              ),
            )
          else if (_selectedEvidenceType == EvidenceType.video)
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_circle_outline,
                size: 64,
                color: AppColors.secondary,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _selectedEvidenceType == EvidenceType.photo
                    ? Icons.photo_camera
                    : Icons.videocam,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile!.path.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
                    ),
                    Text(
                      '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedFile = null),
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationLoadingShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.currentMode == AppThemeMode.dark
            ? AppColors.primary
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Shimmer.fromColors(
              baseColor: Colors.grey,
              highlightColor: Colors.white,
              child: SizedBox.expand(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(4),
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

class Shimmer extends StatefulWidget {
  final Color baseColor;
  final Color highlightColor;
  final Widget child;

  const Shimmer.fromColors({
    required this.baseColor,
    required this.highlightColor,
    required this.child,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(
                -1.0 - _shimmerController.value * 2,
                _shimmerController.value * 2,
              ),
              end: Alignment(
                2.0 - _shimmerController.value * 2,
                _shimmerController.value * 2,
              ),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
