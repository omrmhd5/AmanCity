import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../models/incidents/report_incident_model.dart';

class EvidenceTypeSelector extends StatefulWidget {
  final EvidenceType? selectedType;
  final Function(EvidenceType) onTypeSelected;

  const EvidenceTypeSelector({
    Key? key,
    this.selectedType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  State<EvidenceTypeSelector> createState() => _EvidenceTypeSelectorState();
}

class _EvidenceTypeSelectorState extends State<EvidenceTypeSelector> {
  EvidenceType? _pressedType;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildEvidenceButton(
          type: EvidenceType.photo,
          label: 'Photo',
          icon: Icons.photo_camera_rounded,
          isSelected: widget.selectedType == EvidenceType.photo,
          onTap: () => widget.onTypeSelected(EvidenceType.photo),
        ),
        const SizedBox(width: 12),
        _buildEvidenceButton(
          type: EvidenceType.video,
          label: 'Video',
          icon: Icons.videocam_rounded,
          isSelected: widget.selectedType == EvidenceType.video,
          onTap: () => widget.onTypeSelected(EvidenceType.video),
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
    final bool isPressed = _pressedType == type;
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressedType = type),
        onTapUp: (_) {
          setState(() => _pressedType = null);
          onTap();
        },
        onTapCancel: () => setState(() => _pressedType = null),
        child: AnimatedScale(
          scale: isPressed ? 0.95 : 1.0,
          duration: isPressed
              ? const Duration(milliseconds: 80)
              : const Duration(milliseconds: 200),
          curve: isPressed ? Curves.easeIn : Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.secondary.withOpacity(0.12)
                  : AppTheme.getCardBackgroundColor(),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.secondary
                    : AppTheme.getBorderColor(),
                width: isSelected ? 1.5 : 0.75,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(
                      isSelected ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.15),
                      width: 0.75,
                    ),
                  ),
                  child: Icon(icon, color: AppColors.secondary, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.secondary
                        : AppTheme.getPrimaryTextColor(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
