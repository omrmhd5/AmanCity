import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../shared/custom_button.dart';

class EditProfileActions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const EditProfileActions({
    Key? key,
    required this.isLoading,
    required this.onCancel,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cancel
        Expanded(
          child: CustomButton(
            text: 'common.cancel'.tr(),
            type: ButtonType.tertiary,
            size: ButtonSize.medium,
            onPressed: onCancel,
          ),
        ),
        const SizedBox(width: 12),
        // Save
        Expanded(
          flex: 2,
          child: CustomButton(
            text: 'profile.edit.save'.tr(),
            icon: Icons.check_rounded,
            size: ButtonSize.medium,
            isLoading: isLoading,
            onPressed: onSave,
          ),
        ),
      ],
    );
  }
}
