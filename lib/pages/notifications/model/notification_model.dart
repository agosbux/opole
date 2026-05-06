// lib/pages/notifications/model/notification_model.dart
// ===================================================================
// NOTIFICATION MODEL - Mapeado EXACTO a tu backend real
// ===================================================================

import 'package:flutter/material.dart';
import '../utils/notification_colors.dart';

enum NotificationType {
  loQuiero,              // 'lo_quiero'
  profilePointAdd,       // 'profile_point_add'
  profilePointSub,       // 'profile_point_sub'
  boostPointAdd,         // 'boost_point_add'
  boostPointSub,         // 'boost_point_sub'
  system,                // 'system'
  teSeleccionaron,       // 'te_seleccionaron' - NUEVO
  reelDisabledByReports, // 'reel_disabled_by_reports' - NUEVO
  unknown
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final Map<String, dynamic> data; // Tu columna JSONB
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  // 🔄 Factory para parsear respuesta EXACTA de tu tabla
  factory NotificationModel.fromSupabase(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String?)?.toLowerCase() ?? '';
    
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: _parseType(typeStr),
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      isRead: json['read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // 🎯 Títulos/mensajes: priorizar data.title/message, fallback a generación dinámica
  String get title => 
      data['title'] ?? switch (type) {
        NotificationType.loQuiero => '¡Nuevo Lo Quiero!',
        NotificationType.profilePointAdd || NotificationType.profilePointSub => 
          pointsValue > 0 ? '¡Puntos de Perfil!' : 'Puntos de Perfil',
        NotificationType.boostPointAdd || NotificationType.boostPointSub => 
          pointsValue > 0 ? '¡Puntos de Boost!' : 'Puntos de Boost',
        NotificationType.teSeleccionaron => '¡Te seleccionaron!',
        NotificationType.reelDisabledByReports => 'Reel deshabilitado',
        NotificationType.system => 'Notificación',
        _ => 'Notificación',
      };

  String get message {
    // ✅ Si backend ya envía message, usarlo (como en dar_lo_quiero)
    if (data['message'] != null && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    
    // 🔄 Fallback: generar dinámicamente si no viene
    return switch (type) {
      NotificationType.loQuiero => 
        'Recibiste interés en "${data['item_title'] ?? data['reel_title'] ?? 'tu publicación'}" de un usuario',
      NotificationType.profilePointAdd =>
        '+${pointsValue.abs()} pts por ${_actionLabel(data['action_id'] ?? '')}. ¡Seguí así!',
      NotificationType.profilePointSub =>
        '-${pointsValue.abs()} pts por ${_actionLabel(data['action_id'] ?? '')}. Revisá tu actividad.',
      NotificationType.boostPointAdd =>
        '+${pointsValue.abs()} pts por ${_actionLabel(data['action_id'] ?? '')}. ¡Subí en el feed!',
      NotificationType.boostPointSub =>
        '-${pointsValue.abs()} pts por ${_actionLabel(data['action_id'] ?? '')}.',
      NotificationType.teSeleccionaron => 
        '¡Felicitaciones! Fuiste seleccionado para ${data['opportunity_title'] ?? 'una oportunidad especial'}.',
      NotificationType.reelDisabledByReports => 
        'Tu reel "${data['reel_title'] ?? 'sin título'}" fue deshabilitado por acumular reportes.',
      NotificationType.system => data['message'] ?? '',
      _ => 'Notificación del sistema',
    };
  }

  // 🎨 UI Helpers
  Color get color => NotificationColors.forType(type);
  
  IconData get icon => switch (type) {
    NotificationType.loQuiero => Icons.favorite,
    NotificationType.profilePointAdd => Icons.person_add,
    NotificationType.profilePointSub => Icons.person_remove,
    NotificationType.boostPointAdd => Icons.trending_up,
    NotificationType.boostPointSub => Icons.trending_down,
    NotificationType.teSeleccionaron => Icons.stars,              // ⭐ NUEVO
    NotificationType.reelDisabledByReports => Icons.report_problem, // 🚫 NUEVO
    NotificationType.system => Icons.campaign,
    _ => Icons.notifications_none,
  };
  
  String get typeLabel => switch (type) {
    NotificationType.loQuiero => 'Lo Quiero',
    NotificationType.profilePointAdd || NotificationType.profilePointSub => 'Perfil',
    NotificationType.boostPointAdd || NotificationType.boostPointSub => 'Boost',
    NotificationType.teSeleccionaron => 'Selección',      // 🏆 NUEVO
    NotificationType.reelDisabledByReports => 'Reporte',  // ⚠️ NUEVO
    NotificationType.system => 'Sistema',
    _ => 'App',
  };

  // 📊 Getters seguros para keys REALES de tu backend
  int get pointsValue => (data['points'] as num?)?.toInt() ?? 0;
  
  // ✅ NUEVO: alias para compatibilidad con nombre usado en otras partes
  int? get pointsChanged => data['points'] as int?;
  
  // 🔹 Para lo_quiero: tu backend usa 'reel_id' y 'comprador_id'
  String? get reelId => data['reel_id'] as String?;
  String? get compradorId => data['comprador_id'] as String?; // ✅ KEY REAL
  String? get itemTitle => data['item_title'] as String?;     // ✅ KEY REAL del trigger
  
  // 🔹 Para puntos: action_id para label amigable
  String? get actionId => data['action_id'] as String?;
  
  // 🔹 Para te_seleccionaron
  String? get opportunityTitle => data['opportunity_title'] as String?;
  String? get opportunityId => data['opportunity_id'] as String?;
  
  // 🔹 Para reel_disabled_by_reports
  String? get reelTitle => data['reel_title'] as String?;
  int get reportCount => (data['report_count'] as num?)?.toInt() ?? 0;
  
  // 🔹 Para sistema: campos genéricos
  String? get systemTitle => data['title'] as String?;
  String? get systemMessage => data['message'] as String?;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return '${createdAt.day}/${createdAt.month}';
  }

  static NotificationType _parseType(String raw) {
    if (raw.contains('lo_quiero')) return NotificationType.loQuiero;
    if (raw.contains('profile') && raw.contains('add')) return NotificationType.profilePointAdd;
    if (raw.contains('profile') && raw.contains('sub')) return NotificationType.profilePointSub;
    if (raw.contains('boost') && raw.contains('add')) return NotificationType.boostPointAdd;
    if (raw.contains('boost') && raw.contains('sub')) return NotificationType.boostPointSub;
    if (raw.contains('te_seleccionaron')) return NotificationType.teSeleccionaron;           // NUEVO
    if (raw.contains('reel_disabled')) return NotificationType.reelDisabledByReports;        // NUEVO
    if (raw.contains('system') || raw.contains('noticia') || raw.contains('sugerencia')) return NotificationType.system;
    return NotificationType.unknown;
  }

  static String _actionLabel(String id) {
    const map = {
      'daily_login': 'iniciar sesión diariamente',
      'complete_profile': 'completar tu perfil',
      'publish_reel': 'publicar un Reel',
      'answer_question': 'responder una pregunta',
      'verify_phone': 'verificar tu teléfono',
      'invite_friend': 'invitar a un amigo',
      'lo_quiero_received': 'recibir un Lo Quiero',
      'penalty_no_response': 'no responder a tiempo',
      'penalty_inactive': 'inactividad prolongada',
    };
    return map[id] ?? 'una acción en la app';
  }
}