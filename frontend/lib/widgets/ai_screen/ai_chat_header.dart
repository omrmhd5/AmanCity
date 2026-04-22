import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../shared/custom_text.dart';

class AiChatHeader extends StatelessWidget {
  const AiChatHeader({Key? key}) : super(key: key);

  Future<void> _emergencyCall() async {
    try {
      final Uri launchUri = Uri(scheme: 'tel', path: '122');
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error calling emergency: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor().withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: AppTheme.getBorderColor(), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Avatar + Text
            Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary,
                            Colors.blue[600] ?? Colors.blue,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // Green online dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.getBackgroundColor(),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'Safety Assistant',
                      size: 16,
                      weight: FontWeight.w700,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      text: 'Online',
                      size: 11,
                      weight: FontWeight.w500,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                  ],
                ),
              ],
            ),
            // Emergency button
            GestureDetector(
              onTap: _emergencyCall,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(Icons.phone_in_talk, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
