// lib/pages/notifications/view/notifications_view.dart
// ===================================================================
// NOTIFICATIONS VIEW - Página de notificaciones con bottom bar integration
// ===================================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/utils/color.dart'; // Tu sistema de colores
import 'package:opole/utils/font_style.dart'; // Tus estilos de fuente
import '../controller/notifications_controller.dart';
import '../widget/notification_card.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    // 🛡️ Patrón seguro para Get.find()
    final NotificationsController? controller = _getControllerSafe();
    
    if (controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Notificaciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          // ✅ Botón "Marcar todas como leídas"
          Obx(() => controller.hasUnread.value
            ? IconButton(
                icon: const Icon(Icons.done_all, color: Colors.blueAccent),
                onPressed: () => controller.markAllAsRead(),
                tooltip: 'Marcar todas como leídas',
              )
            : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        
        if (controller.notifications.isEmpty) {
          return _buildEmptyState();
        }
        
        return RefreshIndicator(
          onRefresh: () => controller.fetchNotifications(refresh: true),
          color: Colors.blueAccent,
          backgroundColor: Colors.grey[900],
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 90), // Espacio para bottom bar
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return NotificationCard(
                notification: notification,
                onDismiss: () => controller.markAsRead(notification.id),
              );
            },
          ),
        );
      }),
    );
  }
  
  NotificationsController? _getControllerSafe() {
    try {
      return Get.find<NotificationsController>();
    } catch (_) {
      return null;
    }
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Sin notificaciones',
              style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Acá vas a recibir Lo Quiero, puntos y noticias de Opole',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}