import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../../models/map_incident.dart';
import '../shared/custom_text.dart';

class EvidenceFeedSection extends StatefulWidget {
  final MapIncident? incident;

  const EvidenceFeedSection({Key? key, this.incident}) : super(key: key);

  @override
  State<EvidenceFeedSection> createState() => _EvidenceFeedSectionState();
}

class _EvidenceFeedSectionState extends State<EvidenceFeedSection> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use incident media if available
    final mediaList = widget.incident?.media ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'EVIDENCE FEED',
                size: 11,
                weight: FontWeight.w700,
                color: AppTheme.getSecondaryTextColor(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.getBackgroundColor(),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.getBorderColor(),
                    width: 1,
                  ),
                ),
                child: CustomText(
                  text: '${mediaList.length} Items',
                  size: 10,
                  weight: FontWeight.w600,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (mediaList.isNotEmpty)
          // Carousel
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: mediaList.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildMediaItem(mediaList[index]),
              ),
            ),
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.getCardBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.getBorderColor(), width: 1),
            ),
            child: Center(
              child: CustomText(
                text: 'No evidence attached',
                size: 12,
                weight: FontWeight.w400,
                color: AppTheme.getSecondaryTextColor(),
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Page indicators
        if (mediaList.isNotEmpty)
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                mediaList.length,
                (index) => GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.secondary
                          : AppTheme.getBorderColor(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaItem(MediaItem media) {
    // Properly encode the URL path segments to handle spaces and special characters
    late String mediaUrl;
    if (media.url.startsWith('http')) {
      mediaUrl = media.url;
    } else {
      // Remove 'uploads/' prefix if present (backend already serves from uploads folder)
      String filePath = media.url;
      if (filePath.startsWith('uploads/')) {
        filePath = filePath.substring(8); // Remove 'uploads/' prefix
      }

      // Split path, encode each segment, rejoin
      final pathSegments = filePath.split('/');
      final encodedSegments = pathSegments
          .map((segment) => Uri.encodeComponent(segment))
          .toList();
      mediaUrl = '${AppConfig.fileServerUrl}/${encodedSegments.join('/')}';
    }

    final isVideo = media.mediaType.toUpperCase() == 'VIDEO';

    if (isVideo) {
      return _buildVideoItem(mediaUrl);
    }

    return GestureDetector(
      onTap: () => _showImageViewer(mediaUrl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.getBorderColor(), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildErrorWidget(),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomText(
                  text: media.mediaType.toUpperCase(),
                  size: 10,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            CustomText(
              text: 'Failed to load image',
              size: 12,
              weight: FontWeight.w400,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showImageViewer(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black87,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          CustomText(
                            text: 'Failed to load image',
                            size: 12,
                            weight: FontWeight.w400,
                            color: Colors.grey,
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
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 24),
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

  Widget _buildVideoItem(String videoUrl) {
    return GestureDetector(
      onTap: () => _showVideoPlayer(videoUrl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.getBorderColor(), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          color: Colors.grey[900],
        ),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 80,
                  color: AppColors.secondary,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomText(
                  text: 'VIDEO',
                  size: 10,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoPlayer(String videoUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.getCardBackgroundColor(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_library, size: 48, color: AppColors.secondary),
              const SizedBox(height: 16),
              CustomText(
                text: 'Video Available',
                size: 16,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              CustomText(
                text:
                    'Video playback is being improved. You can view this video at:',
                size: 12,
                weight: FontWeight.w400,
                color: AppTheme.getSecondaryTextColor(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.getBackgroundColor(),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.getBorderColor()),
                ),
                child: SelectableText(
                  videoUrl,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.secondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: CustomText(
                    text: 'Close',
                    size: 14,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
