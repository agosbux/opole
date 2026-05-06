import 'package:get/get.dart';
import 'package:opole/pages/terms_of_use_page/controller/terms_of_use_controller.dart';
import 'package:opole/utils/utils.dart';

class TermsOfUseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TermsOfUseController>(() => TermsOfUseController());
  }
}

