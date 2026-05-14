import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_config.dart';
import '../../../data/app_colors.dart';
import '../../models/incidents/bulk_incident.dart';
import '../../models/incidents/map_incident.dart';
import '../../services/incidents/bulk_incident_api_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/shared/video_player_dialog.dart';
import 'incident_detail_sheet.dart';

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
          final url = _resolveMediaUrl(mediaUrls[index]);
          final isVideo =
              url.toLowerCase().endsWith('.mp4') ||
              url.toLowerCase().endsWith('.mov') ||
              url.toLowerCase().endsWith('.avi') ||
              url.toLowerCase().endsWith('.mkv');

          if (isVideo) {
            return GestureDetector(
              onTap: () => _showVideoPlayerForReport(url),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[900],
                  border: Border.all(
                    color: AppTheme.getBorderColor(),
                    width: 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_fill,
                      size: 50,
                      color: const Color(0xFF00B3A4),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B3A4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'VIDEO',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () => _showImageViewer(url),
            child: ClipRRect(
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
            ),
          );
        },
      ),
    );
  }

  /// Converts a stored relative path (e.g. "uploads/Fire/img.jpg") to a full URL.
  /// Mirrors the logic in evidence_feed_section.dart.
  String _resolveMediaUrl(String storedPath) {
    if (storedPath.startsWith('http')) return storedPath;
    String filePath = storedPath;
    if (filePath.startsWith('uploads/')) {
      filePath = filePath.substring(8); // strip "uploads/"
    }
    final encoded = filePath.split('/').map(Uri.encodeComponent).join('/');
    return '${AppConfig.fileServerUrl}/$encoded';
  }

  Widget _buildSourceUrls(List<String> urls) {
    return Column(
      children: urls.map((url) {
        return GestureDetector(
          onTap: () => _launchSourceUrl(url),
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

  Future<void> _launchSourceUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
          ...reports
              .map(
                (r) =>
                    _buildReportCard(r, parentBulk: _fullBulk ?? widget.bulk),
              )
              .toList(),
        ],
      ],
    );
  }

  Widget _buildReportCard(
    BulkSubIncident report, {
    required BulkIncident parentBulk,
  }) {
    final isOsint = report.isOsint;
    return GestureDetector(
      onTap: () => _openSubIncidentDetail(report, parentBulk),
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
                      ? 'OSINT · ${_timeAgo(report.timestamp)}'
                      : '${report.reportedByName ?? 'Anonymous'} · ${_timeAgo(report.timestamp)}',
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
            // Title
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
            // Reporter (Human only)
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
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.media.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final url = _resolveMediaUrl(report.media[i].url);
                    final isVideo =
                        report.media[i].mediaType.toUpperCase() == 'VIDEO';

                    if (isVideo) {
                      return GestureDetector(
                        onTap: () => _showVideoPlayerForReport(url),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[900],
                            border: Border.all(
                              color: AppTheme.getBorderColor(),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_fill,
                                size: 30,
                                color: const Color(0xFF00B3A4),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B3A4),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: const Text(
                                    'VID',
                                    style: TextStyle(
                                      fontSize: 6,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () => _showImageViewer(url),
                      child: ClipRRect(
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
                      ),
                    );
                  },
                ),
              ),
            ],
            if (report.sourceUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...report.sourceUrls.map((sourceUrl) {
                return GestureDetector(
                  onTap: () => _launchSourceUrl(sourceUrl),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF7C3AED).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.link,
                          size: 14,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sourceUrl,
                            style: const TextStyle(
                              fontSize: 11,
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
            ],
          ],
        ),
      ),
    );
  }

  void _showVideoPlayerForReport(String videoUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      builder: (_) => VideoPlayerDialog(videoUrl: videoUrl),
    );
  }

  void _showImageViewer(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black87,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load image',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSubIncidentDetail(BulkSubIncident sub, BulkIncident parentBulk) {
    final incident = MapIncident(
      id: sub.id,
      type: parentBulk.type,
      position: parentBulk.center,
      title: sub.title ?? parentBulk.type,
      description: sub.description ?? '',
      timestamp: sub.timestamp,
      media: sub.media,
      addressText: parentBulk.locationText,
      city: parentBulk.city,
      confidence: sub.confidence,
      source: sub.source,
      sourceUrls: sub.sourceUrls,
      isMerged: true,
      bulkIncidentId: parentBulk.id,
    );

    final diff = DateTime.now().difference(sub.timestamp);
    final timeAgo = diff.inMinutes < 60
        ? '${diff.inMinutes}m ago'
        : diff.inHours < 24
        ? '${diff.inHours}h ago'
        : '${diff.inDays}d ago';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          IncidentDetailScreen(incident: incident, timeAgo: timeAgo),
    );
  }
}
