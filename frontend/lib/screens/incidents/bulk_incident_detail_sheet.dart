import 'package:flutter/material.dart';
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

  const BulkIncidentDetailSheet({Key? key, required this.bulk})
    : super(key: key);

  @override
  State<BulkIncidentDetailSheet> createState() =>
      _BulkIncidentDetailSheetState();
}

class _BulkIncidentDetailSheetState extends State<BulkIncidentDetailSheet> {
  BulkIncident? _fullBulk;
  bool _loading = true;

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
                  BulkIncidentHeader(bulk: bulk, timeAgo: _timeAgo),
                  const SizedBox(height: 16),
                  BulkSourceChips(bulk: bulk),
                  const SizedBox(height: 20),
                  if (bulk.mediaUrls.isNotEmpty) ...[
                    _sectionLabel('Media Evidence'),
                    const SizedBox(height: 10),
                    BulkMediaFeed(mediaUrls: bulk.mediaUrls, itemSize: 130),
                    const SizedBox(height: 20),
                  ],
                  if (bulk.sourceUrls.isNotEmpty) ...[
                    _sectionLabel('OSINT Sources'),
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
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
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
