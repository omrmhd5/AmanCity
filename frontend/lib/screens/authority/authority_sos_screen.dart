import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../services/authority/authority_api_service.dart';
import '../../widgets/authority/authority_sos_tile.dart';
import '../../widgets/shared/custom_text.dart';

class AuthoritySosScreen extends StatefulWidget {
  const AuthoritySosScreen({Key? key}) : super(key: key);

  @override
  State<AuthoritySosScreen> createState() => _AuthoritySosScreenState();
}

class _AuthoritySosScreenState extends State<AuthoritySosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  List<AuthoritySosSession> _sessions = [];
  bool _loading = true;
  String? _error;

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
          _sessions = data.activeSos;
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
        child: GestureDetector(
          onTap: _load,
          child: CustomText(
            text: 'common.error_tap_retry'.tr(),
            color: AppTheme.getSecondaryTextColor(),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: RefreshIndicator(
          color: AppColors.secondary,
          backgroundColor: AppTheme.getCardBackgroundColor(),
          onRefresh: _load,
          child: _sessions.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                            size: 44,
                          ),
                          const SizedBox(height: 12),
                          CustomText(
                            text: 'authority.no_sos_sessions'.tr(),
                            size: 15,
                            weight: FontWeight.w600,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      AuthoritySosTile(session: _sessions[i]),
                ),
        ),
      ),
    );
  }
}
