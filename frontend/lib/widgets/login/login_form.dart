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
          text: 'Welcome Back',
          size: 24,
          weight: FontWeight.w600,
          color: AppTheme.getPrimaryTextColor(),
        ),
        const SizedBox(height: 4),
        CustomText(
          text: 'Please sign in to continue.',
          size: 13,
          weight: FontWeight.w400,
          color: AppTheme.getSecondaryTextColor(),
        ),
        const SizedBox(height: 24),
        // Phone/Email Input
        CustomTextField(
          label: 'Phone Number or Email',
          placeholder: '+20 123 456 7890',
          prefixIcon: Icons.person,
          controller: _identityController,
        ),
        const SizedBox(height: 20),
        // Password Input
        CustomTextField(
          label: 'Password',
          placeholder: '•••••••••',
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
          child: const Align(
            alignment: Alignment.centerRight,
            child: CustomText(
              text: 'Forgot Password?',
              size: 13,
              weight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Login Button
        CustomButton(
          text: 'Log In',
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
