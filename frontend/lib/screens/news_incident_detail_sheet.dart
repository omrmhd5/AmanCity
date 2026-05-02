import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

                  // OSINT Source URLs (clickable links)
                  if (widget.incident.sourceUrls != null &&
                      widget.incident.sourceUrls!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSourceUrlsSection(widget.incident.sourceUrls!),
                  ],

                  // Sources Section (includes footer)
                  const SizedBox(height: 20),
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

  Widget _buildSourceUrlsSection(List<String> sourceUrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'SOURCES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.getSecondaryTextColor(),
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: sourceUrls.map((url) {
              return GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link,
                        size: 16,
                        color: Color(0xFF7C3AED),
                      ),
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
          ),
        ),
      ],
    );
  }
}
