import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../config/app_config.dart';
import '../../../utils/app_theme.dart';
import '../../shared/video_player_dialog.dart';

class BulkMediaFeed extends StatelessWidget {
  final List<String> mediaUrls;
  final double itemSize;

  /// Optional: if provided, uses mediaType strings ('VIDEO'/'IMAGE') instead of
  /// file extension to detect video. Useful for sub-incident report cards.
  final List<String>? mediaTypes;

  const BulkMediaFeed({
    Key? key,
    required this.mediaUrls,
    this.itemSize = 130,
    this.mediaTypes,
  }) : super(key: key);

  String _resolveMediaUrl(String storedPath) {
    if (storedPath.startsWith('http')) return storedPath;
    String filePath = storedPath;
    if (filePath.startsWith('uploads/')) {
      filePath = filePath.substring(8);
    }
    final encoded = filePath.split('/').map(Uri.encodeComponent).join('/');
    return '${AppConfig.fileServerUrl}/$encoded';
  }

  bool _isVideo(String url, int index) {
    if (mediaTypes != null && index < mediaTypes!.length) {
      return mediaTypes![index].toUpperCase() == 'VIDEO';
    }
    return url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.mov') ||
        url.toLowerCase().endsWith('.avi') ||
        url.toLowerCase().endsWith('.mkv');
  }

  void _showVideoPlayer(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      builder: (_) => VideoPlayerDialog(videoUrl: url),
    );
  }

  void _showImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Container(
            color: Colors.black87,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'map.failed_to_load_image'.tr(),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final size = itemSize;
    final isSmall = size <= 80;
    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mediaUrls.length,
        separatorBuilder: (_, __) => SizedBox(width: isSmall ? 6 : 8),
        itemBuilder: (context, index) {
          final url = _resolveMediaUrl(mediaUrls[index]);
          if (_isVideo(url, index)) {
            return GestureDetector(
              onTap: () => _showVideoPlayer(context, url),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
                  color: Colors.grey[900],
                  border: Border.all(
                    color: AppTheme.getBorderColor(),
                    width: 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_fill,
                      size: isSmall ? 30 : 50,
                      color: const Color(0xFF00B3A4),
                    ),
                    Positioned(
                      top: isSmall ? 4 : 8,
                      right: isSmall ? 4 : 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 3 : 6,
                          vertical: isSmall ? 1 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B3A4),
                          borderRadius: BorderRadius.circular(isSmall ? 2 : 4),
                        ),
                        child: Text(
                          isSmall ? 'common.vid'.tr() : 'common.video'.tr(),
                          style: TextStyle(
                            fontSize: isSmall ? 6 : 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return GestureDetector(
            onTap: () => _showImageViewer(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: size,
                  height: size,
                  color: AppTheme.getBorderColor(),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
