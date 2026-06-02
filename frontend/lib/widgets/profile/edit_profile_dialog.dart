import 'dart:convert';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../utils/app_theme.dart';
import 'edit_profile/widgets/edit_profile_header.dart';
import 'edit_profile/widgets/edit_profile_form.dart';
import 'edit_profile/widgets/edit_profile_actions.dart';

/// Shows a glassmorphism-styled bottom-sheet dialog for editing name & phone.
Future<bool> showEditProfileDialog(
  BuildContext context, {
  required User user,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditProfileSheet(user: user),
  );
  return result == true;
}

class _EditProfileSheet extends StatefulWidget {
  final User user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _nameCtrl = TextEditingController(text: widget.user.displayName ?? '');
    _phoneCtrl = TextEditingController();
    _loadCurrentPhone();
  }

  /// Pre-fill phone from the backend /me endpoint.
  Future<void> _loadCurrentPhone() async {
    try {
      final token = await widget.user.getIdToken();
      final res = await http
          .get(
            Uri.parse('${AppConfig.backendUrl}/users/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted && data['phone'] != null) {
          _phoneCtrl.text = data['phone'] as String;
        }
      }
    } catch (_) {
      // Non-fatal — user can type manually
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'profile.edit.error_name_empty'.tr());
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = 'profile.edit.error_phone_empty'.tr());
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await widget.user.getIdToken(true);
      final res = await http
          .put(
            Uri.parse('${AppConfig.backendUrl}/users/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'name': name, 'phone': phone}),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Reload Firebase user so displayName updates immediately in the UI
        await widget.user.reload();
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final data = jsonDecode(res.body) as Map<String, dynamic>?;
        setState(
          () => _error =
              data?['message']?.toString() ?? 'profile.edit.error_generic'.tr(),
        );
      }
    } catch (e) {
      setState(() => _error = 'profile.edit.error_generic'.tr());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _anim,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: ClipRRect(
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
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EditProfileHeader(),
                        const SizedBox(height: 28),
                        EditProfileForm(
                          nameController: _nameCtrl,
                          phoneController: _phoneCtrl,
                          isLoading: _loading,
                          error: _error,
                        ),
                        const SizedBox(height: 28),
                        EditProfileActions(
                          isLoading: _loading,
                          onCancel: () {
                            if (!_loading) Navigator.of(context).pop(false);
                          },
                          onSave: _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
