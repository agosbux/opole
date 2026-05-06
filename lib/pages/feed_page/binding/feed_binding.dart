//lib/pages/feed_page/binding/feed_binding.dart
import 'package:get/get.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';

class FeedBinding extends Bindings {
  @override
  void dependencies() {
    // âœ… FeedController se inyecta lazy (se crea al navegar a esta pÃ¡gina)
    Get.lazyPut<FeedController>(() => FeedController());
    
    // âœ… SupabaseClient ya es singleton global, no necesita registro aquÃ­
  }
}
