import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../profile_controller.dart';
import '../profile_model.dart';
import 'privacy_section.dart';
import 'boost_section.dart';
import 'stats_section.dart';
import '../../../utils/color.dart';
import '../../../utils/font_style.dart';

class OwnerDashboard extends StatelessWidget {
  final ProfileController controller;
  final ProfileModel profile;
  const OwnerDashboard({required this.controller, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de progreso de perfil
        _buildCompletionProgress(),
        const SizedBox(height: 20),

        // Nivel actual
        Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColor.primaryLinearGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Nivel ${profile.level}',
                  style: AppFontStyle.styleW700(AppColor.white, 28),
                ),
                Text(
                  'Nivel actual',
                  style: AppFontStyle.styleW400(AppColor.white, 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Sección de Boost
        BoostSection(controller: controller, profile: profile),
        const SizedBox(height: 20),

        // Sección de Privacidad
        PrivacySection(controller: controller, profile: profile),
        const SizedBox(height: 20),

        // Estadísticas privadas (reels, lo quiero, etc.)
        StatsSection(controller: controller, profile: profile),
        const SizedBox(height: 20),

        // Datos internos (XP, puntos)
        _buildInternalMetrics(),
      ],
    );
  }

  Widget _buildCompletionProgress() {
    final percentage = profile.completionPercentage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Perfil completado',
              style: AppFontStyle.styleW600(AppColor.black, 14),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: AppFontStyle.styleW600(AppColor.primary, 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade300,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColor.primary),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        if (!profile.profileCompleted)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Completa tu perfil y gana +30 puntos',
              style: AppFontStyle.styleW400(AppColor.primary, 12),
            ),
          ),
      ],
    );
  }

  Widget _buildInternalMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Métricas internas', style: AppFontStyle.styleW600(AppColor.black, 16)),
            const SizedBox(height: 10),
            Text('XP: ${profile.xp}'),
            Text('Puntos disponibles: ${profile.puntos}'),
            Text('Indicador de respuesta: ${profile.indicadorRespuesta ?? "N/A"}'),
            if (profile.progresoSiguienteNivel != null)
              Text(
                'Progreso: ${profile.progresoSiguienteNivel!['porcentaje']}%',
              ),
          ],
        ),
      ),
    );
  }
}