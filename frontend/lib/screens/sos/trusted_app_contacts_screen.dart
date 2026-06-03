import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../models/sos/trusted_app_contact.dart';
import '../../services/sos/trusted_contacts_api_service.dart';

class TrustedAppContactsScreen extends StatefulWidget {
  const TrustedAppContactsScreen({Key? key}) : super(key: key);

  @override
  State<TrustedAppContactsScreen> createState() =>
      _TrustedAppContactsScreenState();
}

class _TrustedAppContactsScreenState extends State<TrustedAppContactsScreen>
    with SingleTickerProviderStateMixin {
  List<TrustedAppContact> _contacts = [];
  List<TrustedAppContact> _searchResults = [];
  bool _loading = true;
  bool _searching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    AppTheme.themeNotifier.addListener(_onThemeChange);
    _loadContacts();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entryController.dispose();
    AppTheme.themeNotifier.removeListener(_onThemeChange);
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, {double start = 0.0, double end = 1.0}) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    final contacts = await TrustedContactsApiService.getContacts();
    if (mounted)
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    final results = await TrustedContactsApiService.searchUsers(q.trim());
    if (!mounted) return;

    // Filter out users already in contacts list
    final existingIds = _contacts.map((c) => c.userId).toSet();
    final filtered = results
        .where((r) => !existingIds.contains(r.userId))
        .toList();
    setState(() {
      _searchResults = filtered;
      _searching = false;
    });
  }

  Future<void> _sendRequest(TrustedAppContact contact) async {
    final ok = await TrustedContactsApiService.sendRequest(contact.userId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request sent to ${contact.name}')),
      );
      setState(
        () => _searchResults.removeWhere((r) => r.userId == contact.userId),
      );
      await _loadContacts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sos.failed_to_send_request'.tr())),
      );
    }
  }

  Future<void> _respond(TrustedAppContact contact, bool accept) async {
    final ok = await TrustedContactsApiService.respondToRequest(
      contact.userId,
      accept: accept,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept ? 'sos.request_accepted'.tr() : 'sos.request_declined'.tr(),
          ),
        ),
      );
      await _loadContacts();
    }
  }

  Future<void> _remove(TrustedAppContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.currentMode == AppThemeMode.dark
                    ? AppColors.primary.withOpacity(0.85)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.getBorderColor(), width: 1),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.25),
                        width: 0.75,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_remove_rounded,
                      color: AppColors.danger,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'sos.remove_contact_title'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getPrimaryTextColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'sos.remove_contact_desc'.tr(namedArgs: {'name': contact.name}),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.getSecondaryTextColor(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                          ),
                          child: Text(
                            'common.cancel'.tr(),
                            style: TextStyle(
                              color: AppTheme.getSecondaryTextColor(),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'common.remove'.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await TrustedContactsApiService.removeContact(contact.userId);
    await _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    final incoming = _contacts.where((c) => c.isPendingIncoming).toList();
    final sent = _contacts.where((c) => c.isPendingSent).toList();
    final accepted = _contacts.where((c) => c.isAccepted).toList();
    final isSearchActive = _searchCtrl.text.trim().length >= 2;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppTheme.getPrimaryTextColor(),
            size: 25,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        title: Text(
          'sos.trusted_contacts_title'.tr(),
          style: TextStyle(
            color: AppTheme.getPrimaryTextColor(),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          _animated(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: AppTheme.getPrimaryTextColor()),
                decoration: InputDecoration(
                  hintText: 'sos.search_hint'.tr(),
                  hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor()),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.getSecondaryTextColor(),
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            color: AppTheme.getSecondaryTextColor(),
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.getCardBackgroundColor(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.getBorderColor()),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.getBorderColor()),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.secondary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _search,
              ),
            ),
            start: 0.0,
            end: 0.5,
          ),

          Expanded(
            child: _animated(
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Search results
                        if (isSearchActive) ...[
                          _sectionHeader('sos.search_results'.tr()),
                          if (_searching)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_searchResults.isEmpty)
                            _emptyHint('sos.no_users_found'.tr())
                          else
                            ..._searchResults.map(
                              (c) => _SearchResultTile(
                                contact: c,
                                onAdd: () => _sendRequest(c),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],

                        // Incoming requests
                        if (!isSearchActive && incoming.isNotEmpty) ...[
                          _sectionHeader('sos.pending_requests'.tr()),
                          ...incoming.map(
                            (c) => _ContactTile(
                              contact: c,
                              onAccept: () => _respond(c, true),
                              onDecline: () => _respond(c, false),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Sent requests
                        if (!isSearchActive && sent.isNotEmpty) ...[
                          _sectionHeader('sos.sent_requests'.tr()),
                          ...sent.map(
                            (c) => _ContactTile(
                              contact: c,
                              onRemove: () => _remove(c),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Accepted contacts
                        if (!isSearchActive) ...[
                          _sectionHeader(
                            '${'sos.trusted_contacts_title'.tr()} (${accepted.length})',
                          ),
                          if (accepted.isEmpty)
                            _emptyHint(
                              'sos.trusted_contacts_empty'.tr(),
                            )
                          else
                            ...accepted.map(
                              (c) => _ContactTile(
                                contact: c,
                                onRemove: () => _remove(c),
                              ),
                            ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
              start: 0.1,
              end: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.getSecondaryTextColor(),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: TextStyle(color: AppTheme.getSecondaryTextColor(), fontSize: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final TrustedAppContact contact;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onRemove;

  const _ContactTile({
    required this.contact,
    this.onAccept,
    this.onDecline,
    this.onRemove,
  });

  String get _initials {
    final parts = contact.name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  Color get _statusColor {
    switch (contact.status) {
      case 'accepted':
        return AppColors.secondary;
      case 'pending_incoming':
        return const Color(0xFFFFB547);
      default:
        return Colors.white.withOpacity(0.3);
    }
  }

  String get _statusLabel {
    switch (contact.status) {
      case 'accepted':
        return 'sos.status_trusted'.tr();
      case 'pending_incoming':
        return 'sos.status_wants_to_add'.tr();
      case 'pending_sent':
        return 'sos.status_request_sent'.tr();
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getBorderColor()),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor.withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                _initials,
                style: TextStyle(
                  color: AppTheme.getPrimaryTextColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name.isEmpty ? 'common.unknown'.tr() : contact.name,
                  style: TextStyle(
                    color: AppTheme.getPrimaryTextColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (contact.phone.isNotEmpty)
                  Text(
                    contact.phone,
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(),
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel,
                  style: TextStyle(color: _statusColor, fontSize: 11),
                ),
              ],
            ),
          ),

          // Actions
          if (contact.isPendingIncoming) ...[
            _iconBtn(Icons.check, AppColors.secondary, onAccept),
            const SizedBox(width: 4),
            _iconBtn(Icons.close, const Color(0xFFFF3B3B), onDecline),
          ] else if (onRemove != null)
            _iconBtn(Icons.remove_circle_outline, AppColors.danger, onRemove),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  final TrustedAppContact contact;
  final VoidCallback onAdd;

  const _SearchResultTile({required this.contact, required this.onAdd});

  String get _initials {
    final parts = contact.name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getBorderColor()),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                _initials,
                style: TextStyle(
                  color: AppTheme.getPrimaryTextColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name.isEmpty ? 'common.unknown'.tr() : contact.name,
                  style: TextStyle(
                    color: AppTheme.getPrimaryTextColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (contact.phone.isNotEmpty)
                  Text(
                    contact.phone,
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
              ),
              child: Text(
                'common.add'.tr(),
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
