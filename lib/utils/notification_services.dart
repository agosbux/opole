// ===================================================================
// âš ï¸ DEPRECADO: Este archivo maneja notificaciones con Firebase directo
// ===================================================================
// La nueva arquitectura usa:
// â€¢ lib/core/services/notification_service.dart (Supabase First)
//   â†’ Registra FCM token en tabla user_devices de Supabase
//   â†’ Escucha onMessage de FirebaseMessaging para notificaciones en foreground
//   â†’ Edge Function de Supabase envÃ­a push via Firebase Admin SDK
//
// âœ… QuÃ© mantener de Firebase:
// â€¢ firebase_messaging para recibir push nativos (solo cliente)
// â€¢ flutter_local_notifications para mostrar en foreground
//
// âŒ QuÃ© eliminar/migrar:
// â€¢ Registro de token en Firestore â†’ Ya cubierto por notification_service.dart
// â€¢ LÃ³gica de navegaciÃ³n por tipo de notificaciÃ³n â†’ Mover a un handler central
// ===================================================================
