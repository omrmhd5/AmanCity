import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class HomeCommunityTools extends StatefulWidget {
  final VoidCallback onMapTap;
  final VoidCallback onNewsTap;

  const HomeCommunityTools({
    Key? key,
    required this.onMapTap,
    required this.onNewsTap,
  }) : super(key: key);

  @override
  State<HomeCommunityTools> createState() => _HomeCommunityToolsState();
}

class _HomeCommunityToolsState extends State<HomeCommunityTools> {
  bool _mapPressed = false;
  bool _newsPressed = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            icon: Icons.map_rounded,
            title: 'home.explore_map'.tr(),
            subtitle: 'home.explore_map_subtitle'.tr(),
            isPressed: _mapPressed,
            onTapDown: () => setState(() => _mapPressed = true),
            onTapUp: () {
              setState(() => _mapPressed = false);
              widget.onMapTap();
            },
            onTapCancel: () => setState(() => _mapPressed = false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCard(
            icon: Icons.report_rounded,
            title: 'home.report'.tr(),
            subtitle: 'home.report_subtitle'.tr(),
            isPressed: _newsPressed,
            onTapDown: () => setState(() => _newsPressed = true),
            onTapUp: () {
              setState(() => _newsPressed = false);
              widget.onNewsTap();
            },
            onTapCancel: () => setState(() => _newsPressed = false),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTapCancel,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: isPressed ? 0.96 : 1.0,
        duration: isPressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 300),
        curve: isPressed ? Curves.easeIn : Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.getCardBackgroundColor(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorderColor(), width: 0.75),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.15),
                    width: 0.75,
                  ),
                ),
                child: Icon(icon, color: AppColors.secondary, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getPrimaryTextColor(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                  height: 1.4,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
