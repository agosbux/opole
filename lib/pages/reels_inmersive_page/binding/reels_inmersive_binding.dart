// lib/pages/reels_inmersive_page/binding/reels_inmersive_binding.dart
import 'package:get/get.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';

class ReelsInmersiveBinding extends Bindings {
  @override
  void dependencies() {
    // ðŸ”¹ FeedController YA estÃ¡ registrado como permanent en BottomBarController
    // No hace falta registrarlo de nuevo. Solo nos aseguramos de que exista.
    
    if (!Get.isRegistered<FeedController>()) {
      // âœ… Fallback: si por algÃºn motivo no existe, lo creamos como permanent
      Get.put<FeedController>(FeedController(), permanent: true);
    }
    
    // ðŸ”¹ Si en el futuro agregÃ¡s servicios especÃ­ficos del modo inmersive,
    // este es el lugar para registrarlos con lazyPut.
  }
}
