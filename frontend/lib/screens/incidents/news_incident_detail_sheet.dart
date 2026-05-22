import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../models/incidents/osint_incident.dart';
import '../../utils/app_theme.dart';
import '../../widgets/news/news_details/news_detail_header.dart';
import '../../widgets/news/news_details/news_location_section.dart';
import '../../widgets/news/news_details/news_detail_confidence_section.dart';
import '../../widgets/news/news_details/news_detail_sources_section.dart';

class NewsIncidentDetailSheet extends StatefulWidget {
  final OsintIncident incident;

  const NewsIncidentDetailSheet({Key? key, required this.incident})
    : super(key: key);

  @override
  State<NewsIncidentDetailSheet> createState() =>
      _NewsIncidentDetailSheetState();
}

class _NewsIncidentDetailSheetState extends State<NewsIncidentDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

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
            color: AppTheme.getBackgroundColor().withOpacity(0.88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.getBorderColor(),
                        borderRadius: BorderRadius.circular(2),
                      ),
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
                // Header
                NewsDetailHeader(
                  title: widget.incident.title,
                  incidentType: widget.incident.type,
                  onBackPressed: () => Navigator.pop(context),
                ),
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        NewsLocationSection(incident: widget.incident),
                        NewsDetailConfidenceSection(incident: widget.incident),
                        const SizedBox(height: 20),
                        NewsDetailSourcesSection(incident: widget.incident),
                        const SizedBox(height: 24),
                      ],
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
}
