import 'package:flutter/material.dart';
import '../../shared/custom_text_field.dart';
import '../../shared/custom_button.dart';
import '../terms_checkbox.dart';
import '../../../utils/app_theme.dart';

class StepPassword extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool agreeToTerms;
  final ValueChanged<bool> onTermsChanged;
  final VoidCallback onRegister;
  final VoidCallback onBack;
  final bool isLoading;

  const StepPassword({
    Key? key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.agreeToTerms,
    required this.onTermsChanged,
    required this.onRegister,
    required this.onBack,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<StepPassword> createState() => _StepPasswordState();
}

class _StepPasswordState extends State<StepPassword> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Create a password',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use at least 6 characters.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ),
          const SizedBox(height: 36),
          CustomTextField(
            label: 'Password',
            placeholder: '•••••••••',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            controller: widget.passwordController,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Confirm Password',
            placeholder: '•••••••••',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            controller: widget.confirmPasswordController,
          ),
          TermsCheckBox(
            isChecked: widget.agreeToTerms,
            onChanged: widget.onTermsChanged,
          ),
          CustomButton(
            text: 'Create Account',
            onPressed: widget.onRegister,
            isLoading: widget.isLoading,
            icon: Icons.check,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: widget.onBack,
              child: Text(
                '← Back',
                style: TextStyle(
                  color: AppTheme.getSecondaryTextColor(),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
