import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/register/register_header.dart';
import '../../widgets/register/register_step_indicator.dart';
import '../../widgets/register/steps/step_name.dart';
import '../../widgets/register/steps/step_email.dart';
import '../../widgets/register/steps/step_phone.dart';
import '../../widgets/register/steps/step_password.dart';
import '../../widgets/register/steps/step_success.dart';
import '../../utils/app_theme.dart';
import '../../utils/navigation_service.dart' as navigation;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
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
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      _showError('register.error_name_required'.tr());
      return;
    }
    _goToNext();
  }

  void _onNextEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('register.error_email_required'.tr());
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showError('register.error_email_invalid'.tr());
      return;
    }
    _goToNext();
  }

  void _onNextPhone() {
    if (_phoneController.text.trim().isEmpty) {
      _showError('register.error_phone_required'.tr());
      return;
    }
    _goToNext();
  }

  Future<void> _handleRegister() async {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('register.error_password_required'.tr());
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('register.error_password_length'.tr());
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('register.error_password_match'.tr());
      return;
    }
    if (!_agreeToTerms) {
      _showError('register.error_agree_terms'.tr());
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
                  _animated(
                    RegisterHeader(
                      onBackPressed: () => navigation.Navigator.goBack(),
                    ),
                    start: 0.0,
                    end: 0.5,
                  ),
                  Expanded(
                    child: _animated(
                      StepSuccess(
                        email: _emailController.text.trim(),
                        onGoToLogin: () => navigation.Navigator.goBack(),
                      ),
                      start: 0.15,
                      end: 0.75,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _animated(
                    RegisterHeader(onBackPressed: _goBack),
                    start: 0.0,
                    end: 0.5,
                  ),
                  const SizedBox(height: 4),
                  _animated(
                    RegisterStepIndicator(currentStep: _currentStep),
                    start: 0.1,
                    end: 0.6,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _animated(
                      PageView(
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
                            confirmPasswordController:
                                _confirmPasswordController,
                            agreeToTerms: _agreeToTerms,
                            onTermsChanged: (val) =>
                                setState(() => _agreeToTerms = val),
                            onRegister: _handleRegister,
                            onBack: _goBack,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                      start: 0.2,
                      end: 0.8,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
