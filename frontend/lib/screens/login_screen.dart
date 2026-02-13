import 'package:flutter/material.dart';
import '../widgets/login/login_header.dart';
import '../widgets/login/login_form.dart';
import '../widgets/login/social_login_section.dart';
import '../widgets/login/signup_link_section.dart';
import '../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful!')));
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
                    const LoginHeader(),
                    // Login Form Section
                    LoginForm(
                      onLoginPressed: _handleLogin,
                      isLoading: _isLoading,
                    ),
                    // Social Login Section
                    SocialLoginSection(
                      onGooglePressed: () {
                        // Handle Google login
                      },
                      onApplePressed: () {
                        // Handle Apple login
                      },
                    ),
                    // Sign Up Link Section
                    SignUpLinkSection(
                      onSignUpPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                    ),
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
