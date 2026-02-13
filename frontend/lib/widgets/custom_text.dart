import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;
  final double? height;

  const CustomText({
    Key? key,
    required this.text,
    this.size = 14,
    this.weight = FontWeight.w400,
    this.color = const Color(0xFF1A1A1A), // Will be overridden by theme
    this.textAlign = TextAlign.left,
    this.maxLines = 999,
    this.overflow = TextOverflow.clip,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use theme-aware color if using default
    final textColor = color == const Color(0xFF1A1A1A)
        ? AppTheme.getPrimaryTextColor()
        : color;

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: textColor,
        height: height,
      ),
    );
  }
}
