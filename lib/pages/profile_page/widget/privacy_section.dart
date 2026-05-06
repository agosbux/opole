import 'package:flutter/material.dart';
import '../profile_controller.dart';
import '../profile_model.dart';
import '../../../utils/color.dart';
import '../../../utils/font_style.dart';

class PrivacySection extends StatelessWidget {
  final ProfileController controller;
  final ProfileModel profile;
  const PrivacySection({required this.controller, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacidad de contacto',
            style: AppFontStyle.styleW600(AppColor.black, 16),
          ),
          const SizedBox(height: 15),
          _buildSwitch(
            icon: Icons.phone,
            label: 'Mostrar teléfono',
            value: profile.showPhone,
            onChanged: (val) => controller.updatePrivacy(showPhone: val),
          ),
          const Divider(height: 20),
          _buildSwitch(
            icon: Icons.email,
            label: 'Mostrar email',
            value: profile.showEmail,
            onChanged: (val) => controller.updatePrivacy(showEmail: val),
          ),
          const Divider(height: 20),
          _buildSwitch(
            icon: Icons.location_on,
            label: 'Mostrar ubicación',
            value: profile.showLocation,
            onChanged: (val) => controller.updatePrivacy(showLocation: val),
          ),
          const Divider(height: 20),
          _buildSwitch(
            icon: Icons.person,
            label: 'Mostrar nombre completo',
            value: profile.showFullName,
            onChanged: (val) => controller.updatePrivacy(showFullName: val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: AppColor.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppFontStyle.styleW500(AppColor.black, 14),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColor.primary,
        ),
      ],
    );
  }
}