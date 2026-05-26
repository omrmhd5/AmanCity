import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/app_colors.dart';
import '../../models/incidents/bulk_incident.dart';
import '../../models/incidents/map_incident.dart';
import '../../services/incidents/bulk_incident_api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/map/bulk_incident_details/bulk_incident_header.dart';
import '../../widgets/map/bulk_incident_details/bulk_source_chips.dart';
import '../../widgets/map/bulk_incident_details/bulk_media_feed.dart';
import '../../widgets/map/bulk_incident_details/bulk_osint_sources.dart';
import '../../widgets/map/bulk_incident_details/bulk_reports_section.dart';
import './incident_detail_sheet.dart';

class BulkIncidentDetailSheet extends StatefulWidget {
  final BulkIncident bulk;
  final Future<void> Function(BulkIncident)? onNavigate;

  const BulkIncidentDetailSheet({Key? key, required this.bulk, this.onNavigate})
    : super(key: key);

  @override
  State<BulkIncidentDetailSheet> createState() =>
      _BulkIncidentDetailSheetState();
}

class _BulkIncidentDetailSheetState extends State<BulkIncidentDetailSheet> {
  BulkIncident? _fullBulk;
  bool _loading = true;
  bool _navigatePressed = false;

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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundColor().withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
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
              // Main content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BulkIncidentHeader(bulk: bulk, timeAgo: _timeAgo),
                      const SizedBox(height: 16),
                      BulkSourceChips(bulk: bulk),
                      const SizedBox(height: 20),
                      if (bulk.mediaUrls.isNotEmpty) ...[
                        _sectionLabel('Media Evidence', Icons.image_rounded),
                        const SizedBox(height: 10),
                        BulkMediaFeed(mediaUrls: bulk.mediaUrls, itemSize: 130),
                        const SizedBox(height: 20),
                      ],
                      if (bulk.sourceUrls.isNotEmpty) ...[
                        _sectionLabel('OSINT Sources', Icons.link_rounded),
                        const SizedBox(height: 10),
                        BulkOsintSources(urls: bulk.sourceUrls),
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
                        BulkReportsSection(
                          reports: _fullBulk!.subIncidents,
                          parentBulk: _fullBulk!,
                          onReportTap: _openSubIncidentDetail,
                          timeAgo: _timeAgo,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Navigate Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _navigatePressed = true),
                  onTapUp: (_) async {
                    setState(() => _navigatePressed = false);
                    if (widget.onNavigate != null) {
                      await widget.onNavigate!(bulk);
                      if (mounted && Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    } else {
                      final lat = bulk.center.latitude;
                      final lng = bulk.center.longitude;
                      final url = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                      if (mounted && Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  onTapCancel: () => setState(() => _navigatePressed = false),
                  child: AnimatedScale(
                    scale: _navigatePressed ? 0.96 : 1.0,
                    duration: _navigatePressed
                        ? const Duration(milliseconds: 80)
                        : const Duration(milliseconds: 300),
                    curve: _navigatePressed
                        ? Curves.easeIn
                        : Curves.easeOutBack,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            bulk.typeColor,
                            bulk.typeColor.withOpacity(0.75),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: bulk.typeColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Navigate To Location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.getSecondaryTextColor(),
            letterSpacing: 1.0,
          ),
        ),
      ],
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
