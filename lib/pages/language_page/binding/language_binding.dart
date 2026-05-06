import 'package:get/get.dart';
import 'package:opole/pages/language_page/controller/language_controller.dart';
import 'package:opole/utils/utils.dart';

class LanguageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LanguageController>(() => LanguageController());
  }
}

