import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../custom_text.dart';

class MapSOSButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const MapSOSButton({Key? key, this.onPressed}) : super(key: key);

  @override
  State<MapSOSButton> createState() => _MapSOSButtonState();
}

class _MapSOSButtonState extends State<MapSOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onPressed?.call();
        _showSOSConfirmation();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring animation
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.3).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withOpacity(0.2),
              ),
            ),
          ),
          // Main button
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.danger, AppColors.danger.withOpacity(0.8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  widget.onPressed?.call();
                  _showSOSConfirmation();
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emergency, color: Colors.white, size: 28),
                    const SizedBox(height: 2),
                    CustomText(
                      text: 'SOS',
                      size: 10,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSOSConfirmation() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF121720)
              : const Color(0xFFF6F7F8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withOpacity(0.1),
              ),
              child: Icon(Icons.emergency, color: AppColors.danger, size: 28),
            ),
            const SizedBox(height: 16),
            CustomText(
              text: 'SOS Alert',
              size: 18,
              weight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.darkText,
            ),
            const SizedBox(height: 8),
            CustomText(
              text:
                  'Send your location to emergency contacts and nearby authorities?',
              size: 13,
              weight: FontWeight.w400,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CustomText(
                          text: 'Cancel',
                          size: 13,
                          weight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppColors.darkText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showSOSSuccess();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CustomText(
                          text: 'Send SOS',
                          size: 13,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSOSSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF121720)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            CustomText(
              text: 'SOS Alert Sent',
              size: 16,
              weight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.darkText,
            ),
            const SizedBox(height: 8),
            CustomText(
              text: 'Emergency contacts have been notified with your location.',
              size: 12,
              weight: FontWeight.w400,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: CustomText(
                    text: 'Got it',
                    size: 13,
                    weight: FontWeight.w600,
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
}
