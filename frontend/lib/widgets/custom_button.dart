import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

enum ButtonSize { small, medium, large }

enum ButtonType { primary, secondary, tertiary }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonSize size;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.size = ButtonSize.large,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  double _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 44;
      case ButtonSize.large:
        return 56;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 13;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  Color _getBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;
    switch (type) {
      case ButtonType.primary:
        return AppColors.primary;
      case ButtonType.secondary:
        return AppColors.secondary;
      case ButtonType.tertiary:
        return AppColors.softGray;
    }
  }

  Color _getTextColor() {
    if (textColor != null) return textColor!;
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        return Colors.white;
      case ButtonType.tertiary:
        return AppColors.darkText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: _getHeight(),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          disabledBackgroundColor: _getBackgroundColor().withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
          shadowColor: _getBackgroundColor().withOpacity(0.3),
        ),
        child: isLoading
            ? SizedBox(
                height: _getHeight() * 0.5,
                width: _getHeight() * 0.5,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getTextColor(),
                  ),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: _getFontSize(),
                      fontWeight: FontWeight.w600,
                      color: _getTextColor(),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      icon,
                      color: _getTextColor(),
                      size: _getFontSize() + 2,
                    ),
                  ]
                ],
              ),
      ),
    );
  }
}
