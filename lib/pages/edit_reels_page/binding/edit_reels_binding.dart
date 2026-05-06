import 'package:get/get.dart';
import 'package:opole/pages/edit_reels_page/controller/edit_reels_controller.dart';
import 'package:opole/utils/utils.dart';

class EditReelsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditReelsController>(() => EditReelsController());
  }
}

