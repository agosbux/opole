import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/profile_controller.dart';

class ReelsTabView extends GetView<ProfileController> {
  const ReelsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos Obx para reaccionar a cambios en myReels
    return Obx(() {
      if (controller.isLoading.value && controller.myReels.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.myReels.isEmpty) {
        return const Center(child: Text('No hay reels publicados'));
      }

      return GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: controller.myReels.length,
        itemBuilder: (context, index) {
          final reelDoc = controller.myReels[index];
          final reelData = reelDoc as Map<String, dynamic>;
          final thumbnail = reelData['thumbnail'] ?? '';

          return GestureDetector(
            onTap: () {
              // Navegar a detalle del reel
              // TODO: Implementar navegaciÃ³n
            },
            child: Image.network(
              thumbnail,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey),
            ),
          );
        },
      );
    });
  }
}

