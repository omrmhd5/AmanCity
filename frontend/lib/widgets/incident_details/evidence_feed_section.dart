import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../custom_text.dart';

class EvidenceFeedSection extends StatefulWidget {
  final List<String> evidenceItems;

  const EvidenceFeedSection({
    Key? key,
    this.evidenceItems = const ['Video', 'Audio', 'Photo'],
  }) : super(key: key);

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
                  text: '${widget.evidenceItems.length} Items',
                  size: 10,
                  weight: FontWeight.w600,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Carousel
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.evidenceItems.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildEvidenceItem(widget.evidenceItems[index], index),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Page indicators
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.evidenceItems.length,
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

  Widget _buildEvidenceItem(String type, int index) {
    if (index == 0) {
      // Main video item
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
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBstSYuFRW5unHGGq02g51v-z0fbp-jw56Bg5oNcrCLI9lMUHrOrfLk9fmVSdxjRgH0JhVfpylQw_Pjl0u1G-FnvrHiJoozouFvp1FQL7IbU3PoZr11bbPqzUA-LClWwc6cyges71M3d7-_ZG4MlmtbRBSg-yqua8Dl2dZAzuSa7e4-19jaoCTf7Ivl2M67uskWPlA6qKUV5Y1BWCCSnRx2ceLVmromivGr-bAHkUrF9nLtAM_fBB_62FZO0Dzw57fEV26MotT8FZxO',
                fit: BoxFit.cover,
              ),
            ),
            // Play button
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
            // Duration badge
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomText(
                  text: '00:14',
                  size: 11,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            // Badge label
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
      );
    } else if (index == 1) {
      // Audio item
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.getCardBackgroundColor().withOpacity(0.8),
              AppTheme.getBackgroundColor().withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.getBorderColor(), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.graphic_eq,
                    size: 32,
                    color: AppColors.secondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: CustomText(
                    text: 'AUDIO',
                    size: 10,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'Voice Note Transcript',
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppTheme.getPrimaryTextColor(),
                ),
                const SizedBox(height: 8),
                CustomText(
                  text:
                      '"Please help me, I can hear someone... I\'m scared..."',
                  size: 12,
                  weight: FontWeight.w400,
                  color: AppTheme.getSecondaryTextColor(),
                  height: 1.5,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                    const SizedBox(width: 4),
                    CustomText(
                      text: '00:08s',
                      size: 11,
                      weight: FontWeight.w500,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Photo item
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
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCQSMLHVnw5ZvYUbXhDn6-usRfVtUjUChuBbSdMNv0ZoXI8mIiUUyI67-w4Kjgdw0TgiFPowDZupZ49BLiVjSwL9wJEs4E073b456l_WOTpmHSH9E-0yEambVzCg6Imhy6xnJ11b4VkYxN71bcoPpQWa7C8-vnEUEFYLoRRJYC3BgUW-Oyb_lk_mqIosVLVnEr6ngL_AAAv7tOz-8RwrK2lh1KhG0d-p903Yfwis-y1cixHF-ulENzKB1faX03eTb89F-STWHWWY4EW',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Container(
              color: Colors.black.withOpacity(0.35),
              width: double.infinity,
              height: double.infinity,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.white.withOpacity(0.8),
                  size: 36,
                ),
                const SizedBox(height: 8),
                CustomText(
                  text: 'Sensitive content',
                  size: 12,
                  weight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 4),
                CustomText(
                  text: 'Tap to reveal',
                  size: 11,
                  weight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
            // Badge label
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CustomText(
                  text: 'PHOTO',
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
}
