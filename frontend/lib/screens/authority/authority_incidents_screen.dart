import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../services/authority/authority_api_service.dart';
import '../../widgets/authority/authority_incident_tile.dart';
import '../../widgets/shared/custom_text.dart';

class AuthorityIncidentsScreen extends StatefulWidget {
  const AuthorityIncidentsScreen({Key? key}) : super(key: key);

  @override
  State<AuthorityIncidentsScreen> createState() =>
      _AuthorityIncidentsScreenState();
}

class _AuthorityIncidentsScreenState extends State<AuthorityIncidentsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  List<AuthorityIncident> _all = [];
  List<AuthorityIncident> _filtered = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL'; // ALL | HUMAN | OSINT

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AuthorityApiService.instance.fetchDashboard();
      if (mounted) {
        setState(() {
          _all = data.recentIncidents;
          _applyFilter();
          _loading = false;
        });
        _animCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _applyFilter() {
    if (_filter == 'HUMAN') {
      _filtered = _all.where((i) => !i.isOsint).toList();
    } else if (_filter == 'OSINT') {
      _filtered = _all.where((i) => i.isOsint).toList();
    } else {
      _filtered = List.from(_all);
    }
  }

  void _setFilter(String f) {
    setState(() {
      _filter = f;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }

    if (_error != null) {
      return Center(
        child: GestureDetector(
          onTap: _load,
          child: CustomText(
            text: 'Error. Tap to retry.',
            color: AppTheme.getSecondaryTextColor(),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _chip('ALL'),
                  const SizedBox(width: 8),
                  _chip('HUMAN'),
                  const SizedBox(width: 8),
                  _chip('OSINT'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.secondary,
                backgroundColor: AppTheme.getCardBackgroundColor(),
                onRefresh: _load,
                child: _filtered.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 60),
                          Center(
                            child: CustomText(
                              text: 'No incidents found.',
                              color: AppTheme.getSecondaryTextColor(),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            AuthorityIncidentTile(incident: _filtered[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    final isSelected = _filter == label;
    return GestureDetector(
      onTap: () => _setFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withOpacity(0.15)
              : AppTheme.getCardBackgroundColor(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.secondary.withOpacity(0.5)
                : AppTheme.getBorderColor(),
          ),
        ),
        child: CustomText(
          text: label,
          size: 12,
          weight: FontWeight.w600,
          color: isSelected
              ? AppColors.secondary
              : AppTheme.getSecondaryTextColor(),
        ),
      ),
    );
  }
}
