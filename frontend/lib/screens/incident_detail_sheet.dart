import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../models/map_incident.dart';
import '../widgets/incident_details/incident_detail_header.dart';
import '../widgets/incident_details/reporter_profile_card.dart';
import '../widgets/incident_details/confidence_section.dart';
import '../widgets/incident_details/evidence_feed_section.dart';
import '../widgets/incident_details/location_section.dart';

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
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          // Header
          IncidentDetailHeader(
            incidentId: widget.incident.id,
            addressText: widget.incident.addressText,
            city: widget.incident.city,
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
              onTap: () async {
                if (widget.onNavigate != null) {
                  await widget.onNavigate!(widget.incident);
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                } else {
                  // Fallback: open Google Maps directly
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
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: widget.incident.typeColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: widget.incident.typeColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.navigation, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Navigate To Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
