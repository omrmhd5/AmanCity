import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../data/app_colors.dart';
import '../../models/incidents/map_incident.dart';
import '../../widgets/map/incident_details/incident_detail_header.dart';
import '../../widgets/map/incident_details/reporter_profile_card.dart';
import '../../widgets/map/incident_details/confidence_section.dart';
import '../../widgets/map/incident_details/evidence_feed_section.dart';
import '../../widgets/map/incident_details/location_section.dart';

class IncidentDetailScreen extends StatefulWidget {
  final MapIncident incident;
  final String timeAgo;
  final Future<void> Function(MapIncident)? onNavigate;

  const IncidentDetailScreen({
    Key? key,
    required this.incident,
    required this.timeAgo,
    this.onNavigate,
  }) : super(key: key);

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  bool _navigatePressed = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: screenHeight * 0.92,
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundColor().withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.getBorderColor(),
                        borderRadius: BorderRadius.circular(2),
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
              // Header
              IncidentDetailHeader(
                incidentId: widget.incident.id,
                title: widget.incident.title,
                addressText: widget.incident.addressText,
                city: widget.incident.city,
                timestamp: widget.incident.timestamp,
                typeColor: widget.incident.typeColor,
                onBackPressed: () => Navigator.pop(context),
                onSharePressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share functionality coming soon'),
                    ),
                  );
                },
              ),
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Reporter & Incident Info
                        ReporterProfileCard(
                          incident: widget.incident,
                          timeAgo: widget.timeAgo,
                          reporterId:
                              widget.incident.reportedByName ?? 'Anonymous',
                          timestamp: widget.incident.timestamp,
                          description: widget.incident.description,
                        ),
                        const SizedBox(height: 16),

                        // AI Confidence
                        ConfidenceSection(incident: widget.incident),
                        const SizedBox(height: 16),

                        // Evidence Feed
                        EvidenceFeedSection(incident: widget.incident),
                        const SizedBox(height: 16),

                        // Location
                        LocationSection(incident: widget.incident),
                        const SizedBox(height: 24),
                      ],
                    ),
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
                      await widget.onNavigate!(widget.incident);
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    } else {
                      final lat = widget.incident.position.latitude;
                      final lng = widget.incident.position.longitude;
                      final String googleMapsUrl =
                          'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                        await launchUrl(
                          Uri.parse(googleMapsUrl),
                          mode: LaunchMode.externalApplication,
                        );
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
                            widget.incident.typeColor,
                            widget.incident.typeColor.withOpacity(0.75),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: widget.incident.typeColor.withOpacity(0.3),
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
}
