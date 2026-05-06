import 'package:get/get.dart';
import 'package:opole/pages/edit_post_page/controller/edit_post_controller.dart';
import 'package:opole/utils/utils.dart';

class EditPostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditPostController>(() => EditPostController());
  }
}

