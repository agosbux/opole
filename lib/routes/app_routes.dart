// lib/routes/app_routes.dart
// ===================================================================
// APP ROUTES - Constantes de navegación
// ===================================================================

class AppRoutes {
  // ✅ SPLASH & AUTH
  static const String splashScreenPage = '/splash';
  static const String loginPage = '/login';
  static const String fillProfilePage = '/fill-profile';

  // ✅ MAIN NAVIGATION
  static const String bottomBarPage = '/bottom-bar';
  static const String feedPage = '/feed';
  
  // 🆕 MODO INMERSIVO (TikTok-style fullscreen)
  static const String reelsInmersivePage = '/reels-inmersive';

  // ✅ USER PROFILE
  static const String profilePage = '/profile';
  static const String editProfilePage = '/edit-profile';
  static const String previewUserProfilePage = '/preview-user';
  static const String verificationRequestPage = '/verification-request';

  // ✅ SETTINGS
  static const String settingPage = '/settings';
  static const String languagePage = '/language';
  static const String helpPage = '/help';
  static const String privacyPolicyPage = '/privacy';
  static const String termsOfUsePage = '/terms';

  // ✅ CONTENT CREATION
  static const String uploadReelsPage = '/upload-reels';
  static const String editReelsPage = '/edit-reels';
  static const String editPostPage = '/edit-post';
  static const String reelQuestionsPage = '/reel-questions';

  // ✅ SEARCH
  static const String searchPage = '/search';
  
  // 🆕 MIS OPOLE (antes "Mis Lo Quiero")
  static const String wishlistPage = '/wishlist';

  // 🆕 NOTIFICACIONES
  static const String notificationsPage = '/notifications';

  // 🔹 Ruta inicial de la app
  static const String initial = splashScreenPage;
}