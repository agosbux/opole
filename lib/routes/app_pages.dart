// lib/routes/app_pages.dart
// ===================================================================
// APP PAGES - Configuración de rutas con GetX
// ===================================================================
// ✅ Imports verificados que existen en tu proyecto
// ✅ Fixes de producción: preventDuplicates, iterable extension
// ✅ AuthMiddleware opcional (comentado, activar cuando quieras)
// ===================================================================

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:opole/core/extensions/iterable_extension.dart';
import 'app_routes.dart';

// ===================================================================
// 🔹 MIDDLEWARE: Auth Protection (OPCIONAL - Activar después)
// ===================================================================
/*
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<SessionController>()) return null;
    final session = Get.find<SessionController>();
    if (session.uid.isEmpty) {
      Get.offAllNamed(AppRoutes.loginPage);
      return null;
    }
    return null;
  }
}
*/

// ===================================================================
// 🔹 IMPORTS (Basados en tu versión que compilaba)
// ===================================================================
import 'package:opole/pages/bottom_bar_page/binding/bottom_bar_binding.dart';
import 'package:opole/pages/bottom_bar_page/view/bottom_bar_view.dart';
import 'package:opole/pages/edit_post_page/binding/edit_post_binding.dart';
import 'package:opole/pages/edit_post_page/view/edit_post_view.dart';
import 'package:opole/pages/edit_profile_page/binding/edit_profile_binding.dart';
import 'package:opole/pages/edit_profile_page/view/edit_profile_view.dart';
import 'package:opole/pages/edit_reels_page/binding/edit_reels_binding.dart';
import 'package:opole/pages/edit_reels_page/view/edit_reels_view.dart';
import 'package:opole/pages/feed_page/binding/feed_binding.dart';
import 'package:opole/pages/feed_page/view/feed_view.dart';
import 'package:opole/pages/fill_profile_page/binding/fill_profile_binding.dart';
import 'package:opole/pages/fill_profile_page/view/fill_profile_view.dart';
import 'package:opole/pages/help_page/binding/help_binding.dart';
import 'package:opole/pages/help_page/view/help_view.dart';
import 'package:opole/pages/language_page/binding/language_binding.dart';
import 'package:opole/pages/language_page/view/language_view.dart';
import 'package:opole/pages/login_page/binding/login_binding.dart';
import 'package:opole/pages/login_page/view/login_view.dart';
import 'package:opole/pages/preview_user_profile_page/binding/preview_user_profile_binding.dart';
import 'package:opole/pages/preview_user_profile_page/view/preview_user_profile_view.dart';
import 'package:opole/pages/privacy_policy_page/binding/privacy_policy_binding.dart';
import 'package:opole/pages/privacy_policy_page/view/privacy_policy_view.dart';
import 'package:opole/pages/profile_page/binding/profile_binding.dart';
import 'package:opole/pages/profile_page/view/profile_view.dart';
import 'package:opole/pages/search_page/binding/search_binding.dart';
import 'package:opole/pages/search_page/view/search_view.dart';
import 'package:opole/pages/setting_page/binding/setting_binding.dart';
import 'package:opole/pages/setting_page/view/setting_view.dart';
import 'package:opole/pages/splash_screen_page/binding/splash_screen_binding.dart';
import 'package:opole/pages/splash_screen_page/view/splash_screen_view.dart';
import 'package:opole/pages/terms_of_use_page/binding/terms_of_use_binding.dart';
import 'package:opole/pages/terms_of_use_page/view/terms_of_use_view.dart';
import 'package:opole/pages/upload_reels_page/binding/upload_reels_binding.dart';
import 'package:opole/pages/upload_reels_page/view/upload_reels_view.dart';
import 'package:opole/pages/verification_request_page/binding/verification_request_binding.dart';
import 'package:opole/pages/verification_request_page/view/verification_request_view.dart';

// 🆕 IMPORTS NUEVOS: Modo inmersivo, Mis Opole (Wishlist) y Notificaciones
import 'package:opole/pages/reels_inmersive_page/view/inmersive_reels_view.dart';
import 'package:opole/pages/reels_inmersive_page/binding/reels_inmersive_binding.dart';
import 'package:opole/pages/wishlist_page/binding/wishlist_binding.dart';
import 'package:opole/pages/wishlist_page/view/wishlist_view.dart';
import 'package:opole/pages/notifications/controller/notifications_controller.dart';
import 'package:opole/pages/notifications/view/notifications_view.dart';

// ===================================================================
// 🔹 APP PAGES - Tu estructura original + fixes + nuevas rutas
// ===================================================================
class AppPages {
  static final list = [
    // ===================================================================
    // ✅ SPLASH & AUTH
    // ===================================================================
    GetPage(
      name: AppRoutes.splashScreenPage,
      page: () => const SplashScreenView(),
      binding: SplashScreenBinding(),
      transition: Transition.noTransition,
      preventDuplicates: true,
    ),
    GetPage(
      name: AppRoutes.loginPage,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: Transition.fade,
      preventDuplicates: true,
    ),
    GetPage(
      name: AppRoutes.fillProfilePage,
      page: () => const FillProfileView(),
      binding: FillProfileBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
    ),

    // ===================================================================
    // ✅ MAIN NAVIGATION (BottomBar + Feed + Inmersive)
    // ===================================================================
    GetPage(
      name: AppRoutes.bottomBarPage,
      page: () => const BottomBarView(),
      binding: BottomBarBinding(),
      transition: Transition.noTransition,
      preventDuplicates: true,
    ),
    GetPage(
      name: AppRoutes.feedPage,
      page: () => const FeedView(),
      binding: FeedBinding(),
      preventDuplicates: true,
    ),

    // 🆕 MODO INMERSIVO (TikTok-style fullscreen)
    GetPage(
      name: AppRoutes.reelsInmersivePage,
      page: () => const InmersiveReelsView(),
      binding: ReelsInmersiveBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      popGesture: true,
      preventDuplicates: true,
    ),

    // 🆕 MIS OPOLE (antes "Wishlist")
    GetPage(
      name: AppRoutes.wishlistPage,
      page: () => const WishlistView(),
      binding: WishlistBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
      // middlewares: [AuthMiddleware()],
    ),

    // 🆕 NOTIFICACIONES
    GetPage(
      name: AppRoutes.notificationsPage,
      page: () => const NotificationsView(),
      //binding: NotificationsBinding(), // Asegúrate de crear este Binding
      transition: Transition.fade,
      preventDuplicates: true,
      // middlewares: [AuthMiddleware()],
    ),

    // ===================================================================
    // ✅ USER PROFILE & SETTINGS
    // ===================================================================
    GetPage(
      name: AppRoutes.profilePage,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
      // middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editProfilePage,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
      // middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.previewUserProfilePage,
      page: () => const PreviewUserProfileView(),
      binding: PreviewUserProfileBinding(),
      transition: Transition.cupertino,
      preventDuplicates: true,
    ),
    GetPage(
      name: AppRoutes.verificationRequestPage,
      page: () => const VerificationRequestView(),
      binding: VerificationRequestBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
      // middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.settingPage,
      page: () => const SettingView(),
      binding: SettingBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
      // middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.languagePage,
      page: () => const LanguageView(),
      binding: LanguageBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
    ),
    GetPage(
      name: AppRoutes.helpPage,
      page: () => const HelpView(),
      binding: HelpBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
    ),
    GetPage(
      name: AppRoutes.privacyPolicyPage,
      page: () => const PrivacyPolicyView(),
      binding: PrivacyPolicyBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
    ),
    GetPage(
      name: AppRoutes.termsOfUsePage,
      page: () => const TermsOfUseView(),
      binding: TermsOfUseBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
    ),

    // ===================================================================
    // ✅ CONTENT CREATION (Reels/Posts)
    // ===================================================================
    GetPage(
      name: AppRoutes.uploadReelsPage,
      page: () => const UploadReelsView(),
      binding: UploadReelsBinding(),
      transition: Transition.upToDown,
      preventDuplicates: true,
      // middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editReelsPage,
      page: () => const EditReelsView(),
      binding: EditReelsBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
      // middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editPostPage,
      page: () => const EditPostView(),
      binding: EditPostBinding(),
      transition: Transition.rightToLeft,
      preventDuplicates: true,
      // middlewares: [AuthMiddleware()],
    ),

    // ===================================================================
    // ✅ SEARCH & DISCOVERY
    // ===================================================================
    GetPage(
      name: AppRoutes.searchPage,
      page: () => const SearchView(),
      binding: SearchBinding(),
      transition: Transition.fade,
      preventDuplicates: true,
    ),
  ];

  // ===================================================================
  // 🔹 UTILS
  // ===================================================================
  static bool hasRoute(String routeName) => list.any((page) => page.name == routeName);
  static GetPage? getPage(String routeName) => list.firstWhereOrNull((page) => page.name == routeName);
}

// ===================================================================
// 🔔 RECORDATORIO: Crear NotificationsBinding
// ===================================================================
// Debes crear el archivo:
// lib/pages/notifications/binding/notifications_binding.dart
// con el siguiente contenido mínimo:
//
// import 'package:get/get.dart';
// import '../controller/notifications_controller.dart';
//
// class NotificationsBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut(() => NotificationsController());
//   }
// }