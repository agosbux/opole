// lib/pages/notifications/widget/notification_card.dart
// ===================================================================
// NOTIFICATION CARD - Widget reusable con acciones por tipo
// ===================================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/notification_model.dart';
import '../utils/notification_colors.dart';
import '../controller/notifications_controller.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onDismiss;
  
  const NotificationCard({
    Key? key,
    required this.notification,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();
    final isUnread = !notification.isRead;
    
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red[400],
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        onDismiss?.call();
        controller.deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () => controller.markAsRead(notification.id),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: NotificationColors.backgroundForType(notification.type),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.color.withOpacity(0.3),
              width: isUnread ? 2 : 1,
            ),
            // 🎨 Gradiente sutil para no leídas
            gradient: isUnread ? NotificationColors.unreadGradient(notification.type) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎨 Icono con badge de no leído
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: notification.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(notification.icon, color: notification.color, size: 20),
                    ),
                    if (isUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: notification.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                
                // 📝 Contenido principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: tipo + tiempo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: notification.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              notification.typeLabel.toUpperCase(),
                              style: TextStyle(
                                color: notification.color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Título
                      Text(
                        notification.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      
                      // Mensaje
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      
                      // 🆕 Acciones específicas por tipo
                      // ✅ CORREGIDO: nombre actual del enum
                      if (notification.type == NotificationType.loQuiero)
                        _buildLoQuieroActions(notification, controller),
                      
                      if (notification.pointsChanged != null)
                        _buildPointsBadge(notification.pointsChanged!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 🟠 Acciones para Lo Quiero: ver perfil del comprador y publicación
  Widget _buildLoQuieroActions(NotificationModel notif, NotificationsController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // 👤 Ver perfil del comprador (usa compradorId, clave real del backend)
          if (notif.compradorId != null)
            _ActionChip(
              label: 'Ver perfil',
              icon: Icons.person_outline,
              color: notif.color,
              onTap: () => ctrl.viewUserProfile(notif.compradorId!),
            ),
          
          // 🎬 Ver publicación (usa reelId)
          if (notif.reelId != null)
            _ActionChip(
              label: 'Ver "${notif.itemTitle ?? 'publicación'}"',
              icon: Icons.play_circle_outline,
              color: notif.color,
              onTap: () => ctrl.viewReel(notif.reelId!),
            ),
        ],
      ),
    );
  }
  
  // 📊 Badge de puntos (+10 / -3)
  Widget _buildPointsBadge(int points) {
    final isPositive = points > 0;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: (isPositive ? Colors.green : Colors.red).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isPositive ? Colors.green : Colors.red).withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
              size: 14,
              color: isPositive ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              '${isPositive ? '+' : ''}$points pts',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatWaitTime(DateTime waitUntil) {
    final diff = waitUntil.difference(DateTime.now());
    if (diff.inHours >= 24) {
      return '${diff.inDays}d ${diff.inHours % 24}h';
    }
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }
}

// 🎨 Chip de acción reusable
class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}