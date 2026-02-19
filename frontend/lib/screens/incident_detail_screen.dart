import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/map_incident.dart';
import '../widgets/incident_details/incident_detail_header.dart';
import '../widgets/incident_details/reporter_profile_card.dart';
import '../widgets/incident_details/evidence_feed_section.dart';
import '../widgets/incident_details/location_section.dart';

class IncidentDetailScreen extends StatefulWidget {
  final MapIncident incident;
  final String timeAgo;

  const IncidentDetailScreen({
    Key? key,
    required this.incident,
    required this.timeAgo,
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
            location: 'Cairo • Maadi Sector',
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

                    // Evidence Feed
                    EvidenceFeedSection(),
                    const SizedBox(height: 16),

                    // Location
                    LocationSection(incident: widget.incident),
                    const SizedBox(height: 24),
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
