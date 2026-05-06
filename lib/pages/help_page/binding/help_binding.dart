import 'package:get/get.dart';
import 'package:opole/pages/help_page/controller/help_controller.dart';
import 'package:opole/utils/utils.dart';

class HelpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelpController>(() => HelpController());
  }
}

