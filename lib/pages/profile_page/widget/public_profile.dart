import 'package:flutter/material.dart';
import '../profile_model.dart';
import '../../../utils/color.dart';
import '../../../utils/font_style.dart';

class PublicProfile extends StatelessWidget {
  final ProfileModel profile;
  const PublicProfile({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Badges de verificación
        Wrap(
          spacing: 8,
          children: [
            if (profile.verificadoMail)
              Chip(
                avatar: const Icon(Icons.verified, size: 18),
                label: const Text('Email verificado'),
              ),
            if (profile.verificadoWhatsapp)
              Chip(
                avatar: const Icon(Icons.phone_android, size: 18),
                label: const Text('WhatsApp'),
              ),
            if (profile.verificadoFacebook)
              Chip(
                avatar: const Icon(Icons.facebook, size: 18),
                label: const Text('Facebook'),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Botón de seguir (a implementar)
        ElevatedButton.icon(
          onPressed: () {
            // Acción de seguir
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Seguir'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 45),
          ),
        ),
        const SizedBox(height: 20),

        // Información de contacto (si el usuario lo permite)
        if (profile.showEmail && profile.email != null)
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(profile.email!),
          ),
        if (profile.showPhone && profile.telefono != null)
          ListTile(
            leading: const Icon(Icons.phone),
            title: Text(profile.telefono!),
          ),

        // Estadísticas públicas (reels, etc.)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Reputación: ${profile.reputation}'),
                Text('Nivel: ${profile.level}'),
                Text('Indicador de respuesta: ${profile.indicadorRespuesta ?? "N/A"}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}