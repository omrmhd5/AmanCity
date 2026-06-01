import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../services/authority/authority_api_service.dart';
import '../../widgets/authority/authority_stats_grid.dart';
import '../../widgets/authority/authority_top_types_card.dart';
import '../../widgets/authority/authority_top_areas_card.dart';
import '../../widgets/authority/authority_incident_tile.dart';
import '../../widgets/shared/custom_text.dart';

class AuthorityDashboardScreen extends StatefulWidget {
  const AuthorityDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AuthorityDashboardScreen> createState() =>
      _AuthorityDashboardScreenState();
}

class _AuthorityDashboardScreenState extends State<AuthorityDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  AuthorityDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
          _dashboard = data;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 40,
              ),
              const SizedBox(height: 12),
              CustomText(
                text: _error!,
                size: 14,
                color: AppTheme.getSecondaryTextColor(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.4),
                    ),
                  ),
                  child: const CustomText(
                    text: 'Retry',
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final d = _dashboard!;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: RefreshIndicator(
          color: AppColors.secondary,
          backgroundColor: AppTheme.getCardBackgroundColor(),
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats grid ───────────────────────────────────────────
                AuthorityStatsGrid(stats: d.stats),
                const SizedBox(height: 20),

                // ── Source breakdown ─────────────────────────────────────
                _SourceBreakdownCard(
                  human: d.stats.human,
                  osint: d.stats.osint,
                ),
                const SizedBox(height: 16),

                // ── Top types ────────────────────────────────────────────
                AuthorityTopTypesCard(topTypes: d.topTypes),
                const SizedBox(height: 16),

                // ── Top areas ────────────────────────────────────────────
                AuthorityTopAreasCard(topAreas: d.topAreas),
                const SizedBox(height: 20),

                // ── Recent incidents ─────────────────────────────────────
                if (d.recentIncidents.isNotEmpty) ...[
                  CustomText(
                    text: 'RECENT INCIDENTS',
                    size: 11,
                    weight: FontWeight.w800,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                  const SizedBox(height: 10),
                  ...d.recentIncidents.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AuthorityIncidentTile(incident: i),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceBreakdownCard extends StatelessWidget {
  final int human;
  final int osint;

  const _SourceBreakdownCard({required this.human, required this.osint});

  @override
  Widget build(BuildContext context) {
    final total = human + osint;
    final humanRatio = total > 0 ? human / total : 0.0;
    final osintRatio = total > 0 ? osint / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: 'SOURCE BREAKDOWN',
            size: 11,
            weight: FontWeight.w800,
            color: AppTheme.getSecondaryTextColor(),
          ),
          const SizedBox(height: 14),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                if (humanRatio > 0)
                  Expanded(
                    flex: (humanRatio * 100).round(),
                    child: Container(height: 12, color: AppColors.success),
                  ),
                if (osintRatio > 0)
                  Expanded(
                    flex: (osintRatio * 100).round(),
                    child: Container(height: 12, color: AppColors.warning),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              _legendDot(AppColors.success),
              const SizedBox(width: 6),
              CustomText(text: 'Human', size: 12, weight: FontWeight.w600),
              const SizedBox(width: 4),
              CustomText(
                text: '$human (${(humanRatio * 100).round()}%)',
                size: 12,
                color: AppTheme.getSecondaryTextColor(),
              ),
              const SizedBox(width: 16),
              _legendDot(AppColors.warning),
              const SizedBox(width: 6),
              CustomText(text: 'OSINT', size: 12, weight: FontWeight.w600),
              const SizedBox(width: 4),
              CustomText(
                text: '$osint (${(osintRatio * 100).round()}%)',
                size: 12,
                color: AppTheme.getSecondaryTextColor(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
