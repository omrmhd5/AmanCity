import 'package:flutter/material.dart';
import '../models/osint_incident.dart';
import '../utils/app_theme.dart';
import '../widgets/news/news_details/news_detail_header.dart';
import '../widgets/news/news_details/news_location_section.dart';
import '../widgets/news/news_details/news_detail_confidence_section.dart';
import '../widgets/news/news_details/news_detail_sources_section.dart';

class NewsIncidentDetailSheet extends StatefulWidget {
  final OsintIncident incident;

  const NewsIncidentDetailSheet({Key? key, required this.incident})
    : super(key: key);

  @override
  State<NewsIncidentDetailSheet> createState() =>
      _NewsIncidentDetailSheetState();
}

class _NewsIncidentDetailSheetState extends State<NewsIncidentDetailSheet> {
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
          // Header (includes type chip)
          NewsDetailHeader(
            title: widget.incident.title,
            incidentType: widget.incident.type,
            onBackPressed: () => Navigator.pop(context),
          ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Location Section (map preview + details)
                  NewsLocationSection(incident: widget.incident),

                  // Confidence Section
                  NewsDetailConfidenceSection(incident: widget.incident),

                  // Sources Section (includes footer)
                  NewsDetailSourcesSection(incident: widget.incident),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
