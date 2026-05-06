import 'package:flutter/material.dart';
import '../../../ui/preview_network_image_ui.dart';
import '../profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel profile;

  const ProfileHeader({super.key, required this.profile});

  String? get _locationText {
    if (profile.province != null && profile.locality != null) {
      return '${profile.locality}, ${profile.province}';
    }
    return profile.province ?? profile.locality;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar con placeholder de ícono
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade200,
          child: ClipOval(
            child: PreviewNetworkImageUi(
              image: profile.photoUrl,
              placeholder: Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
              errorWidget: Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.error, size: 50, color: Colors.red),
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Nombre completo (respetando privacidad)
        Text(
          profile.showFullName ? (profile.fullName ?? 'Usuario sin nombre') : 'Usuario',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        // Ubicación (si está permitido y existe)
        if (profile.showLocation && _locationText != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(_locationText!, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        const SizedBox(height: 8),
        // Género (opcional)
        if (profile.genero != null)
          Chip(
            label: Text(profile.genero!),
            backgroundColor: Colors.grey.shade100,
          ),
        const Divider(height: 32),
      ],
    );
  }
}