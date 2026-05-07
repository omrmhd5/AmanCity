import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/register/register_header.dart';
import '../widgets/register/personal_identity_section.dart';
import '../widgets/register/terms_checkbox.dart';
import '../widgets/shared/custom_button.dart';
import '../widgets/shared/custom_text.dart';
import '../widgets/shared/custom_gesture_detector.dart';
import '../widgets/shared/custom_text_field.dart';
import '../utils/app_theme.dart';
import '../data/app_colors.dart';
import '../utils/navigation_service.dart' as navigation;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _handleRegister() async {
    if (_fullNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (!_agreeToTerms) {
      _showError('Please accept the terms and conditions.');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signUpWithEmail(
        name: _fullNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Account created! A verification link has been sent to your email. Please verify before logging in.',
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
      navigation.Navigator.goBack();
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.getBackgroundColor(),
                  AppTheme.getBackgroundColor().withOpacity(0.95),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const RegisterHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        PersonalIdentitySection(
                          fullNameController: _fullNameController,
                          phoneController: _phoneController,
                          selectedCity: null,
                          onCityChanged: (_) {},
                        ),
                        const SizedBox(height: 20),
                        // Email field
                        CustomTextField(
                          label: 'Email',
                          placeholder: 'example@email.com',
                          prefixIcon: Icons.email_outlined,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 20),
                        // Password field
                        CustomTextField(
                          label: 'Password',
                          placeholder: '•••••••••',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 20),
                        // Confirm Password field
                        CustomTextField(
                          label: 'Confirm Password',
                          placeholder: '•••••••••',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          controller: _confirmPasswordController,
                        ),
                        const SizedBox(height: 24),
                        TermsCheckBox(
                          isChecked: _agreeToTerms,
                          onChanged: (bool newValue) {
                            setState(() => _agreeToTerms = newValue);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  // Register footer as scrollable content
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      16,
                      24,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomButton(
                          text: 'REGISTER ACCOUNT',
                          onPressed: _handleRegister,
                          isLoading: _isLoading,
                          backgroundColor:
                              AppTheme.currentMode == AppThemeMode.dark
                              ? AppColors.secondary
                              : AppColors.primary,
                          textColor: AppColors.white,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              text: 'Already have an account? ',
                              size: 13,
                              weight: FontWeight.w400,
                              color: AppTheme.getSecondaryTextColor(),
                            ),
                            CustomGestureDetector(
                              onTap: () {
                                navigation.Navigator.goBack();
                              },
                              enableScale: false,
                              child: CustomText(
                                text: 'Login',
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppTheme.currentMode == AppThemeMode.dark
                                    ? AppColors.secondary
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
