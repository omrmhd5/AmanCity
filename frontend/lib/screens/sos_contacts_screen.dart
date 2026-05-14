import 'package:flutter/material.dart';

import '../data/app_colors.dart';
import '../models/sos_contact.dart';
import '../services/sos/sos_service.dart';
import '../utils/app_theme.dart';
import '../widgets/sos_screen/sos_add_contact_dialog.dart';
import '../widgets/sos_screen/sos_contact_card.dart';

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
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.getCardBackgroundColor(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove Contact',
          style: TextStyle(
            color: AppTheme.getPrimaryTextColor(),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Remove "$name" from your SOS contacts?',
          style: TextStyle(
            color: AppTheme.getSecondaryTextColor(),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.getSecondaryTextColor()),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _contacts.removeWhere((c) => c.id == id));
              await _persist();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppTheme.getPrimaryTextColor(),
            size: 20,
          ),
          onPressed: () => widget.onBack != null
              ? widget.onBack!()
              : Navigator.of(context).pop(),
        ),
        title: Text(
          'SOS Contacts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.getPrimaryTextColor(),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.getBorderColor()),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.secondary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryHover],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security,
                          color: Colors.white54,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Trusted Circle',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Contacts receive your location via WhatsApp during an SOS alert',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                  height: 1.4,
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
                      Text(
                        'PRIORITY LIST',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getSecondaryTextColor(),
                          letterSpacing: 1.5,
                        ),
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
                    GestureDetector(
                      onTap: () => _showAddDialog(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.getBorderColor(),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: AppTheme.getSecondaryTextColor(),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _contacts.isEmpty
                                  ? 'Add First Contact'
                                  : 'Add ${_contacts.length + 1}${_ordinalSuffix(_contacts.length + 1)} Contact',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.getSecondaryTextColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
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
    );
  }

  String _ordinalSuffix(int n) {
    if (n == 2) return 'nd';
    if (n == 3) return 'rd';
    return 'th';
  }
}
