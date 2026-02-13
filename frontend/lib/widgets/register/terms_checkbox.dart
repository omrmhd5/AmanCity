import 'package:flutter/material.dart';

class TermsCheckBox extends StatelessWidget {
  final bool isChecked;
  final Function(bool) onChanged;

  const TermsCheckBox({
    Key? key,
    required this.isChecked,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: isChecked,
              onChanged: (bool? newValue) {
                onChanged(newValue ?? false);
              },
              fillColor: MaterialStateProperty.all(
                isChecked ? Colors.white : Colors.transparent,
              ),
              checkColor: const Color(0xFF0B1D3A),
              side: BorderSide(
                color: isChecked ? Colors.white : const Color(0xFF404A5C),
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                  ),
                  TextSpan(
                    text: 'Terms of Service',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Handle terms tap
                      },
                  ),
                  const TextSpan(
                    text: ' and ',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Handle privacy policy tap
                      },
                  ),
                  const TextSpan(
                    text: '.',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
