import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/date_time_utils.dart';
import '../../../models/osint_incident.dart';
import '../../shared/custom_text.dart';

class NewsLocationSection extends StatefulWidget {
  final OsintIncident incident;

  const NewsLocationSection({Key? key, required this.incident})
    : super(key: key);

  @override
  State<NewsLocationSection> createState() => _NewsLocationSectionState();
}

class _NewsLocationSectionState extends State<NewsLocationSection> {
  String _mapStylePreference = 'dark';

  @override
  void initState() {
    super.initState();
    _loadMapStylePreference();
  }

  Future<void> _loadMapStylePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mapStylePreference = prefs.getString('map_style_preference') ?? 'dark';
    });
  }

  String _buildMapUrl() {
    final lat = widget.incident.latitude;
    final lng = widget.incident.longitude;
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    if (_mapStylePreference == 'dark') {
      return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=600x240&style=feature:all|element:labels|visibility:off&style=feature:water|element:geometry|color:0x0d0d0d&style=feature:all|element:geometry|color:0x222222&style=feature:road|element:geometry|color:0x333333&key=$apiKey';
    } else {
      return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=600x240&style=feature:all|element:labels|visibility:off&key=$apiKey';
    }
  }

  Future<void> _openGoogleMaps() async {
    final lat = widget.incident.latitude;
    final lng = widget.incident.longitude;
    final mapsUrl = Uri.parse('https://maps.app.goo.gl/?q=$lat,$lng');
    if (await canLaunchUrl(mapsUrl)) {
      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
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
            text: 'Location',
            size: 14,
            weight: FontWeight.w600,
            color: AppTheme.getPrimaryTextColor(),
          ),
          const SizedBox(height: 12),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.getCardBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.getBorderColor(), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Map Preview
                GestureDetector(
                  onTap: _openGoogleMaps,
                  child: Container(
                    height: 240,
                    color: AppTheme.getBackgroundColor(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(_buildMapUrl()),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          color: AppTheme.getBackgroundColor().withOpacity(0.2),
                        ),
                        // Map pin with glow
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Location info badge
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.getBackgroundColor().withOpacity(
                                0.95,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.getBorderColor(),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CustomText(
                                  text: 'Location',
                                  size: 9,
                                  weight: FontWeight.w500,
                                  color: AppTheme.getSecondaryTextColor(),
                                ),
                                const SizedBox(height: 2),
                                CustomText(
                                  text: widget.incident.locationText.substring(
                                    0,
                                    widget.incident.locationText.length > 20
                                        ? 20
                                        : widget.incident.locationText.length,
                                  ),
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: AppTheme.getPrimaryTextColor(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Location Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            text: 'LOCATION',
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                          CustomText(
                            text: DateTimeUtils.formatTime12Hour(
                              widget.incident.timestamp,
                            ),
                            size: 12,
                            weight: FontWeight.w900,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: widget.incident.locationText,
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: AppTheme.getPrimaryTextColor(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                CustomText(
                                  text:
                                      '${widget.incident.latitude.toStringAsFixed(4)}, ${widget.incident.longitude.toStringAsFixed(4)}',
                                  size: 11,
                                  weight: FontWeight.w400,
                                  color: AppTheme.getSecondaryTextColor(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
