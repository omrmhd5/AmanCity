import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/register/register_header.dart';
import '../widgets/register/personal_identity_section.dart';
import '../widgets/register/terms_checkbox.dart';
import '../widgets/register/register_footer.dart';
import '../widgets/shared/custom_text_field.dart';
import '../utils/app_theme.dart';

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
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
        _passwordController.text.isEmpty) {
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

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signUpWithEmail(
        name: _fullNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      // _AuthGate will automatically navigate to HomeScreen on success
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
            child: Column(
              children: [
                const RegisterHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
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
                          const SizedBox(height: 24),
                          TermsCheckBox(
                            isChecked: _agreeToTerms,
                            onChanged: (bool newValue) {
                              setState(() => _agreeToTerms = newValue);
                            },
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          RegisterFooter(
            onRegisterPressed: _handleRegister,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
