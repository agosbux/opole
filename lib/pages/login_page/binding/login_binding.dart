//lib/pages/login_page/binding/login_binding.dart
import 'package:get/get.dart';
import 'package:opole/pages/login_page/controller/login_controller.dart';
import 'package:opole/core/services/auth_service.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // âœ… Registrar AuthService como singleton permanente (una sola instancia en toda la app)
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(AuthService(), permanent: true);
    }
    
    // âœ… LoginController se inyecta lazy (se crea al navegar a esta pÃ¡gina)
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
