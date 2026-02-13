import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_text.dart';
import '../widgets/custom_gesture_detector.dart';
import '../utils/app_colors.dart';

enum AccountType { citizen, womenAtRisk }

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

  final List<String> _cities = [
    'Cairo',
    'Alexandria',
    'Giza',
    'Shubra El-Kheima',
    'Port Said',
    'Suez',
    'Luxor',
  ];

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.security,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const CustomText(
                        text: 'User Registration',
                        size: 28,
                        weight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                      const SizedBox(height: 8),
                      const CustomText(
                        text:
                            'Create a secure account to access real-time safety alerts and reporting tools.',
                        size: 13,
                        weight: FontWeight.w400,
                        color: Color(0xFFCBD5E1),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                // Scrollable Form Area
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          // Section 1: Personal Identity
                          _buildSectionDivider('Personal Identity'),
                          const SizedBox(height: 16),
                          // Full Name
                          CustomTextField(
                            label: 'Full Name',
                            placeholder: 'e.g. Layla Ahmed',
                            prefixIcon: Icons.person,
                            controller: _fullNameController,
                          ),
                          const SizedBox(height: 20),
                          // Phone Number
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CustomText(
                                text: 'Phone Number',
                                size: 14,
                                weight: FontWeight.w500,
                                color: AppColors.white,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF162A4D),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF1E3A66),
                                      ),
                                    ),
                                    child: const CustomText(
                                      text: '🇪🇬 +20',
                                      size: 14,
                                      weight: FontWeight.w500,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '100 123 4567',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFF162A4D),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF1E3A66),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF1E3A66),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 16,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const CustomText(
                                text: 'Used for emergency verification only.',
                                size: 10,
                                weight: FontWeight.w400,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Region / City
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CustomText(
                                text: 'Region / City',
                                size: 14,
                                weight: FontWeight.w500,
                                color: AppColors.white,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF1E3A66),
                                  ),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedCity,
                                  hint: Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: CustomText(
                                      text: 'Select your city...',
                                      color: const Color(0xFF94A3B8),
                                      size: 14,
                                    ),
                                  ),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 14,
                                  ),
                                  dropdownColor: const Color(0xFF162A4D),
                                  items: _cities.map((String city) {
                                    return DropdownMenuItem<String>(
                                      value: city,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: Text(city),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedCity = newValue;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Section 2: Account Type
                          _buildSectionDivider('Account Type'),
                          const SizedBox(height: 16),
                          // Citizen Option
                          _buildAccountTypeOption(
                            title: 'Concerned Citizen',
                            description:
                                'Standard access to community reporting and neighborhood alerts.',
                            icon: Icons.public,
                            value: AccountType.citizen,
                          ),
                          const SizedBox(height: 12),
                          // Woman-at-Risk Option
                          _buildAccountTypeOption(
                            title: 'Woman-at-Risk',
                            description:
                                'Enhanced privacy modes, rapid SOS features, and direct support lines.',
                            icon: Icons.verified_user,
                            value: AccountType.womenAtRisk,
                          ),
                          const SizedBox(height: 24),
                          // Terms Checkbox
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (bool? newValue) {
                                    setState(() {
                                      _agreeToTerms = newValue ?? false;
                                    });
                                  },
                                  fillColor: MaterialStateProperty.all(
                                    _agreeToTerms
                                        ? Colors.white
                                        : Colors.transparent,
                                  ),
                                  checkColor: AppColors.primary,
                                  side: BorderSide(
                                    color: _agreeToTerms
                                        ? Colors.white
                                        : const Color(0xFF404A5C),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'I agree to the ',
                                        style: TextStyle(
                                          color: Color(0xFFCBD5E1),
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            // Handle terms tap
                                          },
                                      ),
                                      const TextSpan(
                                        text: ' and ',
                                        style: TextStyle(
                                          color: Color(0xFFCBD5E1),
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            // Handle privacy policy tap
                                          },
                                      ),
                                      const TextSpan(
                                        text: '.',
                                        style: TextStyle(
                                          color: Color(0xFFCBD5E1),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0),
                    AppColors.primary,
                    AppColors.primary,
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                32,
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
                    backgroundColor: AppColors.white,
                    textColor: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CustomText(
                        text: 'Already have an account? ',
                        size: 13,
                        weight: FontWeight.w400,
                        color: Color(0xFFCBD5E1),
                      ),
                      CustomGestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        enableScale: false,
                        child: const CustomText(
                          text: 'Login',
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CustomText(
            text: title,
            size: 11,
            weight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.2)),
        ),
      ],
    );
  }

  Widget _buildAccountTypeOption({
    required String title,
    required String description,
    required IconData icon,
    required AccountType value,
  }) {
    final isSelected = _accountType == value;
    return CustomGestureDetector(
      onTap: () {
        setState(() {
          _accountType = value;
        });
      },
      enableScale: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF162A4D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.3)
                : const Color(0xFF1E3A66),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF94A3B8), width: 2),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    text: description,
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}
