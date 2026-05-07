import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class ProfileCard extends StatelessWidget {
  final User? user;

  const ProfileCard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // User Info Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.getCardBackgroundColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.getBorderColor(), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Avatar Circle with Status Dot
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary.withOpacity(0.15),
                          border: Border.all(
                            color: AppColors.secondary,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 44,
                          color: AppColors.secondary,
                        ),
                      ),
                      // Green Status Indicator Dot
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                            border: Border.all(
                              color: AppTheme.getCardBackgroundColor(),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // User Name
                  Text(
                    user?.displayName ?? 'User',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // User Email
                  if (user?.email != null)
                    Text(
                      user!.email!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cairo, Egypt',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                      ),
                    ],
                  ),

                  // Verified Guardian Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Verified Guardian',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
