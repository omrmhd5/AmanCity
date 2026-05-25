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
    final isFirst = priority == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor().withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFirst
              ? AppColors.danger.withOpacity(0.28)
              : AppTheme.getBorderColor().withOpacity(0.15),
          width: isFirst ? 1 : 0.75,
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
                  color: isFirst
                      ? AppColors.danger.withOpacity(0.12)
                      : AppColors.secondary.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFirst
                        ? AppColors.danger.withOpacity(0.3)
                        : AppColors.secondary.withOpacity(0.2),
                    width: 1,
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
                      color: isFirst ? AppColors.danger : AppColors.secondary,
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
                    color: isFirst ? AppColors.danger : AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.getBackgroundColor(),
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
                    Flexible(
                      child: Text(
                        contact.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFirst) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.danger.withOpacity(0.2),
                            width: 0.75,
                          ),
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
              Icons.edit_rounded,
              size: 19,
              color: AppTheme.getSecondaryTextColor(),
            ),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 19,
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
