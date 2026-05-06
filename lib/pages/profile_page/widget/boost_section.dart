import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../profile_controller.dart';
import '../profile_model.dart';
import '../../../controllers/session_controller.dart'; // Ajustar según tu proyecto
import '../../../utils/color.dart';
import '../../../utils/font_style.dart';

class BoostSection extends StatelessWidget {
  final ProfileController controller;
  final ProfileModel profile;
  const BoostSection({required this.controller, required this.profile});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>(); // Asegúrate de tener este controller

    return Obx(() {
      final boostCount = session.availableBoost.value;
      final canClaim = session.canClaimDailyBoost;
      final timeRemaining = session.timeUntilNextDailyBoost;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber[800], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Boost disponibles: $boostCount',
                  style: AppFontStyle.styleW700(AppColor.black, 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (canClaim)
              ElevatedButton(
                onPressed: () => controller.claimDailyBoost(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Reclamar boost diario',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Próximo boost en: ${_formatDuration(timeRemaining)}',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}