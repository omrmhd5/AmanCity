import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_colors.dart';
import '../services/connectivity_service.dart';
import '../main.dart';

// ─── Permission item model ────────────────────────────────────────────────────

class _PermItem {
  final String title;
  final String reason;
  final IconData icon;
  final Permission permission;
  final bool required;

  const _PermItem({
    required this.title,
    required this.reason,
    required this.icon,
    required this.permission,
    required this.required,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  // ── Static permission list ──
  static const _items = [
    _PermItem(
      title: 'Location',
      reason:
          'Provides real-time proximity alerts and pinpoints your location during emergencies.',
      icon: Icons.location_on_outlined,
      permission: Permission.locationWhenInUse,
      required: true,
    ),
    _PermItem(
      title: 'Camera',
      reason:
          'Captures photos and video evidence when reporting incidents or during SOS.',
      icon: Icons.camera_alt_outlined,
      permission: Permission.camera,
      required: true,
    ),
    _PermItem(
      title: 'Microphone',
      reason:
          'Records audio evidence during SOS emergencies for documentation.',
      icon: Icons.mic_outlined,
      permission: Permission.microphone,
      required: true,
    ),
    _PermItem(
      title: 'Phone',
      reason:
          'Allows the app to make emergency calls and access your contacts for SOS alerts.',
      icon: Icons.phone_outlined,
      permission: Permission.phone,
      required: true,
    ),
    _PermItem(
      title: 'Photos & Videos',
      reason:
          'Lets you attach media from your gallery when reporting incidents.',
      icon: Icons.photo_library_outlined,
      permission: Permission.photos,
      required: true,
    ),
    _PermItem(
      title: 'Notifications',
      reason: 'Sends critical safety alerts and incident updates in your area.',
      icon: Icons.notifications_outlined,
      permission: Permission.notification,
      required: true,
    ),
  ];

  // ── State ──
  int _step = 0; // which permission is currently active
  int _deniedAtStep = -1; // index that was just denied (show hint)
  bool _isRequesting = false;
  bool _checking = true; // true while we auto-check existing permissions

  bool get _isDone => _step >= _items.length;

  @override
  void initState() {
    super.initState();
    // Bypass connectivity checks — permissions screen doesn't need the backend.
    ConnectivityService.instance.setBypass(true);
    _checkExistingPermissions();
  }

  Future<void> _checkExistingPermissions() async {
    for (int i = 0; i < _items.length; i++) {
      final status = await _items[i].permission.status;
      if (status.isGranted || status.isLimited) {
        _step++;
      } else {
        break; // stop at first ungranted permission (all are required)
      }
    }
    if (mounted) {
      setState(() => _checking = false);
      // All already granted — go straight to auth
      if (_isDone) _finish();
    }
  }

  // ── Actions ──

  Future<void> _request(int index) async {
    setState(() {
      _isRequesting = true;
      _deniedAtStep = -1;
    });
    final status = await _items[index].permission.request();
    setState(() => _isRequesting = false);

    if (status.isGranted || status.isLimited) {
      setState(() => _step++);
    } else if (status.isPermanentlyDenied) {
      await _showSettingsDialog(_items[index].title);
    } else {
      // Denied but can re-request — show inline hint
      setState(() => _deniedAtStep = index);
    }
  }

  Future<void> _showSettingsDialog(String permName) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2742),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$permName Required',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '$permName is required for core safety features. Please enable it in your app settings.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    // Re-enable connectivity checks now that we're entering the main app.
    ConnectivityService.instance.setBypass(false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Access',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Authorize the following permissions to enable full safety functionality.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.52),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Permission cards ────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  children: List.generate(_items.length, (i) {
                    final isDone = i < _step;
                    final isActive = i == _step;
                    final isUpcoming = i > _step;
                    return _PermCard(
                      item: _items[i],
                      isDone: isDone,
                      isActive: isActive,
                      isUpcoming: isUpcoming,
                      isLoading: _isRequesting && isActive,
                      showDeniedHint: _deniedAtStep == i && isActive,
                      onAllow: () => _request(i),
                      onSkip: null, // all required
                    );
                  }),
                ),
              ),
            ),

            // ── Continue button ─────────────────────────────────
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isDone ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isDone ? _finish : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Trust signal ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 13,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SECURE  •  PRIVATE  •  VERIFIED ACCESS',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      color: Colors.white.withOpacity(0.3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Permission card ──────────────────────────────────────────────────────────

class _PermCard extends StatelessWidget {
  final _PermItem item;
  final bool isDone;
  final bool isActive;
  final bool isUpcoming;
  final bool isLoading;
  final bool showDeniedHint;
  final VoidCallback onAllow;
  final VoidCallback? onSkip;

  const _PermCard({
    required this.item,
    required this.isDone,
    required this.isActive,
    required this.isUpcoming,
    required this.isLoading,
    required this.showDeniedHint,
    required this.onAllow,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUpcoming ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDone
              ? const Color(0xFF112B25)
              : isActive
              ? const Color(0xFF112244)
              : const Color(0xFF0D1B30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? AppColors.secondary
                : isActive
                ? const Color(0xFF3B82F6)
                : const Color(0xFF1E3260),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header row ──────────────────────────────
              Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.secondary.withOpacity(0.25)
                          : const Color(0xFF3B82F6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDone ? Icons.check_circle_rounded : item.icon,
                      color: isDone
                          ? AppColors.secondary
                          : const Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: isDone ? Colors.white70 : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Badge
                  if (!isDone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'Required',
                        style: TextStyle(
                          color: Color(0xFFFF8A80),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Granted ✓',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),

              // ── Active: reason + button ─────────────────
              if (isActive) ...[
                const SizedBox(height: 12),
                Text(
                  item.reason,
                  style: const TextStyle(
                    color: Color(0xFF90A4BE),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                // Denied warning
                if (showDeniedHint) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 15,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Permission denied. Tap again to allow — this is required.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Allow button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onAllow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Allow ${item.title}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
