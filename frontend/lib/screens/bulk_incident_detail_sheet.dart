import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../data/app_colors.dart';
import '../../models/bulk_incident.dart';
import '../../services/bulk_incident_api_service.dart';
import '../../utils/app_theme.dart';

class BulkIncidentDetailSheet extends StatefulWidget {
  final BulkIncident bulk;

  const BulkIncidentDetailSheet({Key? key, required this.bulk})
    : super(key: key);

  @override
  State<BulkIncidentDetailSheet> createState() =>
      _BulkIncidentDetailSheetState();
}

class _BulkIncidentDetailSheetState extends State<BulkIncidentDetailSheet> {
  BulkIncident? _fullBulk;
  bool _loading = true;
  bool _reportsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadFull();
  }

  Future<void> _loadFull() async {
    try {
      final full = await BulkIncidentApiService.getBulkIncidentById(
        widget.bulk.id,
      );
      if (mounted)
        setState(() {
          _fullBulk = full;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final bulk = _fullBulk ?? widget.bulk;
    final color = bulk.typeColor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(bulk, color),
                  const SizedBox(height: 16),
                  _buildSourceChips(bulk),
                  const SizedBox(height: 20),
                  if (bulk.mediaUrls.isNotEmpty) ...[
                    _buildSectionLabel('Media Evidence'),
                    const SizedBox(height: 10),
                    _buildMediaFeed(bulk.mediaUrls),
                    const SizedBox(height: 20),
                  ],
                  if (bulk.sourceUrls.isNotEmpty) ...[
                    _buildSectionLabel('OSINT Sources'),
                    const SizedBox(height: 10),
                    _buildSourceUrls(bulk.sourceUrls),
                    const SizedBox(height: 20),
                  ],
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if ((_fullBulk?.subIncidents ?? []).isNotEmpty) ...[
                    _buildReportsSection(_fullBulk!.subIncidents),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BulkIncident bulk, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(bulk.typeIcon, color: color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bulk.type,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
                    ),
                  ),
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${bulk.count} reports',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (bulk.locationText != null)
                Text(
                  bulk.locationText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              Text(
                'First reported ${_timeAgo(bulk.firstReportedAt)} · last updated ${_timeAgo(bulk.lastUpdatedAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSourceChips(BulkIncident bulk) {
    return Wrap(
      spacing: 8,
      children: [
        if (bulk.hasHumanReports)
          _chip(Icons.person_outline, 'Human Reports', AppColors.secondary),
        if (bulk.hasOsintReports)
          _chip(Icons.radar, 'OSINT Intelligence', const Color(0xFF7C3AED)),
        _chip(
          Icons.analytics_outlined,
          '${(bulk.avgConfidence * 100).round()}% confidence',
          AppColors.primary,
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.getSecondaryTextColor(),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildMediaFeed(List<String> mediaUrls) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mediaUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = '${AppConfig.fileServerUrl}/${mediaUrls[index]}';
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              width: 130,
              height: 130,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 130,
                height: 130,
                color: AppTheme.getBorderColor(),
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSourceUrls(List<String> urls) {
    return Column(
      children: urls.map((url) {
        return GestureDetector(
          onTap: () async {
            final uri = Uri.tryParse(url);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, size: 16, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    url,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7C3AED),
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportsSection(List<BulkSubIncident> reports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _reportsExpanded = !_reportsExpanded),
          child: Row(
            children: [
              Expanded(
                child: _buildSectionLabel(
                  'Individual Reports (${reports.length})',
                ),
              ),
              Icon(
                _reportsExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppTheme.getSecondaryTextColor(),
                size: 20,
              ),
            ],
          ),
        ),
        if (_reportsExpanded) ...[
          const SizedBox(height: 10),
          ...reports.map((r) => _buildReportCard(r)).toList(),
        ],
      ],
    );
  }

  Widget _buildReportCard(BulkSubIncident report) {
    final isOsint = report.isOsint;
    return Container(
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
                color: isOsint ? const Color(0xFF7C3AED) : AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                isOsint
                    ? 'OSINT · ${_timeAgo(report.timestamp)}'
                    : 'Human · ${_timeAgo(report.timestamp)}',
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
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ),
            ],
          ),
          if (report.description != null && report.description!.isNotEmpty) ...[
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
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: report.media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final url =
                      '${AppConfig.fileServerUrl}/${report.media[i].url}';
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: AppTheme.getBorderColor(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
