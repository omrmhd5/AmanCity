import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class SocialLoginDialog extends StatefulWidget {
  final String providerName;

  const SocialLoginDialog({Key? key, required this.providerName})
    : super(key: key);

  @override
  State<SocialLoginDialog> createState() => _SocialLoginDialogState();
}

class _SocialLoginDialogState extends State<SocialLoginDialog> {
  late final TextEditingController _phoneController;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.currentMode == AppThemeMode.dark
                      ? AppColors.primary.withOpacity(0.85)
                      : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.getBorderColor(),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'auth.complete_signin'.tr(
                        namedArgs: {'provider': widget.providerName},
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'auth.enter_phone_to_finish'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.getCardBackgroundColor(),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.getBorderColor(),
                            ),
                          ),
                          child: Text(
                            '🇪🇬 +20',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.getPrimaryTextColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            autofocus: true,
                            style: TextStyle(
                              color: AppTheme.getPrimaryTextColor(),
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'auth.enter_phone_hint'.tr(),
                              hintStyle: TextStyle(
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                              errorText: _validationError,
                              filled: true,
                              fillColor: AppTheme.getCardBackgroundColor(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppTheme.getBorderColor(),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppTheme.getBorderColor(),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.secondary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: AppTheme.getBorderColor(),
                                ),
                              ),
                            ),
                            child: Text(
                              'common.cancel'.tr(),
                              style: TextStyle(
                                color: AppTheme.getSecondaryTextColor(),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final phone = _phoneController.text.trim();
                              if (phone.isEmpty) {
                                setState(() {
                                  _validationError = 'auth.phone_required'.tr();
                                });
                                return;
                              }
                              // Prepend +20 if not already present
                              final fullPhone = phone.startsWith('+20')
                                  ? phone
                                  : '+20$phone';
                              Navigator.of(context).pop(fullPhone);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'common.continue_btn'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
