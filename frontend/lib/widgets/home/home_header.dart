import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../screens/alerts/alerts_screen.dart';
import '../../services/notifications/notification_service.dart';
import '../../utils/app_theme.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({Key? key}) : super(key: key);

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    _pulseController.dispose();
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Logo
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/logos/AmanCity_Logo_Only.png',
            width: 42,
            height: 42,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        // Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.getPrimaryTextColor(),
                ),
              ),
            ],
          ),
        ),
        // Bell icon with badge
        ValueListenableBuilder<int>(
          valueListenable: NotificationService.instance.unreadCount,
          builder: (context, count, _) {
            return GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) {
                setState(() => _pressed = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                );
              },
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedScale(
                scale: _pressed ? 0.95 : 1.0,
                duration: _pressed
                    ? const Duration(milliseconds: 80)
                    : const Duration(milliseconds: 300),
                curve: _pressed ? Curves.easeIn : Curves.easeOutBack,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Button container
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppTheme.getBackgroundColor().withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.getBorderColor(),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: count > 0
                          ? AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) {
                                return Transform.scale(
                                  scale:
                                      1.0 +
                                      (Curves.easeInOut.transform(
                                            _pulseController.value,
                                          ) *
                                          0.15),
                                  child: Icon(
                                    Icons.notifications_active_rounded,
                                    color: AppColors.secondary,
                                    size: 24,
                                  ),
                                );
                              },
                            )
                          : Icon(
                              Icons.notifications_outlined,
                              color: AppTheme.getSecondaryTextColor(),
                              size: 24,
                            ),
                    ),
                    // Enhanced badge with shadow
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.danger.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
