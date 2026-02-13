import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

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
    this.color = AppColors.darkText,
    this.textAlign = TextAlign.left,
    this.maxLines = 999,
    this.overflow = TextOverflow.clip,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      ),
    );
  }
}
