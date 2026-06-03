import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
import '../shared/custom_text.dart';

class AiChatHeader extends StatefulWidget {
  final Function(String)? onLanguageChanged;

  const AiChatHeader({Key? key, this.onLanguageChanged}) : super(key: key);

  @override
  State<AiChatHeader> createState() => _AiChatHeaderState();
}

class _AiChatHeaderState extends State<AiChatHeader> {
  late String _selectedLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLanguage = context.locale.languageCode == 'ar' ? 'ar_SA' : 'en_US';
  }

  Future<void> _emergencyCall() async {
    try {
      final Uri launchUri = Uri(scheme: 'tel', path: '122');
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
                          text: 'ai.safety_assistant'.tr(),
                          size: 16,
                          weight: FontWeight.w700,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                        const SizedBox(height: 2),
                        CustomText(
                          text: 'common.online'.tr(),
                          size: 11,
                          weight: FontWeight.w500,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                      ],
                    ),
                  ],
                ),
                // Language selector + Emergency button
                Row(
                  children: [
                    // Language selector
                    PopupMenuButton<String>(
                      initialValue: _selectedLanguage,
                      onSelected: (language) {
                        setState(() => _selectedLanguage = language);
                        widget.onLanguageChanged?.call(language);
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'en_US',
                          child: Text('🇺🇸 English'),
                        ),
                        const PopupMenuItem(
                          value: 'ar_SA',
                          child: Text('🇪🇬 العربية'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.secondary.withOpacity(0.30),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedLanguage == 'en_US' ? '🇺🇸' : '🇪🇬',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _selectedLanguage == 'en_US' ? 'EN' : 'AR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        child: Icon(
                          Icons.phone_in_talk,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Gradient divider
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.0),
                AppColors.secondary.withOpacity(0.3),
                AppColors.secondary.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
