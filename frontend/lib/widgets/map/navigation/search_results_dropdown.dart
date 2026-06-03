import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';

class SearchResultsDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> results;
  final Function(Map<String, dynamic>) onResultTap;

  const SearchResultsDropdown({
    Key? key,
    required this.results,
    required this.onResultTap,
  }) : super(key: key);

  @override
  State<SearchResultsDropdown> createState() => _SearchResultsDropdownState();
}

class _SearchResultsDropdownState extends State<SearchResultsDropdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  /// Get icon and color for a search result
  Map<String, dynamic> _getIconAndColor(Map<String, dynamic> place) {
    final type = place['type'] as String?;
    if (type == 'hospital') {
      return {'icon': Icons.local_hospital, 'color': const Color(0xFFEF4444)};
    } else if (type == 'police') {
      return {'icon': Icons.local_police, 'color': const Color(0xFF3B82F6)};
    } else if (type == 'fire') {
      return {'icon': Icons.fire_truck, 'color': const Color(0xFFF59E0B)};
    } else {
      return {'icon': Icons.location_on, 'color': AppColors.secondary};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) return const SizedBox.shrink();

    final isDark = AppTheme.currentMode == AppThemeMode.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Stack(
                children: [
                  // Glass base
                  Container(
                    constraints: const BoxConstraints(maxHeight: 380),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppColors.primary.withOpacity(0.82),
                                AppColors.primary.withOpacity(0.70),
                              ]
                            : [
                                Colors.white.withOpacity(0.88),
                                Colors.white.withOpacity(0.75),
                              ],
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.10)
                            : Colors.white.withOpacity(0.65),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.38 : 0.12),
                          blurRadius: 28,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.results.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final place = widget.results[index];
                        final isLast = index == widget.results.length - 1;
                        final iconData = _getIconAndColor(place);
                        final icon = iconData['icon'] as IconData;
                        final color = iconData['color'] as Color;

                        return _DropdownItem(
                          place: place,
                          icon: icon,
                          color: color,
                          isLast: isLast,
                          onTap: () => widget.onResultTap(place),
                        );
                      },
                    ),
                  ),

                  // Specular highlight
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(isDark ? 0.30 : 0.75),
                              Colors.white.withOpacity(isDark ? 0.14 : 0.45),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.25, 0.75, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownItem extends StatefulWidget {
  final Map<String, dynamic> place;
  final IconData icon;
  final Color color;
  final bool isLast;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.place,
    required this.icon,
    required this.color,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: _pressed
                ? const Duration(milliseconds: 80)
                : const Duration(milliseconds: 260),
            curve: _pressed ? Curves.easeIn : Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.place['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getPrimaryTextColor(),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.place['address'] ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.getSecondaryTextColor(),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.place['type'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getTypeLabel(
                                    widget.place['type'] as String?,
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: widget.color,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!widget.isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(
              height: 1,
              color: AppTheme.getBorderColor(),
              thickness: 1,
            ),
          ),
      ],
    );
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'hospital':
        return 'poi.hospital'.tr();
      case 'police':
        return 'poi.police_station'.tr();
      case 'fire':
        return 'poi.fire_station'.tr();
      default:
        return '';
    }
  }
}
