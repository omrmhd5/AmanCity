import 'package:flutter/material.dart';
import '../../../data/app_colors.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/safe_route_scorer.dart';

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

  String _safetyPercent(double dangerScore) {
    final pct = ((1.0 - dangerScore) * 100).round().clamp(0, 100);
    return '$pct%';
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = AppTheme.currentMode == AppThemeMode.dark
        ? AppColors.primary
        : Colors.white;
    final borderColor = widget.routeColor ?? AppColors.secondary;
    final safestInfo = widget.dangerScore != null
        ? SafeRouteScorer.getDangerLevelInfo(widget.dangerScore!)
        : null;
    final fastestInfo = widget.fastestDangerScore != null
        ? SafeRouteScorer.getDangerLevelInfo(widget.fastestDangerScore!)
        : null;

    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.35), width: 1),
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
                          widget.destinationName ?? 'Destination',
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
                                  ? '${widget.incidentType} Incident'
                                  : widget.incidentType!,
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
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
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

            const SizedBox(height: 12),

            // ── Route cards ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  // Safest route card
                  _RouteOptionCard(
                    label: widget.hasFastestAlternative
                        ? 'Safest'
                        : 'Safest + Fastest',
                    labelColor: const Color(0xFF10B981),
                    duration: widget.duration ?? 'Calculating...',
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
                    onTap: () {
                      setState(() => _safestSelected = true);
                      widget.onRouteSelectionChanged?.call(true);
                    },
                  ),

                  // Fastest route card (only when there's an alternative)
                  if (widget.hasFastestAlternative &&
                      widget.fastestDuration != null) ...[
                    const SizedBox(height: 8),
                    _RouteOptionCard(
                      label: 'Fastest',
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
                      onTap: () {
                        setState(() => _safestSelected = false);
                        widget.onRouteSelectionChanged?.call(false);
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Start navigation button ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.isLoading
                      ? null
                      : (_safestSelected
                            ? widget.onNavigate
                            : (widget.onNavigateSafeRoute ??
                                  widget.onNavigate)),
                  icon: const Icon(Icons.navigation, size: 18),
                  label: Text(
                    widget.isLoading ? 'Calculating...' : 'Start Navigation',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.secondary.withOpacity(
                      0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
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
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = AppTheme.currentMode == AppThemeMode.dark
        ? (isSelected
              ? AppColors.primaryHover
              : AppColors.primary.withOpacity(0.6))
        : (isSelected ? Colors.white : Colors.grey.shade50);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? labelColor : Colors.transparent,
            width: 2,
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
        child: Row(
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
                        isLoading ? '...' : duration,
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
                          isLoading ? '' : distance,
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
                    'Safety Score',
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
