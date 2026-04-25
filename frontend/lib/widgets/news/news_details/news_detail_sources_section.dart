import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/osint_incident.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/app_colors.dart';
import '../../shared/custom_text.dart';

class NewsDetailSourcesSection extends StatelessWidget {
  final OsintIncident incident;

  const NewsDetailSourcesSection({Key? key, required this.incident})
    : super(key: key);

  Future<void> _launchUrl(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Could not open tweet link'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: 'Sources',
            size: 14,
            weight: FontWeight.w600,
            color: AppTheme.getPrimaryTextColor(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.getCardBackgroundColor(),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.getBorderColor(), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: incident.sourceUrls
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key != incident.sourceUrls.length - 1
                            ? 8
                            : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => _launchUrl(entry.value, context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link, size: 14, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomText(
                                  text: 'Tweet #${entry.key + 1}',
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                size: 12,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Footer Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomText(
                text: '🤖 Detected by Grok AI from Twitter',
                size: 11,
                weight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
