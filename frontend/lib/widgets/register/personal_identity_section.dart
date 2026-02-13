import 'package:flutter/material.dart';
import '../custom_text_field.dart';
import '../custom_text.dart';
import '../../utils/app_colors.dart';

class PersonalIdentitySection extends StatefulWidget {
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final String? selectedCity;
  final Function(String?) onCityChanged;

  const PersonalIdentitySection({
    Key? key,
    required this.fullNameController,
    required this.phoneController,
    required this.selectedCity,
    required this.onCityChanged,
  }) : super(key: key);

  @override
  State<PersonalIdentitySection> createState() =>
      _PersonalIdentitySectionState();
}

class _PersonalIdentitySectionState extends State<PersonalIdentitySection> {
  final List<String> _cities = [
    'Cairo',
    'Alexandria',
    'Giza',
    'Shubra El-Kheima',
    'Port Said',
    'Suez',
    'Luxor',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section Divider
        _buildSectionDivider('Personal Identity'),
        const SizedBox(height: 16),
        // Full Name
        CustomTextField(
          label: 'Full Name',
          placeholder: 'e.g. Layla Ahmed',
          prefixIcon: Icons.person,
          controller: widget.fullNameController,
        ),
        const SizedBox(height: 20),
        // Phone Number
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(
              text: 'Phone Number',
              size: 14,
              weight: FontWeight.w500,
              color: AppColors.white,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162A4D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E3A66)),
                  ),
                  child: const CustomText(
                    text: '🇪🇬 +20',
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: '100 123 4567',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF162A4D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1E3A66)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1E3A66)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const CustomText(
              text: 'Used for emergency verification only.',
              size: 10,
              weight: FontWeight.w400,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Region / City
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(
              text: 'Region / City',
              size: 14,
              weight: FontWeight.w500,
              color: AppColors.white,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E3A66)),
              ),
              child: DropdownButton<String>(
                value: widget.selectedCity,
                hint: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: CustomText(
                    text: 'Select your city...',
                    color: const Color(0xFF94A3B8),
                    size: 14,
                  ),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                style: const TextStyle(color: AppColors.white, fontSize: 14),
                dropdownColor: const Color(0xFF162A4D),
                items: _cities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(city),
                    ),
                  );
                }).toList(),
                onChanged: widget.onCityChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionDivider(String title) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CustomText(
            text: title,
            size: 11,
            weight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.2)),
        ),
      ],
    );
  }
}
