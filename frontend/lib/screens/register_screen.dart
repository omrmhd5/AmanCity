import 'package:flutter/material.dart';
import '../widgets/register/register_header.dart';
import '../widgets/register/personal_identity_section.dart';
import '../widgets/register/account_type_selector.dart';
import '../widgets/register/terms_checkbox.dart';
import '../widgets/register/register_footer.dart';
import '../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  String? _selectedCity;
  AccountType _accountType = AccountType.citizen;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_fullNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedCity == null ||
        !_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and accept terms'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate registration delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration successful!')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.95),
                ],
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header Section
                const RegisterHeader(),
                // Scrollable Form Area
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // Personal Identity Section
                          PersonalIdentitySection(
                            fullNameController: _fullNameController,
                            phoneController: _phoneController,
                            selectedCity: _selectedCity,
                            onCityChanged: (String? newValue) {
                              setState(() {
                                _selectedCity = newValue;
                              });
                            },
                          ),
                          // Account Type Section
                          AccountTypeSelector(
                            selectedType: _accountType,
                            onTypeChanged: (AccountType newType) {
                              setState(() {
                                _accountType = newType;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          // Terms Checkbox
                          TermsCheckBox(
                            isChecked: _agreeToTerms,
                            onChanged: (bool newValue) {
                              setState(() {
                                _agreeToTerms = newValue;
                              });
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
          // Sticky Footer
          RegisterFooter(
            onRegisterPressed: _handleRegister,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
