import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../models/report_incident_model.dart';

class EvidenceTypeSelector extends StatelessWidget {
  final EvidenceType? selectedType;
  final Function(EvidenceType) onTypeSelected;

  const EvidenceTypeSelector({
    Key? key,
    this.selectedType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildEvidenceButton(
          type: EvidenceType.photo,
          label: 'Photo',
          icon: Icons.photo_camera,
          isSelected: selectedType == EvidenceType.photo,
          onTap: () => onTypeSelected(EvidenceType.photo),
        ),
        const SizedBox(width: 12),
        _buildEvidenceButton(
          type: EvidenceType.video,
          label: 'Video',
          icon: Icons.videocam,
          isSelected: selectedType == EvidenceType.video,
          onTap: () => onTypeSelected(EvidenceType.video),
        ),
      ],
    );
  }

  Widget _buildEvidenceButton({
    required EvidenceType type,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.currentMode == AppThemeMode.dark
                ? AppColors.primary
                : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.secondary
                  : AppTheme.getBorderColor(),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppColors.secondary, size: 24),
                    ),
                    const SizedBox(height: 8),
                    // Text label
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
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
