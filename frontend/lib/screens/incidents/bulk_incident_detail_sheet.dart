import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
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
import '../../utils/localization_formatter.dart';

class BulkIncidentDetailSheet extends StatefulWidget {
  final BulkIncident bulk;
  final Future<void> Function(BulkIncident)? onNavigate;

  const BulkIncidentDetailSheet({Key? key, required this.bulk, this.onNavigate})
    : super(key: key);

  @override
  State<BulkIncidentDetailSheet> createState() =>
      _BulkIncidentDetailSheetState();
}

class _BulkIncidentDetailSheetState extends State<BulkIncidentDetailSheet>
    with SingleTickerProviderStateMixin {
  BulkIncident? _fullBulk;
  bool _loading = true;
  bool _navigatePressed = false;
  late AnimationController _entryController;

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
    _loadFull();
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
    return LocalizationFormatter.formatTimeAgo(context, dt);
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
              // Header row with title on left and close button on right
              _animated(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.layers_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'incidents.bulk_incident'.tr(),
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
                start: 0.0,
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
                start: 0.05,
                end: 0.5,
              ),
              // Main content
              Flexible(
                child: _animated(
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BulkIncidentHeader(bulk: bulk, timeAgo: _timeAgo),
                        const SizedBox(height: 16),
                        BulkSourceChips(bulk: bulk),
                        const SizedBox(height: 20),
                        if (bulk.mediaUrls.isNotEmpty) ...[
                          _sectionLabel(
                            'incidents.media_evidence'.tr(),
                            Icons.image_rounded,
                          ),
                          const SizedBox(height: 10),
                          BulkMediaFeed(
                            mediaUrls: bulk.mediaUrls,
                            itemSize: 130,
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (bulk.sourceUrls.isNotEmpty) ...[
                          _sectionLabel(
                            'incidents.osint_sources'.tr(),
                            Icons.link_rounded,
                          ),
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
                        else if ((_fullBulk?.subIncidents ?? [])
                            .isNotEmpty) ...[
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
                  start: 0.15,
                  end: 0.75,
                ),
              ),
              // Navigate Button
              _animated(
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
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.navigation_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'map.navigate_to_location'.tr(),
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
                start: 0.4,
                end: 0.9,
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

    final timeAgo = LocalizationFormatter.formatTimeAgo(context, sub.timestamp);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          IncidentDetailScreen(incident: incident, timeAgo: timeAgo),
    );
  }
}
