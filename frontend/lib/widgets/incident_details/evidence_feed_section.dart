import 'package:flutter/material.dart';
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
    final imageUrl = media.url.startsWith('http')
        ? media.url
        : 'http://10.0.2.2:5000/${media.url.replaceFirst('uploads/', '')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
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
        alignment: Alignment.center,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
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
