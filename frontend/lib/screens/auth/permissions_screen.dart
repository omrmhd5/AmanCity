import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../services/core/connectivity_service.dart';
import '../../main.dart';

// ─── Permission item model ────────────────────────────────────────────────────

class _PermItem {
  final String title;
  final String reason;
  final IconData icon;
  final Permission permission;
  final Permission? fallbackPermission; // For older Android versions
  final bool required;

  const _PermItem({
    required this.title,
    required this.reason,
    required this.icon,
    required this.permission,
    this.fallbackPermission,
    required this.required,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with SingleTickerProviderStateMixin {
  // ── Static permission list ──
  List<_PermItem> get _items => [
    _PermItem(
      title: 'permissions.location'.tr(),
      reason: 'permissions.location_reason'.tr(),
      icon: Icons.location_on_outlined,
      permission: Permission.locationWhenInUse,
      required: true,
    ),
    _PermItem(
      title: 'permissions.camera'.tr(),
      reason: 'permissions.camera_reason'.tr(),
      icon: Icons.camera_alt_outlined,
      permission: Permission.camera,
      required: true,
    ),
    _PermItem(
      title: 'permissions.microphone'.tr(),
      reason: 'permissions.microphone_reason'.tr(),
      icon: Icons.mic_outlined,
      permission: Permission.microphone,
      required: true,
    ),
    _PermItem(
      title: 'permissions.photos_videos'.tr(),
      reason: 'permissions.photos_reason'.tr(),
      icon: Icons.photo_library_outlined,
      permission: Permission.photos,
      fallbackPermission: Permission.storage,
      required: true,
    ),
    _PermItem(
      title: 'permissions.notifications'.tr(),
      reason: 'permissions.notifications_reason'.tr(),
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
  late AnimationController _entryController;

  bool get _isDone => _step >= _items.length;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    // Bypass connectivity checks — permissions screen doesn't need the backend.
    ConnectivityService.instance.setBypass(true);
    AppTheme.themeNotifier.addListener(_onThemeChange);
    _checkExistingPermissions();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entryController.dispose();
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    super.dispose();
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

  Future<void> _checkExistingPermissions() async {
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      var status = await item.permission.status;

      // If primary not granted, check fallback for older Android
      if (!status.isGranted &&
          !status.isLimited &&
          item.fallbackPermission != null) {
        status = await item.fallbackPermission!.status;
      }

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

    final item = _items[index];
    PermissionStatus status = await item.permission.request();

    // If primary permission failed on older Android, try fallback (storage)
    if (!status.isGranted &&
        !status.isLimited &&
        item.fallbackPermission != null) {
      status = await item.fallbackPermission!.request();
    }

    setState(() => _isRequesting = false);

    if (status.isGranted || status.isLimited) {
      setState(() => _step++);
    } else if (status.isPermanentlyDenied) {
      await _showSettingsDialog(item.title);
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
        backgroundColor: AppTheme.getCardBackgroundColor(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'permissions.required_dialog_title'.tr(namedArgs: {'name': permName}),
          style: TextStyle(
            color: AppTheme.getPrimaryTextColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'permissions.required_dialog_body'.tr(namedArgs: {'name': permName}),
          style: TextStyle(
            color: AppTheme.getSecondaryTextColor(),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: AppTheme.getSecondaryTextColor()),
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
            child: Text('permissions.open_settings'.tr()),
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
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            _animated(
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'permissions.system_access'.tr(),
                      style: TextStyle(
                        color: AppTheme.getPrimaryTextColor(),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'permissions.authorize_subtitle'.tr(),
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              start: 0.0,
              end: 0.5,
            ),

            // ── Permission cards ────────────────────────────────
            Expanded(
              child: _animated(
                SingleChildScrollView(
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
                start: 0.1,
                end: 0.7,
              ),
            ),

            // ── Continue button ─────────────────────────────────
            Visibility(
              visible: _isDone,
              child: _animated(
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'common.continue_btn'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                start: 0.25,
                end: 0.8,
              ),
            ),

            // ── Trust signal ────────────────────────────────────
            _animated(
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 13,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SECURE  •  PRIVATE  •  VERIFIED ACCESS',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        color: AppTheme.getSecondaryTextColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              start: 0.3,
              end: 0.85,
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
              ? (AppTheme.currentMode == AppThemeMode.dark
                    ? const Color(0xFF112B25)
                    : AppColors.secondary.withOpacity(0.08))
              : isActive
              ? (AppTheme.currentMode == AppThemeMode.dark
                    ? const Color(0xFF112244)
                    : const Color(0xFF3B82F6).withOpacity(0.08))
              : (AppTheme.currentMode == AppThemeMode.dark
                    ? const Color(0xFF0D1B30)
                    : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? AppColors.secondary
                : isActive
                ? const Color(0xFF3B82F6)
                : AppTheme.getBorderColor(),
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
                        color: isDone
                            ? AppTheme.getSecondaryTextColor()
                            : AppTheme.getPrimaryTextColor(),
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
                      child: Text(
                        'permissions.required'.tr(),
                        style: const TextStyle(
                          color: Color(0xFFFF8A80),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      'permissions.granted'.tr(),
                      style: const TextStyle(
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
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(),
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
