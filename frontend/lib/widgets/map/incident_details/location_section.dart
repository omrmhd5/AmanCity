import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/app_theme.dart';
import '../../../models/map_incident.dart';
import '../../shared/custom_text.dart';

class LocationSection extends StatefulWidget {
  final MapIncident incident;

  const LocationSection({Key? key, required this.incident}) : super(key: key);

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
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
    final lat = widget.incident.position.latitude;
    final lng = widget.incident.position.longitude;
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    if (_mapStylePreference == 'dark') {
      return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=600x240&style=feature:all|element:labels|visibility:off&style=feature:water|element:geometry|color:0x0d0d0d&style=feature:all|element:geometry|color:0x222222&style=feature:road|element:geometry|color:0x333333&key=$apiKey';
    } else {
      return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=600x240&style=feature:all|element:labels|visibility:off&key=$apiKey';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
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
                        color: widget.incident.typeColor,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: widget.incident.typeColor.withOpacity(0.6),
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
                      color: AppTheme.getBackgroundColor().withOpacity(0.95),
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
                          text: widget.incident.city ?? 'Location',
                          size: 9,
                          weight: FontWeight.w500,
                          color: AppTheme.getSecondaryTextColor(),
                        ),
                        const SizedBox(height: 2),
                        CustomText(
                          text:
                              widget.incident.addressText?.substring(
                                0,
                                widget.incident.addressText!.length > 20
                                    ? 20
                                    : widget.incident.addressText!.length,
                              ) ??
                              'Unknown',
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
          // Location Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'LOCATION',
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppTheme.getSecondaryTextColor(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.incident.typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 20,
                        color: widget.incident.typeColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.incident.addressText != null)
                            CustomText(
                              text: widget.incident.addressText!,
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppTheme.getPrimaryTextColor(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          else
                            CustomText(
                              text:
                                  '${widget.incident.position.latitude.toStringAsFixed(4)}, ${widget.incident.position.longitude.toStringAsFixed(4)}',
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppTheme.getPrimaryTextColor(),
                            ),
                          const SizedBox(height: 4),
                          if (widget.incident.city != null)
                            CustomText(
                              text: widget.incident.city!,
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
    );
  }
}
