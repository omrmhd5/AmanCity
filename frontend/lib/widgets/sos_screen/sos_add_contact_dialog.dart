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
    return AlertDialog(
      backgroundColor: AppTheme.getCardBackgroundColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        widget.existingContact != null ? 'Edit Contact' : 'Add SOS Contact',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppTheme.getPrimaryTextColor(),
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                color: AppTheme.getPrimaryTextColor(),
                fontSize: 14,
              ),
              decoration: _fieldDecoration('Full Name', Icons.person_outline),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
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
                if (v == null || v.trim().isEmpty) return 'Phone is required';
                final digits = v.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 7) return 'Enter a valid phone number';
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Include country code without + or spaces. Example: 201001234567',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.getSecondaryTextColor().withOpacity(0.65),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.getSecondaryTextColor()),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
