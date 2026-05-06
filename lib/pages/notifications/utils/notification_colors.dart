// lib/pages/notifications/utils/notification_colors.dart
// ===================================================================
// NOTIFICATION COLORS - Sistema de colores por tipo (centralizado)
// ===================================================================

import 'package:flutter/material.dart';
import '../model/notification_model.dart';

class NotificationColors {
  // 🎨 Colores base por tipo
  static const Color loQuiero = Color(0xFFFF9800);        // 🟠 Naranja
  static const Color profilePositive = Color(0xFF4CAF50);  // 🟢 Verde
  static const Color profileNegative = Color(0xFFE53935);  // 🔴 Rojo
  static const Color boostPositive = Color(0xFFBA68C8);    // 🟣 Púrpura
  static const Color boostNegative = Color(0xFFE53935);    // 🔴 Rojo
  static const Color system = Color(0xFF2196F3);           // 🔵 Azul
  static const Color teSeleccionaron = Color(0xFFFFD700);  // 🟡 Dorado
  static const Color reelDisabled = Color(0xFFD32F2F);     // 🔴 Rojo oscuro
  
  // 🎨 Backgrounds con opacidad para cards
  static Color backgroundForType(NotificationType type) {
    switch (type) {
      case NotificationType.loQuiero: 
        return loQuiero.withOpacity(0.12);
      case NotificationType.profilePointAdd: 
        return profilePositive.withOpacity(0.12);
      case NotificationType.profilePointSub: 
        return profileNegative.withOpacity(0.12);
      case NotificationType.boostPointAdd: 
        return boostPositive.withOpacity(0.12);
      case NotificationType.boostPointSub: 
        return boostNegative.withOpacity(0.12);
      case NotificationType.system: 
        return system.withOpacity(0.12);
      case NotificationType.teSeleccionaron: 
        return teSeleccionaron.withOpacity(0.12);
      case NotificationType.reelDisabledByReports: 
        return reelDisabled.withOpacity(0.12);
      case NotificationType.unknown: 
        return Colors.grey.withOpacity(0.12);
    }
  }
  
  // 🎨 Color principal para iconos/bordes
  static Color forType(NotificationType type) {
    switch (type) {
      case NotificationType.loQuiero: 
        return loQuiero;
      case NotificationType.profilePointAdd: 
        return profilePositive;
      case NotificationType.profilePointSub: 
        return profileNegative;
      case NotificationType.boostPointAdd: 
        return boostPositive;
      case NotificationType.boostPointSub: 
        return boostNegative;
      case NotificationType.system: 
        return system;
      case NotificationType.teSeleccionaron: 
        return teSeleccionaron;
      case NotificationType.reelDisabledByReports: 
        return reelDisabled;
      case NotificationType.unknown: 
        return Colors.grey;
    }
  }
  
  // 🎨 Gradiente para highlight en notificaciones no leídas
  static LinearGradient unreadGradient(NotificationType type) {
    final color = forType(type);
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        color.withOpacity(0.2),
        color.withOpacity(0.05),
        Colors.transparent,
      ],
    );
  }
}