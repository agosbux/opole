import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/profile_controller.dart';

class FeedsTabView extends GetView<ProfileController> {
  const FeedsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Mientras carga y la lista estÃ¡ vacÃ­a, mostramos indicador
      if (controller.isLoading.value && controller.loQuieroSent.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.loQuieroSent.isEmpty) {
        return const Center(
          child: Text('No has dado "Lo quiero" a ningÃºn reel'),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: controller.loQuieroSent.length,
        itemBuilder: (context, index) {
          final doc = controller.loQuieroSent[index];
          final data = doc as Map<String, dynamic>;
          final thumbnail = data['reelThumbnail'] ?? '';
          final status = data['status'] ?? 'pending';
          final reelId = data['reelId'] as String?;
          // âœ… CORRECCIÃ“N: usar otro nombre para la variable
          final timestamp = data['DateTime'] as DateTime?;
          final formattedTime = timestamp != null
              ? DateFormat('dd/MM/yy').format(timestamp)
              : '';

          return GestureDetector(
            onTap: () {
              // Navegar al detalle del reel (implementar segÃºn tu sistema de rutas)
              // Get.toNamed('/reel-detail', arguments: reelId);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (formattedTime.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        formattedTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
