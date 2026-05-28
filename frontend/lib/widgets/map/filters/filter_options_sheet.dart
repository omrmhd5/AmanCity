import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../../data/incident_types_config.dart';
import '../../shared/custom_text.dart';
import '../../shared/custom_filter_chips.dart';

class FilterSettings {
  final double radiusKm;
  final Set<String> selectedIncidentTypes;

  FilterSettings({required this.radiusKm, required this.selectedIncidentTypes});
}

class FilterOptionsSheet extends StatefulWidget {
  final double initialRadius;
  final Set<String> initialSelectedTypes;

  const FilterOptionsSheet({
    Key? key,
    this.initialRadius = 5.0,
    this.initialSelectedTypes = const {},
  }) : super(key: key);

  @override
  State<FilterOptionsSheet> createState() => _FilterOptionsSheetState();
}

class _FilterOptionsSheetState extends State<FilterOptionsSheet>
    with SingleTickerProviderStateMixin {
  Set<String> selectedIncidentTypes = {};
  bool _showAllTypes = false;
  bool _applyPressed = false;
  late AnimationController _entryController;

  late double radiusKm;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entryController.forward();
    });
    radiusKm = widget.initialRadius;
    selectedIncidentTypes = {...widget.initialSelectedTypes};
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, {double start = 0.0, double end = 1.0}) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  bool get _allSelected => IncidentTypesConfig.allTypes.every(
    (t) => selectedIncidentTypes.contains(t.key),
  );

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        selectedIncidentTypes.clear();
      } else {
        selectedIncidentTypes = IncidentTypesConfig.allTypes
            .map((t) => t.key)
            .toSet();
      }
    });
  }

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.secondary),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.getSecondaryTextColor(),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundColor().withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              _animated(
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                start: 0.0,
                end: 0.4,
              ),
              // Title row
              _animated(
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 16, 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filters & Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.getPrimaryTextColor(),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 28,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                start: 0.05,
                end: 0.5,
              ),
              // Teal gradient divider
              _animated(
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.0),
                        AppColors.secondary.withOpacity(0.3),
                        AppColors.secondary.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                start: 0.1,
                end: 0.5,
              ),
              // Content
              Expanded(
                child: _animated(
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Display Range section header ──────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionLabel(Icons.place_rounded, 'Display Range'),
                            Text(
                              '${radiusKm.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.getPrimaryTextColor(),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Radius Slider card ───────────────────────────
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          decoration: BoxDecoration(
                            color: AppTheme.getCardBackgroundColor(),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 10,
                                  ),
                                  activeTrackColor: AppColors.secondary,
                                  inactiveTrackColor: AppTheme.getBorderColor(),
                                  thumbColor: AppColors.secondary,
                                  overlayColor: AppColors.secondary.withOpacity(
                                    0.15,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 18,
                                  ),
                                ),
                                child: Slider(
                                  value: radiusKm,
                                  min: 1.0,
                                  max: 25.0,
                                  divisions: 24,
                                  onChanged: (value) {
                                    setState(() => radiusKm = value);
                                  },
                                ),
                              ),
                              // Track labels — proportional: 5 at 17%, 15 at 58%, 25 at 100%
                              Row(
                                children: [
                                  const Spacer(flex: 4),
                                  Text(
                                    '5 km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.getSecondaryTextColor(),
                                    ),
                                  ),
                                  const Spacer(flex: 10),
                                  Text(
                                    '15 km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.getSecondaryTextColor(),
                                    ),
                                  ),
                                  const Spacer(flex: 10),
                                  Text(
                                    '25 km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.getSecondaryTextColor(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'POIs like hospitals, police stations, and fire departments within this range will be displayed on the map.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.getPrimaryTextColor()
                                      .withOpacity(0.6),
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Incident Types section header ─────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionLabel(
                              Icons.warning_amber_rounded,
                              'Incident Types',
                            ),
                            GestureDetector(
                              onTap: _toggleAll,
                              child: Text(
                                _allSelected ? 'Deselect All' : 'Select All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Filter chips ──────────────────────────────────
                        Wrap(
                          spacing: 13,
                          runSpacing: 12,
                          children: List.generate(
                            _showAllTypes
                                ? IncidentTypesConfig.allTypes.length
                                : 9,
                            (index) {
                              final incident =
                                  IncidentTypesConfig.allTypes[index];
                              final isSelected = selectedIncidentTypes.contains(
                                incident.key,
                              );
                              return AnimatedScale(
                                scale: isSelected ? 1.06 : 1.0,
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutBack,
                                child: CustomFilterChip(
                                  label: incident.displayName,
                                  icon: incident.icon,
                                  isSelected: isSelected,
                                  selectedColor: incident.color,
                                  iconColor: incident.color,
                                  onTap: () => setState(() {
                                    if (isSelected) {
                                      selectedIncidentTypes.remove(
                                        incident.key,
                                      );
                                    } else {
                                      selectedIncidentTypes.add(incident.key);
                                    }
                                  }),
                                ),
                              );
                            },
                          ).toList(),
                        ),

                        if (!_showAllTypes &&
                            IncidentTypesConfig.allTypes.length > 9)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Center(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _showAllTypes = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.secondary,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: CustomText(
                                    text: 'Show More',
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  start: 0.15,
                  end: 0.75,
                ),
              ),
              // Apply button
              _animated(
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _applyPressed = true),
                    onTapUp: (_) {
                      setState(() => _applyPressed = false);
                      Navigator.pop(
                        context,
                        FilterSettings(
                          radiusKm: radiusKm,
                          selectedIncidentTypes: selectedIncidentTypes,
                        ),
                      );
                    },
                    onTapCancel: () => setState(() => _applyPressed = false),
                    child: AnimatedScale(
                      scale: _applyPressed ? 0.96 : 1.0,
                      duration: _applyPressed
                          ? const Duration(milliseconds: 80)
                          : const Duration(milliseconds: 300),
                      curve: _applyPressed ? Curves.easeIn : Curves.easeOutBack,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.secondary,
                              AppColors.secondary.withOpacity(0.72),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: CustomText(
                            text: 'Apply Filters',
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                start: 0.3,
                end: 0.85,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
