import 'package:flutter/material.dart';
import '../shared/custom_text.dart';
import '../../utils/app_theme.dart';

class RegisterHeader extends StatelessWidget {
  final VoidCallback? onBackPressed;

  const RegisterHeader({Key? key, this.onBackPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBackPressed != null)
                IconButton(
                  onPressed: onBackPressed,
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppTheme.getPrimaryTextColor(),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/logos/AmanCity_Logo_Only.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 0, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'User Registration',
                  size: 28,
                  weight: FontWeight.w700,
                  color: AppTheme.getPrimaryTextColor(),
                ),
                const SizedBox(height: 8),
                CustomText(
                  text:
                      'Create a secure account to access real-time safety alerts and reporting tools.',
                  size: 13,
                  weight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
