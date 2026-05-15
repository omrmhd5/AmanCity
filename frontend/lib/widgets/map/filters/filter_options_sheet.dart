import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../../data/incident_types_config.dart';
import '../../shared/custom_text.dart';

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

class _FilterOptionsSheetState extends State<FilterOptionsSheet> {
  Set<String> selectedIncidentTypes = {};
  bool _showAllTypes = false;
  bool _applyPressed = false;

  late double radiusKm;

  @override
  void initState() {
    super.initState();
    radiusKm = widget.initialRadius;
    selectedIncidentTypes = {...widget.initialSelectedTypes};
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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(),
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
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.getBorderColor(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 16),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: AppColors.secondary),
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
                  child: Icon(
                    Icons.close,
                    color: AppTheme.getSecondaryTextColor(),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Teal gradient divider
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
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Alert Radius section header ───────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionLabel(Icons.radar, 'Alert Radius'),
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
                            overlayColor: AppColors.secondary.withOpacity(0.15),
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
                          'You will receive real-time alerts for incidents reported within this distance from your current location.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getPrimaryTextColor().withOpacity(
                              0.6,
                            ),
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
                      _showAllTypes ? IncidentTypesConfig.allTypes.length : 9,
                      (index) {
                        final incident = IncidentTypesConfig.allTypes[index];
                        final isSelected = selectedIncidentTypes.contains(
                          incident.key,
                        );
                        return AnimatedScale(
                          scale: isSelected ? 1.06 : 1.0,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          child: FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  incident.icon,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : incident.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  incident.displayName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.getPrimaryTextColor(),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedIncidentTypes.add(incident.key);
                                } else {
                                  selectedIncidentTypes.remove(incident.key);
                                }
                              });
                            },
                            selectedColor: incident.color,
                            backgroundColor: AppTheme.getCardBackgroundColor(),
                            side: BorderSide(
                              color: isSelected
                                  ? incident.color
                                  : AppTheme.getBorderColor(),
                              width: isSelected ? 2 : 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),

                  if (!_showAllTypes && IncidentTypesConfig.allTypes.length > 9)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: GestureDetector(
                          onTap: () => setState(() => _showAllTypes = true),
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
          ),
          // Apply button
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
        ],
      ),
    );
  }
}
