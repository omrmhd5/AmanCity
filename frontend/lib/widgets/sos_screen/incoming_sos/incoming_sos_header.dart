import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../utils/app_theme.dart';

class IncomingSosHeader extends StatelessWidget {
  const IncomingSosHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time = TimeOfDay.fromDateTime(now).format(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B3B).withOpacity(0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFFF3B3B).withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B3B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'sos.alert_received'.tr(),
                style: const TextStyle(
                  color: Color(0xFFFF3B3B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Today at $time',
          style: TextStyle(
            color: AppTheme.getSecondaryTextColor().withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
