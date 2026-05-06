import 'package:get/get.dart';
import 'package:opole/pages/preview_user_profile_page/controller/preview_user_profile_controller.dart';
import 'package:opole/utils/utils.dart';

class PreviewUserProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PreviewUserProfileController>(() => PreviewUserProfileController());
  }
}

