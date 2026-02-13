import 'package:flutter/material.dart';
import '../custom_text.dart';
import '../custom_gesture_detector.dart';
import '../../utils/app_colors.dart';

enum AccountType { citizen, womenAtRisk }

class AccountTypeSelector extends StatefulWidget {
  final AccountType selectedType;
  final Function(AccountType) onTypeChanged;

  const AccountTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeChanged,
  }) : super(key: key);

  @override
  State<AccountTypeSelector> createState() => _AccountTypeSelectorState();
}

class _AccountTypeSelectorState extends State<AccountTypeSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        // Section Divider
        _buildSectionDivider('Account Type'),
        const SizedBox(height: 16),
        // Citizen Option
        _buildAccountTypeOption(
          title: 'Concerned Citizen',
          description:
              'Standard access to community reporting and neighborhood alerts.',
          icon: Icons.public,
          value: AccountType.citizen,
        ),
        const SizedBox(height: 12),
        // Woman-at-Risk Option
        _buildAccountTypeOption(
          title: 'Woman-at-Risk',
          description:
              'Enhanced privacy modes, rapid SOS features, and direct support lines.',
          icon: Icons.verified_user,
          value: AccountType.womenAtRisk,
        ),
      ],
    );
  }

  Widget _buildSectionDivider(String title) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CustomText(
            text: title,
            size: 11,
            weight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.2)),
        ),
      ],
    );
  }

  Widget _buildAccountTypeOption({
    required String title,
    required String description,
    required IconData icon,
    required AccountType value,
  }) {
    final isSelected = widget.selectedType == value;
    return CustomGestureDetector(
      onTap: () {
        widget.onTypeChanged(value);
      },
      enableScale: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF162A4D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.3)
                : const Color(0xFF1E3A66),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF94A3B8), width: 2),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: title,
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    text: description,
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}
