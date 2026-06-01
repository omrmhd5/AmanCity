import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../shared/custom_text_field.dart';
import '../shared/custom_button.dart';
import '../shared/custom_text.dart';
import '../shared/custom_gesture_detector.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class LoginForm extends StatefulWidget {
  final void Function(String email, String password) onLoginPressed;
  final bool isLoading;

  const LoginForm({
    Key? key,
    required this.onLoginPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late TextEditingController _identityController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _identityController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome message
        CustomText(
          text: 'auth.welcome_back'.tr(),
          size: 24,
          weight: FontWeight.w600,
          color: AppTheme.getPrimaryTextColor(),
        ),
        const SizedBox(height: 4),
        CustomText(
          text: 'auth.sign_in_to_continue'.tr(),
          size: 13,
          weight: FontWeight.w400,
          color: AppTheme.getSecondaryTextColor(),
        ),
        const SizedBox(height: 24),
        // Email Input
        CustomTextField(
          label: 'auth.email'.tr(),
          placeholder: 'auth.email_placeholder'.tr(),
          prefixIcon: Icons.email,
          controller: _identityController,
        ),
        const SizedBox(height: 20),
        // Password Input
        CustomTextField(
          label: 'auth.password'.tr(),
          placeholder: 'auth.password_placeholder'.tr(),
          prefixIcon: Icons.lock,
          isPassword: true,
          controller: _passwordController,
        ),
        const SizedBox(height: 12),
        CustomGestureDetector(
          onTap: () {
            // Handle forgot password
          },
          enableScale: false,
          child: Align(
            alignment: Alignment.centerRight,
            child: CustomText(
              text: 'auth.forgot_password'.tr(),
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.secondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Login Button
        CustomButton(
          text: 'auth.log_in'.tr(),
          onPressed: () => widget.onLoginPressed(
            _identityController.text.trim(),
            _passwordController.text,
          ),
          isLoading: widget.isLoading,
          icon: Icons.arrow_forward,
        ),
      ],
    );
  }
}
