import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
      return _VideoPlayerWidget(videoUrl: mediaUrl);
    }

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
              errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
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
                text: media.mediaType.toUpperCase(),
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
}

/// Video Player Widget for displaying MP4 videos with controls
class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );
    _initializeVideoPlayerFuture = _controller.initialize().catchError((error) {
      print('Video initialization error: $error');
      throw error;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FutureBuilder<void>(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      // Video container with proper sizing
                      Container(
                        color: Colors.black,
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                      // Play/Pause button overlay
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_controller.value.isPlaying) {
                                _controller.pause();
                              } else {
                                _controller.play();
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: AppColors.secondary,
                              size: 60,
                            ),
                          ),
                        ),
                      ),
                      // Progress bar at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          child: VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: AppColors.secondary,
                              backgroundColor: Colors.grey[600]!,
                              bufferedColor: Colors.grey[500]!,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          CustomText(
                            text: 'Failed to load video',
                            size: 12,
                            weight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          CustomText(
                            text: '${snapshot.error}',
                            size: 10,
                            weight: FontWeight.w300,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomText(
                            text: 'Loading video...',
                            size: 12,
                            weight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
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
}
