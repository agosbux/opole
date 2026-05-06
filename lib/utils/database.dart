// ===================================================================
// âš ï¸ DEPRECADO: Este archivo usa API calls antiguos y GetStorage
// ===================================================================
// La nueva arquitectura usa:
// â€¢ SupabaseClient para datos de usuario
// â€¢ GetStorage solo para preferencias locales (idioma, notificaciones)
// â€¢ SessionController como Ãºnica fuente de verdad para el estado del usuario
//
// âœ… QuÃ© mantener:
// â€¢ Getters/setters de lenguaje y paÃ­s (GetStorage)
// â€¢ isShowNotification (GetStorage)
//
// âŒ QuÃ© migrar/eliminar:
// â€¢ fetchLoginUserProfileModel â†’ Usar SessionController.user.value
// â€¢ loginUserId, loginType â†’ Usar SupabaseClient.currentUserId
// â€¢ onLogOut() â†’ Usar AuthService.signOut() + SessionController.logout()
// ===================================================================
