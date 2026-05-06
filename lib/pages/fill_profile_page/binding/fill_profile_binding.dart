import 'package:get/get.dart';
import 'package:opole/pages/fill_profile_page/controller/fill_profile_controller.dart';
import 'package:opole/utils/utils.dart';

class FillProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FillProfileController>(() => FillProfileController());
  }
}

