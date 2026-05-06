// lib/pages/bottom_bar_page/binding/bottom_bar_binding.dart

import 'package:get/get.dart';
import 'package:opole/pages/bottom_bar_page/controller/bottom_bar_controller.dart';
import 'package:opole/core/services/auth_service.dart';
import 'package:opole/pages/search_page/controller/custom_search_controller.dart';
import 'package:opole/pages/profile_page/profile_controller.dart'; // ✅ NUEVO
import 'package:opole/pages/notifications/controller/notifications_controller.dart';
import 'package:opole/controllers/session_controller.dart';

class BottomBarBinding extends Bindings {
  @override
  void dependencies() {
    Get.log('🔌 [BINDING] BottomBarBinding ejecutado');

    // BottomBarController
    Get.lazyPut<BottomBarController>(() {
      Get.log('📦 [BINDING] BottomBarController registrado');
      return BottomBarController();
    });

    // AuthService (permanente)
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(AuthService(), permanent: true);
      Get.log('🔐 [BINDING] AuthService registrado (permanent: true)');
    }

    // CustomSearchController
    if (!Get.isRegistered<CustomSearchController>()) {
      Get.lazyPut<CustomSearchController>(
        () {
          Get.log('🔍 [BINDING] CustomSearchController registrado (fenix: true)');
          return CustomSearchController();
        },
        fenix: true,
      );
    }

    // NotificationsController
    if (!Get.isRegistered<NotificationsController>()) {
      Get.lazyPut<NotificationsController>(
        () {
          Get.log('🔔 [BINDING] NotificationsController registrado (fenix: true)');
          return NotificationsController();
        },
        fenix: true,
      );
    }

    // ✅ ProfileController para el perfil propio (usa el userId de sesión)
    if (!Get.isRegistered<ProfileController>()) {
      final sessionController = Get.find<SessionController>();
      final userId = sessionController.uid;
      Get.lazyPut<ProfileController>(
        () {
          Get.log('👤 [BINDING] ProfileController registrado con userId: $userId');
          return ProfileController(userId: userId);
        },
        fenix: true,
      );
    }
  }
}