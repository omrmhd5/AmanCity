import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../data/app_colors.dart';
import '../../../shared/custom_text_field.dart';

class EditProfileForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool isLoading;
  final String? error;

  const EditProfileForm({
    Key? key,
    required this.nameController,
    required this.phoneController,
    required this.isLoading,
    this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        CustomTextField(
          controller: nameController,
          label: 'profile.edit.name_label'.tr(),
          placeholder: 'profile.edit.name_hint'.tr(),
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          enabled: !isLoading,
        ),
        const SizedBox(height: 20),

        // Phone field
        CustomTextField(
          controller: phoneController,
          label: 'profile.edit.phone_label'.tr(),
          placeholder: 'profile.edit.phone_hint'.tr(),
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            LengthLimitingTextInputFormatter(20),
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
          ],
          enabled: !isLoading,
        ),

        // Error message
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: error != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
