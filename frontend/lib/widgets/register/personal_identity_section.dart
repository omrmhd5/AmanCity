import 'package:flutter/material.dart';
import '../custom_text_field.dart';
import '../custom_text.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class PersonalIdentitySection extends StatefulWidget {
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final String? selectedCity; // Kept for compatibility
  final Function(String?) onCityChanged; // Kept for compatibility

  const PersonalIdentitySection({
    Key? key,
    required this.fullNameController,
    required this.phoneController,
    required this.selectedCity,
    required this.onCityChanged,
  }) : super(key: key);

  @override
  State<PersonalIdentitySection> createState() =>
      _PersonalIdentitySectionState();
}

class _PersonalIdentitySectionState extends State<PersonalIdentitySection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section Divider
        _buildSectionDivider('Personal Identity'),
        const SizedBox(height: 16),
        // Full Name
        CustomTextField(
          label: 'Full Name',
          placeholder: 'e.g. Layla Ahmed',
          prefixIcon: Icons.person,
          controller: widget.fullNameController,
        ),
        const SizedBox(height: 20),
        // Phone Number
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: 'Phone Number',
              size: 14,
              weight: FontWeight.w500,
              color: AppTheme.getPrimaryTextColor(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.currentMode == AppThemeMode.dark
                        ? const Color(0xFF162A4D)
                        : AppColors.lightGray,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.getBorderColor()),
                  ),
                  child: CustomText(
                    text: '🇪🇬 +20',
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppTheme.getPrimaryTextColor(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      color: AppTheme.getPrimaryTextColor(),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: '100 123 4567',
                      hintStyle: TextStyle(
                        color: AppColors.slateGray.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: AppTheme.currentMode == AppThemeMode.dark
                          ? const Color(0xFF162A4D)
                          : AppColors.lightGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.getBorderColor(),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppTheme.getBorderColor(),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            CustomText(
              text: 'Used for emergency verification only.',
              size: 10,
              weight: FontWeight.w400,
              color: AppTheme.getSecondaryTextColor(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionDivider(String title) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppTheme.getBorderColor())),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CustomText(
            text: title,
            size: 11,
            weight: FontWeight.w600,
            color: AppTheme.getSecondaryTextColor(),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.getBorderColor())),
      ],
    );
  }
}
