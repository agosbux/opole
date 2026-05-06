import 'package:get/get.dart';
import 'package:opole/pages/edit_profile_page/controller/edit_profile_controller.dart';
import 'package:opole/utils/utils.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
}

