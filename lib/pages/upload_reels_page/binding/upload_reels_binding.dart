import 'package:get/get.dart';
import 'package:opole/pages/upload_reels_page/controller/upload_reels_controller.dart';
import 'package:opole/utils/utils.dart';

class UploadReelsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UploadReelsController>(() => UploadReelsController());
  }
}

