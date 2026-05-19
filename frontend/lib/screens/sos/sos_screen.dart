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
  final ValueNotifier<bool>? activateSignal;
  final ValueNotifier<String?>? viewSignal;

  const SosScreen({
    Key? key,
    this.onBack,
    this.onActiveStateChanged,
    this.activateSignal,
    this.viewSignal,
  }) : super(key: key);

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  final SosService _sosService = SosService();

  late AnimationController _entryController;

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

  bool _viewFromExternal = false;

  // Pressed states for management cards
  bool _contactsPressed = false;
  bool _historyPressed = false;

  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    widget.activateSignal?.addListener(_onActivateSignal);
    widget.viewSignal?.addListener(_onViewSignal);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _recordingTimer?.cancel();
    widget.activateSignal?.removeListener(_onActivateSignal);
    widget.viewSignal?.removeListener(_onViewSignal);
    if (_isActive) {
      _sosService.stopRecording(lat: _activeLat, lng: _activeLng);
      _sosService.stopFlashStrobe();
      _sosService.stopSiren();
    }
    super.dispose();
  }

  void _onActivateSignal() {
    if (widget.activateSignal?.value == true) {
      widget.activateSignal!.value = false;
      _onActivate();
    }
  }

  void _onViewSignal() {
    final v = widget.viewSignal?.value;
    if (v == null) return;
    widget.viewSignal!.value = null;
    if (v == 'contacts') {
      setState(() {
        _currentView = _SosView.contacts;
        _viewFromExternal = true;
      });
    } else if (v == 'history') {
      setState(() {
        _currentView = _SosView.history;
        _viewFromExternal = true;
      });
    }
  }

  // ─── Animation helper ────────────────────────────────────────────────────────

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

    // Start recording first — so recorder initialises audio session before siren
    await _sosService.startRecording();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });

    // Ensure flash is running
    if (!_flashEnabled) {
      setState(() => _flashEnabled = true);
      await _sosService.startFlashStrobe();
    }

    // Start siren LAST — its playAndRecord audio context is applied on top of
    // whatever the recorder set, allowing both to coexist
    if (!_sirenEnabled) {
      setState(() => _sirenEnabled = true);
    }
    await _sosService.startSiren();

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
            final fromExternal = _viewFromExternal;
            setState(() {
              _currentView = _SosView.idle;
              _viewFromExternal = false;
            });
            if (fromExternal) {
              widget.onBack?.call();
            } else {
              _entryController.forward(from: 0);
            }
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
                  onBack: () {
                    final fromExternal = _viewFromExternal;
                    setState(() {
                      _currentView = _SosView.idle;
                      _viewFromExternal = false;
                    });
                    if (fromExternal) {
                      widget.onBack?.call();
                    } else {
                      _entryController.forward(from: 0);
                    }
                  },
                )
              : _currentView == _SosView.history
              ? SosHistoryScreen(
                  onBack: () {
                    final fromExternal = _viewFromExternal;
                    setState(() {
                      _currentView = _SosView.idle;
                      _viewFromExternal = false;
                    });
                    if (fromExternal) {
                      widget.onBack?.call();
                    } else {
                      _entryController.forward(from: 0);
                    }
                  },
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
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _animated(
            SosHeader(onBackPressed: widget.onBack),
            start: 0.0,
            end: 0.5,
          ),
          // Teal gradient divider
          _animated(
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
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
            ),
            start: 0.05,
            end: 0.55,
          ),
          const SizedBox(height: 20),
          _animated(
            SosUtilityToggles(
              flashEnabled: _flashEnabled,
              sirenEnabled: _sirenEnabled,
              onFlashToggle: _onFlashToggle,
              onSirenToggle: _onSirenToggle,
            ),
            start: 0.1,
            end: 0.65,
          ),
          const SizedBox(height: 44),
          _animated(
            SosHoldButton(onActivate: _onActivate),
            start: 0.2,
            end: 0.8,
          ),
          const SizedBox(height: 12),
          // Location active pill
          _animated(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.25),
                  width: 0.75,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Location tracking active',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            start: 0.3,
            end: 0.85,
          ),
          const SizedBox(height: 36),
          // Section label
          _animated(
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_rounded,
                    size: 15,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MANAGE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getSecondaryTextColor(),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            start: 0.35,
            end: 0.9,
          ),
          // Manage Contacts card
          _animated(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _contactsPressed = true),
                onTapUp: (_) {
                  setState(() => _contactsPressed = false);
                  setState(() => _currentView = _SosView.contacts);
                },
                onTapCancel: () => setState(() => _contactsPressed = false),
                child: AnimatedScale(
                  scale: _contactsPressed ? 0.97 : 1.0,
                  duration: _contactsPressed
                      ? const Duration(milliseconds: 80)
                      : const Duration(milliseconds: 300),
                  curve: _contactsPressed ? Curves.easeIn : Curves.easeOutBack,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.getCardBackgroundColor(),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.getBorderColor().withOpacity(0.15),
                        width: 0.75,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.15),
                              width: 0.75,
                            ),
                          ),
                          child: const Icon(
                            Icons.people_rounded,
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
                          Icons.chevron_right_rounded,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            start: 0.4,
            end: 1.0,
          ),
          const SizedBox(height: 12),
          // Past Recordings card
          _animated(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _historyPressed = true),
                onTapUp: (_) {
                  setState(() => _historyPressed = false);
                  setState(() => _currentView = _SosView.history);
                },
                onTapCancel: () => setState(() => _historyPressed = false),
                child: AnimatedScale(
                  scale: _historyPressed ? 0.97 : 1.0,
                  duration: _historyPressed
                      ? const Duration(milliseconds: 80)
                      : const Duration(milliseconds: 300),
                  curve: _historyPressed ? Curves.easeIn : Curves.easeOutBack,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.getCardBackgroundColor(),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.getBorderColor().withOpacity(0.15),
                        width: 0.75,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: AppColors.danger.withOpacity(0.12),
                              width: 0.75,
                            ),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            color: AppColors.danger,
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
                          Icons.chevron_right_rounded,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            start: 0.45,
            end: 1.0,
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
