import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/safe_route_scorer.dart';
import '../../../data/incident_types_config.dart';

class RouteInfoCard extends StatefulWidget {
  final String? destinationName;
  final String? distance;
  final String? duration;
  final bool isLoading;
  final Color? routeColor;
  final VoidCallback onNavigate;
  final VoidCallback? onNavigateSafeRoute;
  final VoidCallback onClose;
  final String? incidentType;
  final String? locationText;
  final bool isIncident;
  final double? dangerScore;
  // Fastest alternative (shown only when different from safest)
  final bool hasFastestAlternative;
  final String? fastestDistance;
  final String? fastestDuration;
  final double? fastestDangerScore;
  final ValueChanged<bool>?
  onRouteSelectionChanged; // true=safest, false=fastest

  const RouteInfoCard({
    Key? key,
    required this.destinationName,
    required this.distance,
    required this.duration,
    required this.isLoading,
    this.routeColor,
    required this.onNavigate,
    this.onNavigateSafeRoute,
    required this.onClose,
    this.incidentType,
    this.locationText,
    this.isIncident = false,
    this.dangerScore,
    this.hasFastestAlternative = false,
    this.fastestDistance,
    this.fastestDuration,
    this.fastestDangerScore,
    this.onRouteSelectionChanged,
  }) : super(key: key);

  @override
  State<RouteInfoCard> createState() => _RouteInfoCardState();
}

class _RouteInfoCardState extends State<RouteInfoCard> {
  // true = user selected safest, false = user selected fastest
  bool _safestSelected = true;
  bool _startPressed = false;

  String _safetyPercent(double dangerScore) {
    final pct = ((1.0 - dangerScore) * 100).round().clamp(0, 100);
    return '$pct%';
  }

  String _getLocalizedIncidentLabel(BuildContext context, String type) {
    final isArabic = context.locale.languageCode == 'ar';
    final lowerType = type.toLowerCase().trim();
    if (lowerType == 'accident') {
      return isArabic ? 'حادث سيارة' : 'Car Accident';
    } else if (lowerType == 'fire') {
      return isArabic ? 'حادث حريق' : 'Fire Incident';
    } else if (lowerType == 'flood') {
      return isArabic ? 'حادث فيضان' : 'Flood Incident';
    } else {
      final localizedName = IncidentTypesConfig.getByKey(type).localizedName;
      return isArabic ? 'حادثة $localizedName' : '$type Incident';
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.routeColor ?? AppColors.secondary;
    final safestInfo = widget.dangerScore != null
        ? SafeRouteScorer.getDangerLevelInfo(widget.dangerScore!)
        : null;
    final fastestInfo = widget.fastestDangerScore != null
        ? SafeRouteScorer.getDangerLevelInfo(widget.fastestDangerScore!)
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundColor().withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor.withOpacity(0.35), width: 1),
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
              // ── Header (destination + close) ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                child: Row(
                  children: [
                    Icon(Icons.pin_drop, color: borderColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.destinationName == 'Selected Location'
                                ? 'map.selected_location'.tr()
                                : (widget.destinationName ?? 'map.destination'.tr()),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.getPrimaryTextColor(),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.incidentType != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: borderColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: borderColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.isIncident
                                    ? _getLocalizedIncidentLabel(context, widget.incidentType!)
                                    : (widget.incidentType == 'Destination'
                                        ? 'map.destination'.tr()
                                        : (widget.incidentType == 'Selected Location'
                                            ? 'map.selected_location'.tr()
                                            : widget.incidentType!)),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: borderColor,
                                ),
                              ),
                            ),
                          ],
                          if (widget.locationText != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.locationText!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: Colors.red),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
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
              const SizedBox(height: 12),

              // ── Route cards ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: widget.hasFastestAlternative &&
                        widget.fastestDuration != null
                    ? Row(
                        children: [
                          Expanded(
                            child: _RouteOptionCard(
                              label: 'map.safest'.tr(),
                              labelColor: const Color(0xFF10B981),
                              duration: widget.duration ?? 'map.calculating'.tr(),
                              distance: widget.distance ?? '...',
                              safetyPercent: widget.dangerScore != null
                                  ? _safetyPercent(widget.dangerScore!)
                                  : null,
                              safetyColor: safestInfo != null
                                  ? (safestInfo['color'] as Color)
                                  : const Color(0xFF10B981),
                              safetyIcon: Icons.verified_user,
                              isSelected: _safestSelected,
                              isLoading: widget.isLoading,
                              isCompact: true,
                              onTap: () {
                                setState(() => _safestSelected = true);
                                widget.onRouteSelectionChanged?.call(true);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RouteOptionCard(
                              label: 'map.fastest'.tr(),
                              labelColor: const Color(0xFF3B82F6),
                              duration: widget.fastestDuration!,
                              distance: widget.fastestDistance ?? '...',
                              safetyPercent: widget.fastestDangerScore != null
                                  ? _safetyPercent(widget.fastestDangerScore!)
                                  : null,
                              safetyColor: fastestInfo != null
                                  ? (fastestInfo['color'] as Color)
                                  : const Color(0xFFF59E0B),
                              safetyIcon: Icons.gpp_maybe,
                              isSelected: !_safestSelected,
                              isLoading: widget.isLoading,
                              isCompact: true,
                              onTap: () {
                                setState(() => _safestSelected = false);
                                widget.onRouteSelectionChanged?.call(false);
                              },
                            ),
                          ),
                        ],
                      )
                    : _RouteOptionCard(
                        label: 'map.safest_fastest'.tr(),
                        labelColor: const Color(0xFF10B981),
                        duration: widget.duration ?? 'map.calculating'.tr(),
                        distance: widget.distance ?? '...',
                        safetyPercent: widget.dangerScore != null
                            ? _safetyPercent(widget.dangerScore!)
                            : null,
                        safetyColor: safestInfo != null
                            ? (safestInfo['color'] as Color)
                            : const Color(0xFF10B981),
                        safetyIcon: Icons.verified_user,
                        isSelected: _safestSelected,
                        isLoading: widget.isLoading,
                        isCompact: false,
                        onTap: () {
                          setState(() => _safestSelected = true);
                          widget.onRouteSelectionChanged?.call(true);
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // ── Start navigation button ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: GestureDetector(
                  onTapDown: widget.isLoading
                      ? null
                      : (_) => setState(() => _startPressed = true),
                  onTapUp: widget.isLoading
                      ? null
                      : (_) {
                          setState(() => _startPressed = false);
                          (_safestSelected
                                  ? (widget.onNavigateSafeRoute ??
                                        widget.onNavigate)
                                  : widget.onNavigate)
                              .call();
                        },
                  onTapCancel: widget.isLoading
                      ? null
                      : () => setState(() => _startPressed = false),
                  child: AnimatedScale(
                    scale: _startPressed ? 0.96 : 1.0,
                    duration: _startPressed
                        ? const Duration(milliseconds: 80)
                        : const Duration(milliseconds: 300),
                    curve: _startPressed ? Curves.easeIn : Curves.easeOutBack,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.isLoading
                              ? [
                                  AppColors.secondary.withOpacity(0.4),
                                  AppColors.secondary.withOpacity(0.3),
                                ]
                              : [
                                  AppColors.secondary,
                                  AppColors.secondary.withOpacity(0.72),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: widget.isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.navigation_rounded,
                            color: Colors.white.withOpacity(
                              widget.isLoading ? 0.5 : 1.0,
                            ),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isLoading
                                ? 'map.calculating'.tr()
                                : 'map.start_navigation'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(
                                widget.isLoading ? 0.5 : 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single route option card ──────────────────────────────────────────────────

class _RouteOptionCard extends StatelessWidget {
  final String label;
  final Color labelColor;
  final String duration;
  final String distance;
  final String? safetyPercent;
  final Color safetyColor;
  final IconData safetyIcon;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;
  final bool isCompact;

  const _RouteOptionCard({
    required this.label,
    required this.labelColor,
    required this.duration,
    required this.distance,
    required this.safetyPercent,
    required this.safetyColor,
    required this.safetyIcon,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    String displayDuration = duration;
    String displayDistance = distance;

    if (isArabic) {
      displayDuration = displayDuration
          .replaceAll('mins', 'دقيقة')
          .replaceAll('min', 'دقيقة')
          .replaceAll('hours', 'ساعة')
          .replaceAll('hour', 'ساعة');

      displayDistance = displayDistance.replaceAll('km', 'كم');
      if (displayDistance.endsWith(' m')) {
        displayDistance = displayDistance.substring(0, displayDistance.length - 2) + ' م';
      } else if (displayDistance.endsWith('m') && !displayDistance.endsWith('km')) {
        displayDistance = displayDistance.substring(0, displayDistance.length - 1) + ' م';
      }
    }

    final cardBg = AppTheme.currentMode == AppThemeMode.dark
        ? (isSelected
              ? AppColors.primaryHover
              : AppTheme.getBackgroundColor().withOpacity(0.5))
        : (isSelected ? Colors.white : Colors.grey.shade50);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 14,
          vertical: isCompact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? labelColor
                : AppTheme.getBorderColor().withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: labelColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: labelColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: labelColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      if (safetyPercent != null)
                        Row(
                          children: [
                            Icon(safetyIcon, color: safetyColor, size: 13),
                            const SizedBox(width: 2),
                            Text(
                              safetyPercent!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: safetyColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isLoading ? '...' : displayDuration,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isLoading ? '' : displayDistance,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  // Left: label + time + distance
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: labelColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: labelColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isLoading ? '...' : displayDuration,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.getPrimaryTextColor(),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                isLoading ? '' : displayDistance,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.getSecondaryTextColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Right: safety score
                  if (safetyPercent != null) ...[
                    Container(
                      height: 52,
                      width: 1,
                      color: AppTheme.getBorderColor(),
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(safetyIcon, color: safetyColor, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              safetyPercent!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: safetyColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'map.safety_score'.tr(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getSecondaryTextColor(),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
