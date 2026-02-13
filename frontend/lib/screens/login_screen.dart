import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_text.dart';
import '../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _identityController;
  late TextEditingController _passwordController;
  bool _isLoading = false;

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

  void _handleLogin() {
    setState(() {
      _isLoading = true;
    });
    // Simulate login delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      // Navigate or handle login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          // Background gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Header Section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Column(
                        children: [
                          // Shield Icon
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shield,
                              color: AppColors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // App Title
                          const CustomText(
                            text: 'AmanCity',
                            size: 32,
                            weight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          // Tagline
                          const CustomText(
                            text: 'Your Safety, Our Priority.',
                            size: 13,
                            weight: FontWeight.w500,
                            color: AppColors.slateGray,
                          ),
                        ],
                      ),
                    ),
                    // Login Form Section
                    Column(
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
                                GestureDetector(
                                  onTap: () {
                                    // Handle forgot password
                                  },
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
                          onPressed: _handleLogin,
                          isLoading: _isLoading,
                          icon: Icons.arrow_forward,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.softGray,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: CustomText(
                            text: 'Or continue with',
                            size: 12,
                            weight: FontWeight.w400,
                            color: AppColors.slateGray,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.softGray,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Social Login Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Handle Google login
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.softGray,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: AppColors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.language,
                                    color: AppColors.darkText,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const CustomText(
                                    text: 'Google',
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: AppColors.darkText,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Handle Apple login
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.softGray,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: AppColors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.apple,
                                    color: AppColors.darkText,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const CustomText(
                                    text: 'Apple',
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: AppColors.darkText,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CustomText(
                          text: "Don't have an account? ",
                          size: 13,
                          weight: FontWeight.w400,
                          color: AppColors.slateGray,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const CustomText(
                            text: 'Sign Up',
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
