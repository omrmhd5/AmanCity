import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../utils/app_theme.dart';
import '../../../../data/app_colors.dart';

class IncomingSosMapBackground extends StatefulWidget {
  final double lat;
  final double lng;

  const IncomingSosMapBackground({
    Key? key,
    required this.lat,
    required this.lng,
  }) : super(key: key);

  @override
  State<IncomingSosMapBackground> createState() => _IncomingSosMapBackgroundState();
}

class _IncomingSosMapBackgroundState extends State<IncomingSosMapBackground> {
  String? _cachedMapUrl;
  NetworkImage? _cachedMapImage;
  double? _cachedLat;
  double? _cachedLng;

  @override
  void initState() {
    super.initState();
    AppTheme.themeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) {
      setState(() {
        _cachedMapUrl = null;
        _cachedMapImage = null;
      });
    }
  }

  String _buildMapUrl() {
    final lat = widget.lat;
    final lng = widget.lng;
    if (lat == _cachedLat && lng == _cachedLng && _cachedMapUrl != null) {
      return _cachedMapUrl!;
    }
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    _cachedLat = lat;
    _cachedLng = lng;
    final isDark = AppTheme.currentMode == AppThemeMode.dark;
    final styleParams = isDark
        ? '&style=feature:all|element:labels|visibility:off'
          '&style=feature:water|element:geometry|color:0x060e1a'
          '&style=feature:all|element:geometry|color:0x0d1b2a'
          '&style=feature:road|element:geometry|color:0x1a3050'
        : '&style=feature:all|element:labels|visibility:off';
    _cachedMapUrl =
        'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=14'
        '&size=640x640'
        '&markers=color:red%7C$lat,$lng'
        '$styleParams'
        '&key=$apiKey';
    return _cachedMapUrl!;
  }

  ImageProvider _buildMapImage() {
    final url = _buildMapUrl();
    if (_cachedMapImage != null && _cachedMapUrl == url) {
      return _cachedMapImage!;
    }
    _cachedMapImage = NetworkImage(url);
    return _cachedMapImage!;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ColoredBox(color: AppTheme.getBackgroundColor()),
        ),
        Positioned.fill(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 1200),
            opacity: 1.0,
            child: Image(
              image: _buildMapImage(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.getBackgroundColor().withOpacity(0.15),
                  AppTheme.getBackgroundColor().withOpacity(0.97),
                ],
                stops: const [0.0, 0.65],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(color: AppColors.danger.withOpacity(0.06)),
        ),
      ],
    );
  }
}
