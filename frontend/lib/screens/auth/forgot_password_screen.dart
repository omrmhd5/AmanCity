import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/shared/custom_text_field.dart';
import '../../widgets/shared/custom_button.dart';
import '../../widgets/shared/custom_text.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green.shade700),
    );
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('auth.email_required'.tr()); // Or fallback to hardcoded if not present
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      _showSuccess('auth.reset_email_sent'.tr());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getPrimaryTextColor()),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'auth.forgot_password'.tr(),
                  size: 28,
                  weight: FontWeight.w700,
                  color: AppTheme.getPrimaryTextColor(),
                ),
                const SizedBox(height: 12),
                CustomText(
                  text: 'auth.reset_password_subtitle'.tr(),
                  size: 14,
                  weight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                  height: 1.5,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'auth.email'.tr(),
                  placeholder: 'auth.email_placeholder'.tr(),
                  prefixIcon: Icons.email,
                  controller: _emailController,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'auth.send_reset_link'.tr(),
                  onPressed: _handleResetPassword,
                  isLoading: _isLoading,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
