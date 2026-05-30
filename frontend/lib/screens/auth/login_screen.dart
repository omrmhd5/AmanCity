import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../utils/navigation_service.dart' as navigation;
import '../../widgets/login/login_header.dart';
import '../../widgets/login/login_form.dart';
import '../../widgets/login/social_login_dialog.dart';
import '../../widgets/login/social_login_section.dart';
import '../../widgets/login/signup_link_section.dart';
import '../../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
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

  void _showSuccess(String message) {
    final ctx = navigation.Navigator.navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green.shade700),
    );
  }

  Future<String?> _promptPhoneNumber(String providerName) async {
    final dialogContext = navigation.Navigator.navigatorKey.currentContext;

    if (dialogContext == null) {
      return null;
    }

    return showDialog<String>(
      context: dialogContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        return SocialLoginDialog(providerName: providerName);
      },
    );
  }

  Future<void> _handleLogin(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithEmail(email, password);
      _showSuccess('Login successful!');
      // _
      //e in main.dart will automatically navigate to HomeScreen
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      AuthService.socialProfileCompletionRequired.value = true;
      final result = await AuthService.instance.signInWithGoogle();
      if (result == null) {
        AuthService.socialProfileCompletionRequired.value = false;
        return;
      }

      if (!result.isNewUser) {
        AuthService.socialProfileCompletionRequired.value = false;
        _showSuccess('Login successful!');
        return;
      }

      if (mounted) setState(() => _isLoading = false);
      final phone = await _promptPhoneNumber('Google');

      if (phone == null || phone.isEmpty) {
        await AuthService.instance.cancelSocialProfileCompletion(
          deleteCurrentUser: true,
        );
        _showError('Phone number is required to finish Google sign-in.');
        return;
      }

      if (mounted) setState(() => _isLoading = true);
      await AuthService.instance.completeSocialProfile(
        user: result.user,
        phone: phone,
        name: result.suggestedName,
      );
      _showSuccess('Login successful!');
    } catch (e) {
      AuthService.socialProfileCompletionRequired.value = false;
      if (e.toString().contains('PlatformException')) {
        _showError('Google sign-in was cancelled.');
      } else {
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() => _isLoading = true);
    try {
      AuthService.socialProfileCompletionRequired.value = true;
      final result = await AuthService.instance.signInWithApple();
      if (result == null) {
        AuthService.socialProfileCompletionRequired.value = false;
        return;
      }

      if (!result.isNewUser) {
        AuthService.socialProfileCompletionRequired.value = false;
        _showSuccess('Login successful!');
        return;
      }

      if (mounted) setState(() => _isLoading = false);
      final phone = await _promptPhoneNumber('Apple');

      if (phone == null || phone.isEmpty) {
        await AuthService.instance.cancelSocialProfileCompletion(
          deleteCurrentUser: true,
        );
        _showError('Phone number is required to finish Apple sign-in.');
        return;
      }

      if (mounted) setState(() => _isLoading = true);
      await AuthService.instance.completeSocialProfile(
        user: result.user,
        phone: phone,
        name: result.suggestedName,
      );
      _showSuccess('Login successful!');
    } catch (e) {
      AuthService.socialProfileCompletionRequired.value = false;
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                _animated(const LoginHeader(), start: 0.0, end: 0.5),
                _animated(
                  LoginForm(
                    onLoginPressed: _handleLogin,
                    isLoading: _isLoading,
                  ),
                  start: 0.1,
                  end: 0.65,
                ),
                _animated(
                  SocialLoginSection(
                    onGooglePressed: _handleGoogleLogin,
                    onApplePressed: _handleAppleLogin,
                  ),
                  start: 0.2,
                  end: 0.75,
                ),
                _animated(SignUpLinkSection(), start: 0.35, end: 0.9),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
