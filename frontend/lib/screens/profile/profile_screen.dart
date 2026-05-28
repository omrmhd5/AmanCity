import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/profile/profile_card.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_menu_section.dart';

class ProfileScreen extends StatefulWidget {
  final ValueNotifier<int>? activationSignal;

  const ProfileScreen({Key? key, this.activationSignal}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    widget.activationSignal?.addListener(_onActivation);
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.activationSignal?.removeListener(_onActivation);
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    _entryController.dispose();
    super.dispose();
  }

  void _onActivation() {
    _entryController.forward(from: 0);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: AuthService.instance.authStateChanges,
          builder: (context, snapshot) {
            final user = snapshot.data;
            return ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _animated(ProfileHeader(user: user), start: 0.0, end: 0.5),
                _animated(ProfileCard(user: user), start: 0.1, end: 0.6),
                _animated(const ProfileMenuSection(), start: 0.25, end: 0.75),
                _animated(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 32.0),
                    child: Center(
                      child: Text(
                        'Version 1.0.0 • Build 1',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                      ),
                    ),
                  ),
                  start: 0.45,
                  end: 0.95,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
