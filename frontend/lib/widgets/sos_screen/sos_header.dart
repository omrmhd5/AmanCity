import 'dart:ui';
import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class SosHeader extends StatelessWidget {
  final VoidCallback? onBackPressed;

  SosHeader({Key? key, this.onBackPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button or placeholder
              SizedBox(
                width: 48,
                child: onBackPressed != null
                    ? IconButton(
                        onPressed: onBackPressed,
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: AppTheme.getPrimaryTextColor(),
                          size: 25,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      )
                    : const SizedBox(),
              ),
              // Centered content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Glass icon container with glow
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.danger.withOpacity(0.28),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.danger.withOpacity(0.18),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sos_rounded,
                            color: AppColors.danger,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Emergency SOS',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getPrimaryTextColor(),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hold the button for 3 seconds to alert your trusted contacts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.getSecondaryTextColor().withOpacity(
                          0.85,
                        ),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              // Balance spacer
              const SizedBox(width: 48),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.0),
                  AppColors.secondary.withOpacity(0.25),
                  AppColors.secondary.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
