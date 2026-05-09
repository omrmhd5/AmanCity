import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/register/register_header.dart';
import '../widgets/register/register_step_indicator.dart';
import '../widgets/register/steps/step_name.dart';
import '../widgets/register/steps/step_email.dart';
import '../widgets/register/steps/step_phone.dart';
import '../widgets/register/steps/step_password.dart';
import '../widgets/register/steps/step_success.dart';
import '../utils/app_theme.dart';
import '../utils/navigation_service.dart' as navigation;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSuccess = false;
  bool _isLoading = false;

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

  void _goToNext() {
    final next = _currentStep + 1;
    setState(() => _currentStep = next);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    if (_currentStep == 0) {
      navigation.Navigator.goBack();
      return;
    }
    final prev = _currentStep - 1;
    setState(() => _currentStep = prev);
    _pageController.animateToPage(
      prev,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onNextName() {
    if (_fullNameController.text.trim().isEmpty) {
      _showError('Please enter your full name.');
      return;
    }
    _goToNext();
  }

  void _onNextEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address.');
      return;
    }
    _goToNext();
  }

  void _onNextPhone() {
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number.');
      return;
    }
    _goToNext();
  }

  Future<void> _handleRegister() async {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Please enter and confirm your password.');
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
    if (!_agreeToTerms) {
      _showError('Please accept the terms and conditions.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signUpWithEmail(
        name: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isSuccess = true);
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
      body: SafeArea(
        child: _isSuccess
            ? Column(
                children: [
                  RegisterHeader(
                    onBackPressed: () => navigation.Navigator.goBack(),
                  ),
                  Expanded(
                    child: StepSuccess(
                      email: _emailController.text.trim(),
                      onGoToLogin: () => navigation.Navigator.goBack(),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  RegisterHeader(onBackPressed: _goBack),
                  const SizedBox(height: 4),
                  RegisterStepIndicator(currentStep: _currentStep),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        SingleChildScrollView(
                          child: StepName(
                            controller: _fullNameController,
                            onNext: _onNextName,
                          ),
                        ),
                        SingleChildScrollView(
                          child: StepEmail(
                            controller: _emailController,
                            onNext: _onNextEmail,
                            onBack: _goBack,
                          ),
                        ),
                        SingleChildScrollView(
                          child: StepPhone(
                            controller: _phoneController,
                            onNext: _onNextPhone,
                            onBack: _goBack,
                          ),
                        ),
                        StepPassword(
                          passwordController: _passwordController,
                          confirmPasswordController: _confirmPasswordController,
                          agreeToTerms: _agreeToTerms,
                          onTermsChanged: (val) =>
                              setState(() => _agreeToTerms = val),
                          onRegister: _handleRegister,
                          onBack: _goBack,
                          isLoading: _isLoading,
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
