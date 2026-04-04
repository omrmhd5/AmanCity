import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../models/report_incident_model.dart' hide LatLng;
import '../models/prediction_result_model.dart';
import '../services/backend_api/prediction_api_service.dart';
import '../services/backend_api/incident_api_service.dart';
import '../widgets/report/location_context_card.dart';
import '../widgets/report/evidence_type_selector.dart';
import '../widgets/report/prediction_result_dialog.dart';
import '../widgets/report/location_selector.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({Key? key}) : super(key: key);

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  EvidenceType? _selectedEvidenceType;
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  bool _isLoadingLocation = false;
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  File? _selectedFile;
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    _loadUserLocationFromCache();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

        if (age.inMinutes < 60) {
          // Cache is fresh, use it
          if (mounted) {
            setState(() {
              _currentLocation = LatLng(cachedLat, cachedLng);
              _selectedLocation = _currentLocation;
              _isLoadingLocation = false;
            });
          }
          print('📍 Using cached location (${age.inSeconds}s old)');
          return;
        }
      }
    } catch (e) {
      print('⚠️ Error loading cached location: $e');
    }

    // No valid cache, fetch fresh location
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
        });
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
        print('✅ Location cached');
      } catch (e) {
        print('⚠️ Failed to cache location: $e');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        // Default to Cairo if location fails
        setState(() {
          _currentLocation = const LatLng(30.0444, 31.2357);
          _selectedLocation = _currentLocation;
        });
      }
    }
  }

  Future<void> _onEvidenceTypeSelected(EvidenceType type) async {
    setState(() => _isPickingFile = true);

    try {
      final picker = ImagePicker();
      XFile? pickedFile;

      if (type == EvidenceType.photo) {
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
      } else if (type == EvidenceType.video) {
        pickedFile = await picker.pickVideo(source: ImageSource.gallery);
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
            content: Text('✅ Incident created: ${incident.title}'),
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

        // Navigate back to map to see new incident
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        });
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Text(
                        'Report Incident',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ),
                    ),
                    // Location Context Card
                    if (_currentLocation != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                        child: LocationContextCard(
                          latitude: _currentLocation!.latitude,
                          longitude: _currentLocation!.longitude,
                          isLoading: _isLoadingLocation,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildLocationLoadingShimmer(),
                      ),
                    // Location Selector
                    LocationSelector(
                      useCurrentLocation: _selectedLocation == _currentLocation,
                      currentLocation: _currentLocation,
                      onLocationSelected: (location) {
                        setState(() => _selectedLocation = location);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Title Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Title',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getSecondaryTextColor(),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Car Accident, Fire Incident...',
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
                    // Evidence Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Evidence',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getSecondaryTextColor(),
                              letterSpacing: 0.5,
                            ),
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
                    const SizedBox(height: 24),
                    // Description Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description (Optional)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getSecondaryTextColor(),
                              letterSpacing: 0.5,
                            ),
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
                    const SizedBox(height: 24),
                    // Report Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            disabledBackgroundColor: AppColors.danger
                                .withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Report Incident',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
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
