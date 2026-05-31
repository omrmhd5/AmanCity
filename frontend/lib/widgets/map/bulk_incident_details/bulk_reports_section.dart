import 'package:flutter/material.dart';
import '../../../data/app_colors.dart';
import '../../../models/incidents/bulk_incident.dart';
import '../../../utils/app_theme.dart';
import './bulk_media_feed.dart';
import './bulk_osint_sources.dart';

class BulkReportsSection extends StatefulWidget {
  final List<BulkSubIncident> reports;
  final BulkIncident parentBulk;
  final void Function(BulkSubIncident, BulkIncident) onReportTap;
  final String Function(DateTime) timeAgo;

  const BulkReportsSection({
    Key? key,
    required this.reports,
    required this.parentBulk,
    required this.onReportTap,
    required this.timeAgo,
  }) : super(key: key);

  @override
  State<BulkReportsSection> createState() => _BulkReportsSectionState();
}

class _BulkReportsSectionState extends State<BulkReportsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                Icons.description_rounded,
                size: 14,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'INDIVIDUAL REPORTS (${widget.reports.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getSecondaryTextColor(),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.secondary,
                size: 20,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 10),
          ...widget.reports.map((r) => _buildReportCard(r)).toList(),
        ],
      ],
    );
  }

  Widget _buildReportCard(BulkSubIncident report) {
    final isOsint = report.isOsint;
    return GestureDetector(
      onTap: () => widget.onReportTap(report, widget.parentBulk),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.getCardBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.getBorderColor()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOsint ? Icons.radar : Icons.person_outline,
                  size: 14,
                  color: isOsint
                      ? const Color(0xFF7C3AED)
                      : AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  isOsint
                      ? 'OSINT · ${widget.timeAgo(report.timestamp)}'
                      : '${report.reportedByName ?? 'Anonymous'} · ${widget.timeAgo(report.timestamp)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOsint
                        ? const Color(0xFF7C3AED)
                        : AppColors.secondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(report.confidence * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: report.confidence >= 0.7
                        ? AppColors.danger
                        : report.confidence >= 0.4
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
              ],
            ),
            if (report.title != null && report.title!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                report.title!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getPrimaryTextColor(),
                ),
              ),
            ],
            if (!isOsint && report.reportedByName != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 11,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Reported by ${report.reportedByName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                  ),
                ],
              ),
            ],
            if (report.description != null &&
                report.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                report.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSecondaryTextColor(),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (report.media.isNotEmpty) ...[
              const SizedBox(height: 8),
              BulkMediaFeed(
                mediaUrls: report.media.map((m) => m.url).toList(),
                mediaTypes: report.media.map((m) => m.mediaType).toList(),
                itemSize: 70,
              ),
            ],
            if (report.sourceUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              BulkOsintSources(
                urls: report.sourceUrls,
                itemFontSize: 11,
                iconSize: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                marginBottom: 6,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
