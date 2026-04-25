import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double? size;
  final FontWeight weight;
  final Color? color;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;
  final double? height;
  final TextStyle? baseStyle;

  const CustomText({
    Key? key,
    required this.text,
    this.size,
    this.weight = FontWeight.w400,
    this.color,
    this.textAlign = TextAlign.left,
    this.maxLines = 999,
    this.overflow = TextOverflow.clip,
    this.height,
    this.baseStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use provided baseStyle or create one from theme
    TextStyle style =
        baseStyle ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle();

    // Override with provided properties
    style = style.copyWith(
      fontSize: size ?? style.fontSize,
      fontWeight: weight,
      color: color ?? AppTheme.getPrimaryTextColor(),
      height: height ?? style.height,
    );

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: style,
    );
  }
}
