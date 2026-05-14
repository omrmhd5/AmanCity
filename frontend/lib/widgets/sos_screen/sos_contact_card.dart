import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../models/sos/sos_contact.dart';
import '../../utils/app_theme.dart';

class SosContactCard extends StatelessWidget {
  final SosContact contact;
  final int priority;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SosContactCard({
    Key? key,
    required this.contact,
    required this.priority,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  String _priorityLabel(int p) {
    switch (p) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${p}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priority == 1
              ? AppColors.danger.withOpacity(0.25)
              : AppTheme.getBorderColor(),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar + priority badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: priority == 1
                        ? AppColors.danger.withOpacity(0.4)
                        : AppTheme.getBorderColor(),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    contact.name.isNotEmpty
                        ? contact.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: priority == 1
                        ? AppColors.danger
                        : AppColors.darkGray,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.getCardBackgroundColor(),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _priorityLabel(priority),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      contact.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
                    ),
                    if (priority == 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'PRIMARY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  contact.phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppTheme.getSecondaryTextColor(),
            ),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.danger,
            ),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
