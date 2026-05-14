import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../services/sos/sos_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/sos_screen/sos_active_view.dart';
import '../../widgets/sos_screen/sos_header.dart';
import '../../widgets/sos_screen/sos_hold_button.dart';
import '../../widgets/sos_screen/sos_utility_toggles.dart';
import 'sos_contacts_screen.dart';
import 'sos_history_screen.dart';

enum _SosView { idle, contacts, history }

class SosScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<bool>? onActiveStateChanged;

  const SosScreen({Key? key, this.onBack, this.onActiveStateChanged})
    : super(key: key);

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final SosService _sosService = SosService();

  bool _isActive = false;
  bool _flashEnabled = false;
  bool _sirenEnabled = false;
  bool _locationAcquired = false;
  bool _contactsNotified = false;
  int _recordingSeconds = 0;
  String? _locationText;
  double? _activeLat;
  double? _activeLng;
  _SosView _currentView = _SosView.idle;

  Timer? _recordingTimer;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    if (_isActive) {
      _sosService.stopRecording(lat: _activeLat, lng: _activeLng);
      _sosService.stopFlashStrobe();
      _sosService.stopSiren();
    }
    super.dispose();
  }

  // ─── Idle toggles ────────────────────────────────────────────────────────────

  Future<void> _onFlashToggle(bool value) async {
    setState(() => _flashEnabled = value);
    if (value) {
      await _sosService.startFlashStrobe();
    } else {
      await _sosService.stopFlashStrobe();
    }
  }

  Future<void> _onSirenToggle(bool value) async {
    setState(() => _sirenEnabled = value);
    if (value) {
      await _sosService.startSiren();
    } else {
      await _sosService.stopSiren();
    }
  }

  // ─── Activation ──────────────────────────────────────────────────────────────

  Future<void> _onActivate() async {
    setState(() {
      _isActive = true;
      _locationAcquired = false;
      _contactsNotified = false;
      _recordingSeconds = 0;
    });
    widget.onActiveStateChanged?.call(true);

    // Ensure flash is running
    if (!_flashEnabled) {
      setState(() => _flashEnabled = true);
      await _sosService.startFlashStrobe();
    }

    // Ensure siren is running
    if (!_sirenEnabled) {
      setState(() => _sirenEnabled = true);
      await _sosService.startSiren();
    }

    // Start recording
    await _sosService.startRecording();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });

    // Acquire location and notify contacts in background
    _acquireAndNotify();
  }

  Future<void> _acquireAndNotify() async {
    final position = await _sosService.getCurrentLocation();

    if (!mounted) return;

    double? lat;
    double? lng;

    if (position != null) {
      lat = position.latitude;
      lng = position.longitude;
      setState(() {
        _locationAcquired = true;
        _activeLat = lat;
        _activeLng = lng;
        _locationText =
            '${lat!.toStringAsFixed(4)}° N, ${lng!.toStringAsFixed(4)}° E';
      });
    }

    // Send WhatsApp alerts sequentially
    final contacts = await _sosService.getContacts();
    for (int i = 0; i < contacts.length; i++) {
      if (i > 0) await Future.delayed(const Duration(milliseconds: 600));
      await _sosService.sendWhatsAppAlert(contacts[i], lat, lng);
    }

    if (mounted) setState(() => _contactsNotified = true);
  }

  // ─── Cancel ──────────────────────────────────────────────────────────────────

  Future<void> _onCancel() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    // Stop recording first (with coords so metadata is complete)
    await _sosService.stopRecording(lat: _activeLat, lng: _activeLng);
    await _sosService.stopFlashStrobe();
    await _sosService.stopSiren();

    if (mounted) {
      setState(() {
        _isActive = false;
        _flashEnabled = false;
        _sirenEnabled = false;
        _locationAcquired = false;
        _contactsNotified = false;
        _recordingSeconds = 0;
        _locationText = null;
        _activeLat = null;
        _activeLng = null;
      });
      widget.onActiveStateChanged?.call(false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.onBack == null || _currentView == _SosView.idle,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_currentView != _SosView.idle) {
            // If in contacts or history view, go back to idle
            setState(() => _currentView = _SosView.idle);
          } else if (widget.onBack != null) {
            widget.onBack!();
          }
        }
      },
      child: Scaffold(
        backgroundColor: _isActive
            ? const Color(0xFF0B1E3C)
            : AppTheme.getBackgroundColor(),
        body: SafeArea(
          child: _isActive
              ? _buildActiveView()
              : _currentView == _SosView.contacts
              ? SosContactsScreen(
                  onBack: () => setState(() => _currentView = _SosView.idle),
                )
              : _currentView == _SosView.history
              ? SosHistoryScreen(
                  onBack: () => setState(() => _currentView = _SosView.idle),
                )
              : _buildIdleView(),
        ),
      ),
    );
  }

  Widget _buildActiveView() {
    return SosActiveView(
      locationAcquired: _locationAcquired,
      contactsNotified: _contactsNotified,
      recordingSeconds: _recordingSeconds,
      locationText: _locationText,
      onCancel: _onCancel,
    );
  }

  Widget _buildIdleView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SosHeader(onBackPressed: widget.onBack),
          const SizedBox(height: 24),
          SosUtilityToggles(
            flashEnabled: _flashEnabled,
            sirenEnabled: _sirenEnabled,
            onFlashToggle: _onFlashToggle,
            onSirenToggle: _onSirenToggle,
          ),
          const SizedBox(height: 44),
          SosHoldButton(onActivate: _onActivate),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Location tracking active',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.getSecondaryTextColor(),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          // Manage Contacts card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () => setState(() => _currentView = _SosView.contacts),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getCardBackgroundColor(),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.getBorderColor()),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.contacts_outlined,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage SOS Contacts',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getPrimaryTextColor(),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add trusted contacts to receive emergency alerts',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Past Recordings card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () => setState(() => _currentView = _SosView.history),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getCardBackgroundColor(),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.getBorderColor()),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Past Recordings',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getPrimaryTextColor(),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Review & play audio captured during SOS alerts',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
