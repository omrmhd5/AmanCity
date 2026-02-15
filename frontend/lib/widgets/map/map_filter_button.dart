import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'filter_options_sheet.dart';

class MapFilterButton extends StatelessWidget {
  final VoidCallback? onFilterPressed;

  const MapFilterButton({Key? key, this.onFilterPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor().withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onFilterPressed?.call();
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => const FilterOptionsSheet(),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Icon(
            Icons.tune,
            color: AppTheme.getPrimaryTextColor(),
            size: 20,
          ),
        ),
      ),
    );
  }
}
