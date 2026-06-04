import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _exitController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  late Animation<double> _exitScaleAnimation;
  late Animation<double> _exitOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Entry animation: Fade-in and scale-up with elastic bounce
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    // 2. Subtle continuous breathing pulse for the logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 3. Exit animation: Dynamic surprise zoom scaling logo to cover screen
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 20.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.fastOutSlowIn),
    );

    _exitOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );

    // Start entry animations and loop pulse
    _fadeController.forward().then((_) {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });

    // Start exit transition after 3.1 seconds, then invoke onFinished
    Future.delayed(const Duration(milliseconds: 3100), () {
      if (mounted) {
        _pulseController.stop();
        _exitController.forward().then((_) {
          widget.onFinished();
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.currentMode == AppThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.lightBackground,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _fadeController,
          _pulseController,
          _exitController,
        ]),
        builder: (context, child) {
          // Calculate compound opacity and scale
          double logoOpacity = _fadeAnimation.value;
          double logoScale = _scaleAnimation.value * _pulseAnimation.value;
          double bgOpacity = 1.0;

          if (_exitController.isAnimating || _exitController.isCompleted) {
            logoOpacity *= _exitOpacityAnimation.value;
            logoScale *= _exitScaleAnimation.value;
            bgOpacity *= _exitOpacityAnimation.value;
          }

          return Stack(
            children: [
              // Background Image with gradient fallback + Theme Overlay
              Opacity(
                opacity: bgOpacity,
                child: Stack(
                  children: [
                    // Fallback theme gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.3,
                          colors: isDark
                              ? const [
                                  Color(0xFF132D54), // Dark glow center
                                  AppColors.primary,
                                ]
                              : const [
                                  Color(0xFFDCEBFF), // Light glow center
                                  AppColors.lightBackground,
                                ],
                        ),
                      ),
                    ),

                    // Background image with localized overlay on success
                    Image.asset(
                      'assets/images/Splash_Bg.webp',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (frame == null) return child;
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                child,
                                // Overlaid container to match light/dark theme brightness
                                Container(
                                  color: isDark
                                      ? AppColors.primary.withOpacity(0.50)
                                      : AppColors.lightGray.withOpacity(0.5),
                                ),
                              ],
                            );
                          },
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink(); // fallback to base gradient
                      },
                    ),
                  ],
                ),
              ),

              // Central content (Logo + Title + Subtitle)
              Center(
                child: Opacity(
                  opacity: logoOpacity,
                  child: Transform.scale(
                    scale: logoScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo container with dynamic theme-sensitive glow
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(
                                  (isDark ? 0.18 : 0.12) * _fadeAnimation.value,
                                ),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(65),
                            child: Image.asset(
                              'assets/logos/AmanCity_Logo_Only.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // App Brand Text
                        Text(
                          'AmanCity',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.darkText,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle with tracking
                        const Text(
                          'CITY SAFETY & INTELLIGENCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                            letterSpacing: 4.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Minimalist premium spinner at the bottom
              Positioned(
                bottom: 70,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: bgOpacity * _fadeAnimation.value,
                    child: PremiumSpinner(isDark: isDark),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Premium custom spinner ──────────────────────────────────────────────────

class PremiumSpinner extends StatefulWidget {
  final bool isDark;

  const PremiumSpinner({super.key, required this.isDark});

  @override
  State<PremiumSpinner> createState() => _PremiumSpinnerState();
}

class _PremiumSpinnerState extends State<PremiumSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spinnerController,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer subtle tracker track ring
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary.withOpacity(
                  widget.isDark ? 0.08 : 0.15,
                ),
                width: 2.5,
              ),
            ),
          ),

          // Outer spinning cyan/teal arc
          const SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              strokeWidth: 3.0,
              value: 0.3, // 30% arc
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
              backgroundColor: Colors.transparent,
            ),
          ),

          // Inner counter-spinning arc
          RotationTransition(
            turns: Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(_spinnerController),
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                value: 0.25, // 25% arc
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isDark
                      ? Colors.white60
                      : AppColors.primary.withOpacity(0.5),
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
