import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';

class MapThemeSelector extends StatefulWidget {
  final bool isCompact;

  const MapThemeSelector({Key? key, this.isCompact = false}) : super(key: key);

  @override
  State<MapThemeSelector> createState() => _MapThemeSelectorState();
}

class _MapThemeSelectorState extends State<MapThemeSelector> {
  late SharedPreferences _prefs;
  String _mapStylePreference = 'dark';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMapStylePreference();
  }

  Future<void> _loadMapStylePreference() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _mapStylePreference = _prefs.getString('map_style_preference') ?? 'dark';
      _isLoading = false;
    });
  }

  Future<void> _setMapStylePreference(String style) async {
    await _prefs.setString('map_style_preference', style);
    setState(() {
      _mapStylePreference = style;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Map style changed to ${style == 'dark' ? 'Dark' : 'Light'}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
        ),
      );
    }

    if (widget.isCompact) {
      return _buildCompactTile();
    } else {
      return _buildFullTile();
    }
  }

  Widget _buildCompactTile() {
    return GestureDetector(
      onTap: () => _setMapStylePreference(
        _mapStylePreference == 'dark' ? 'light' : 'dark',
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getCardBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.getBorderColor(), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _mapStylePreference == 'dark'
                      ? Icons.dark_mode
                      : Icons.wb_sunny,
                  color: const Color(0xFF6366F1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Map Theme',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getPrimaryTextColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _mapStylePreference == 'dark'
                          ? 'Dark mode'
                          : 'Light mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getSecondaryTextColor(),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.getSecondaryTextColor(),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose between light and dark theme',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildToggleButtons(),
          const SizedBox(height: 12),
          Text(
            'This preference applies to both the main map and location picker',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.getSecondaryTextColor(),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.getBorderColor(), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildThemeButton(
              label: 'Light',
              icon: Icons.wb_sunny,
              isSelected: _mapStylePreference == 'light',
              onTap: () => _setMapStylePreference('light'),
              isLeft: true,
            ),
          ),
          Expanded(
            child: _buildThemeButton(
              label: 'Dark',
              icon: Icons.dark_mode,
              isSelected: _mapStylePreference == 'dark',
              onTap: () => _setMapStylePreference('dark'),
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppTheme.getBackgroundColor().withOpacity(0.5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isLeft ? 7 : 0),
            bottomLeft: Radius.circular(isLeft ? 7 : 0),
            topRight: Radius.circular(isLeft ? 0 : 7),
            bottomRight: Radius.circular(isLeft ? 0 : 7),
          ),
          border: isSelected
              ? Border.all(color: AppColors.secondary, width: 2)
              : null,
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.getPrimaryTextColor(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.getPrimaryTextColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
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
