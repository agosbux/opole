//lib/pages/splash_screen_page/binding/splash_binding.dart
import 'package:get/get.dart';
import 'package:opole/pages/splash_screen_page/controller/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // âœ… SplashController se inyecta lazy
    Get.lazyPut<SplashController>(() => SplashController());
    
    // âœ… AuthService debe estar disponible (ya se registra en LoginBinding)
    // Si no estÃ¡ registrado, lo registramos aquÃ­ como fallback
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(AuthService(), permanent: true);
    }
  }
}
