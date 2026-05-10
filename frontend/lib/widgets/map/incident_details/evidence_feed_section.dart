import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_config.dart';
import '../../../utils/app_theme.dart';
import '../../../data/app_colors.dart';
import '../../../models/map_incident.dart';
import '../../shared/custom_text.dart';
import '../../shared/video_player_dialog.dart';

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
    final sourceUrls = widget.incident?.sourceUrls ?? [];
    final isOsint = widget.incident?.isOsint ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Evidence Feed Header (when media exists)
        if (mediaList.isNotEmpty)
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
        if (mediaList.isNotEmpty) const SizedBox(height: 12),
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
        else if (!isOsint)
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

        // Twitter source links for OSINT incidents
        if (isOsint && sourceUrls.isNotEmpty) ...[
          if (mediaList.isNotEmpty) const SizedBox(height: 16),
          // Sources Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: 'SOURCES',
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppTheme.getSecondaryTextColor(),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.getBackgroundColor(),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.getBorderColor(),
                      width: 1,
                    ),
                  ),
                  child: CustomText(
                    text: '${sourceUrls.length} Items',
                    size: 10,
                    weight: FontWeight.w600,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.getCardBackgroundColor(),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.getBorderColor(), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sourceUrls
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key != sourceUrls.length - 1 ? 8 : 0,
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
                                  text: entry.value,
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: Colors.blue,
                                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomText(
                text: '🤖 Detected by Grok AI from Twitter/X',
                size: 11,
                weight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _launchUrl(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open tweet link'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildMediaItem(MediaItem media) {
    final isVideo = media.mediaType.toUpperCase() == 'VIDEO';

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

    // For videos, just show play icon thumbnail
    if (isVideo) {
      return GestureDetector(
        onTap: () => _showVideoPlayer(mediaUrl),
        child: _buildVideoThumbnail(),
      );
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

  Widget _buildVideoThumbnail() {
    return Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    );
  }

  void _openVideoFromThumbnail(String videoUrl) {
    _showVideoPlayer(videoUrl);
  }

  void _showVideoPlayer(String videoUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      builder: (_) => VideoPlayerDialog(videoUrl: videoUrl),
    );
  }
}
