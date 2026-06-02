import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import 'custom_text.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String placeholder;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool enabled;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.placeholder,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: CustomText(
              text: widget.label,
              size: 14,
              weight: FontWeight.w500,
              color: AppTheme.getPrimaryTextColor(),
            ),
          ),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {});
          },
          child: TextFormField(
            focusNode: _focusNode,
            controller: widget.controller,
            obscureText: _obscureText,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            enabled: widget.enabled,
            style: TextStyle(
              color: AppTheme.getPrimaryTextColor(),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                color: AppTheme.getSecondaryTextColor().withOpacity(0.6),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: _focusNode.hasFocus
                    ? AppColors.secondary
                    : AppTheme.getSecondaryTextColor().withOpacity(0.6),
              ),
              suffixIcon: widget.isPassword
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                      child: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.getSecondaryTextColor().withOpacity(
                          0.6,
                        ),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.currentMode == AppThemeMode.dark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.secondary.withOpacity(0.15),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppTheme.currentMode == AppThemeMode.dark
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.softGray,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.secondary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
