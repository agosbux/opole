// lib/pages/search_page/binding/search_binding.dart
// ===================================================================
// SEARCH BINDING - InyecciÃ³n de dependencias + soporte para argumentos
// ===================================================================

import 'package:get/get.dart';
import 'package:opole/pages/search_page/controller/custom_search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    // âœ… Lazy put: se crea solo cuando se navega a /search
    // âœ… Fenix: false para que se limpie al salir y liberar memoria
    Get.lazyPut<CustomSearchController>(
      () => CustomSearchController(),
      fenix: false,
    );
  }
}
