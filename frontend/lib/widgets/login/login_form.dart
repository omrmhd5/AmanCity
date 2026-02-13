import 'package:flutter/material.dart';
import '../custom_text_field.dart';
import '../custom_button.dart';
import '../custom_text.dart';
import '../custom_gesture_detector.dart';
import '../../utils/app_colors.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onLoginPressed;
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
        const CustomText(
          text: 'Welcome Back',
          size: 24,
          weight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        const SizedBox(height: 4),
        const CustomText(
          text: 'Please sign in to continue.',
          size: 13,
          weight: FontWeight.w400,
          color: AppColors.slateGray,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CustomText(
                  text: 'Password',
                  size: 14,
                  weight: FontWeight.w500,
                  color: AppColors.darkText,
                ),
                CustomGestureDetector(
                  onTap: () {
                    // Handle forgot password
                  },
                  enableScale: false,
                  child: const CustomText(
                    text: 'Forgot Password?',
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
        CustomTextField(
          label: '',
          placeholder: '•••••••••',
          prefixIcon: Icons.lock,
          isPassword: true,
          controller: _passwordController,
        ),
        const SizedBox(height: 24),
        // Login Button
        CustomButton(
          text: 'Log In',
          onPressed: widget.onLoginPressed,
          isLoading: widget.isLoading,
          icon: Icons.arrow_forward,
        ),
      ],
    );
  }
}
