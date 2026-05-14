import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  const CustomSearchBar({
    Key? key,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.suffix,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.currentMode == AppThemeMode.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? AppColors.secondary.withOpacity(0.18)
                : Colors.black.withOpacity(isDark ? 0.28 : 0.08),
            blurRadius: _isFocused ? 16 : 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Stack(
            children: [
              // Glass base
              Container(
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.primary.withOpacity(0.58),
                            AppColors.primary.withOpacity(0.44),
                          ]
                        : [
                            Colors.white.withOpacity(0.72),
                            Colors.white.withOpacity(0.55),
                          ],
                  ),
                  border: Border.all(
                    color: _isFocused
                        ? AppColors.secondary.withOpacity(0.45)
                        : isDark
                        ? Colors.white.withOpacity(0.10)
                        : Colors.white.withOpacity(0.65),
                    width: _isFocused ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          Icons.search,
                          key: ValueKey(_isFocused),
                          color: _isFocused
                              ? AppColors.secondary
                              : AppTheme.getSecondaryTextColor(),
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: widget.onChanged,
                        style: TextStyle(
                          color: AppTheme.getPrimaryTextColor(),
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                            color: AppTheme.getSecondaryTextColor(),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 0,
                          ),
                        ),
                      ),
                    ),
                    if (widget.suffix != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: widget.suffix,
                      ),
                  ],
                ),
              ),

              // Specular highlight
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(isDark ? 0.30 : 0.75),
                          Colors.white.withOpacity(isDark ? 0.14 : 0.45),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.25, 0.75, 1.0],
                      ),
                    ),
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
