import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../models/sos/sos_contact.dart';
import '../../services/sos/sos_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/sos_screen/sos_add_contact_dialog.dart';
import '../../widgets/sos_screen/sos_contact_card.dart';

class SosContactsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SosContactsScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<SosContactsScreen> createState() => _SosContactsScreenState();
}

class _SosContactsScreenState extends State<SosContactsScreen> {
  final SosService _sosService = SosService();
  List<SosContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await _sosService.getContacts();
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    }
  }

  Future<void> _persist() async {
    await _sosService.saveContacts(_contacts);
  }

  void _showAddDialog({SosContact? existing}) {
    showDialog(
      context: context,
      builder: (_) => SosAddContactDialog(
        existingContact: existing,
        onSave: (contact) async {
          setState(() {
            if (existing != null) {
              final idx = _contacts.indexWhere((c) => c.id == existing.id);
              if (idx != -1) {
                _contacts[idx] = contact;
              }
            } else {
              _contacts.add(contact);
            }
          });
          await _persist();
        },
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.currentMode == AppThemeMode.dark
                ? AppColors.primary
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorderColor(), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remove Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getPrimaryTextColor(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Remove "$name" from your SOS contacts?',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getSecondaryTextColor(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      setState(() => _contacts.removeWhere((c) => c.id == id));
                      await _persist();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.onBack != null
                        ? widget.onBack!()
                        : Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.getBackgroundColor().withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.getBorderColor().withOpacity(0.15),
                          width: 0.75,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.getPrimaryTextColor(),
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'SOS Contacts',
                    style: TextStyle(
                      color: AppTheme.getPrimaryTextColor(),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Teal gradient divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.secondary.withOpacity(0.0),
                    AppColors.secondary.withOpacity(0.3),
                    AppColors.secondary.withOpacity(0.0),
                  ]),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info banner
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.secondary.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  color: AppColors.secondary,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Trusted Circle',
                                        style: TextStyle(
                                          color: AppTheme.getPrimaryTextColor(),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Contacts receive your location via WhatsApp during an SOS alert',
                                        style: TextStyle(
                                          color: AppTheme.getSecondaryTextColor(),
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Header row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shield_rounded, size: 15, color: AppColors.secondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PRIORITY LIST',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.getSecondaryTextColor(),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_contacts.length}/5 added',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Contact list
                          if (_contacts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.person_add_outlined,
                                      size: 52,
                                      color: AppTheme.getSecondaryTextColor(),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'No contacts added yet',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.getPrimaryTextColor(),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tap the button below to add trusted contacts',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.getSecondaryTextColor(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...List.generate(
                              _contacts.length,
                              (i) => SosContactCard(
                                contact: _contacts[i],
                                priority: i + 1,
                                onEdit: () => _showAddDialog(existing: _contacts[i]),
                                onDelete: () =>
                                    _confirmDelete(_contacts[i].id, _contacts[i].name),
                              ),
                            ),

                          // Add slot placeholder (when under 5)
                          if (_contacts.length < 5)
                            _AddContactButton(
                              label: _contacts.isEmpty
                                  ? 'Add First Contact'
                                  : 'Add ${_contacts.length + 1}${_ordinalSuffix(_contacts.length + 1)} Contact',
                              onTap: () => _showAddDialog(),
                            ),

                          const SizedBox(height: 16),
                          Text(
                            'Contacts are notified in the order listed above when SOS is activated.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.getSecondaryTextColor().withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _ordinalSuffix(int n) {
    if (n == 2) return 'nd';
    if (n == 3) return 'rd';
    return 'th';
  }
}

// ---------------------------------------------------------------------------

class _AddContactButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _AddContactButton({required this.label, required this.onTap});

  @override
  State<_AddContactButton> createState() => _AddContactButtonState();
}

class _AddContactButtonState extends State<_AddContactButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: _pressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 300),
        curve: _pressed ? Curves.easeIn : Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.secondary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                color: AppColors.secondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
