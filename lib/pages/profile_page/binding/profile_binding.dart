import 'package:get/get.dart';
import 'package:opole/pages/profile_page/controller/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // ANTES (lazyPut - no se crea hasta que se necesita)
    // Get.lazyPut<ProfileController>(() => ProfileController());
    
    // AHORA (put - se crea inmediatamente)
    Get.put<ProfileController>(ProfileController(), permanent: true);
  }
}
