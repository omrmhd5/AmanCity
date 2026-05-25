import 'dart:ui';
import 'package:flutter/material.dart';

import '../../data/app_colors.dart';
import '../../models/sos/sos_contact.dart';
import '../../utils/app_theme.dart';

class SosAddContactDialog extends StatefulWidget {
  final SosContact? existingContact;
  final ValueChanged<SosContact> onSave;

  const SosAddContactDialog({
    Key? key,
    this.existingContact,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SosAddContactDialog> createState() => _SosAddContactDialogState();
}

class _SosAddContactDialogState extends State<SosAddContactDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  bool _savePressed = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingContact?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.existingContact?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(
        SosContact(
          id:
              widget.existingContact?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  InputDecoration _fieldDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTheme.getSecondaryTextColor().withOpacity(0.45),
        fontSize: 13,
      ),
      labelStyle: TextStyle(
        color: AppTheme.getSecondaryTextColor(),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: AppTheme.getSecondaryTextColor(), size: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.getBorderColor()),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingContact != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.getBackgroundColor().withOpacity(0.88),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.getBorderColor().withOpacity(0.2),
                width: 0.75,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.danger.withOpacity(0.2),
                            width: 0.75,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: AppColors.danger,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Contact' : 'Add SOS Contact',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getPrimaryTextColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      color: AppTheme.getPrimaryTextColor(),
                      fontSize: 14,
                    ),
                    decoration: _fieldDecoration(
                      'Full Name',
                      Icons.person_outline,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  // Phone field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      color: AppTheme.getPrimaryTextColor(),
                      fontSize: 14,
                    ),
                    decoration: _fieldDecoration(
                      'Phone (with country code)',
                      Icons.phone_outlined,
                      hint: 'e.g. 201001234567',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Phone is required';
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 7)
                        return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Include country code without + or spaces. Example: 201001234567',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.getSecondaryTextColor().withOpacity(0.65),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedScale(
                        scale: _savePressed ? 0.97 : 1.0,
                        duration: Duration(
                          milliseconds: _savePressed ? 80 : 300,
                        ),
                        curve: Curves.easeOut,
                        child: GestureDetector(
                          onTap: _save,
                          onTapDown: (_) => setState(() => _savePressed = true),
                          onTapUp: (_) => setState(() => _savePressed = false),
                          onTapCancel: () =>
                              setState(() => _savePressed = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.danger, Color(0xFFC0392B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
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
  }
}
