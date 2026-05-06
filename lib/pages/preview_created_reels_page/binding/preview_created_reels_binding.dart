import 'package:get/get.dart';
import 'package:opole/pages/preview_created_reels_page/controller/preview_created_reels_controller.dart';
import 'package:opole/utils/utils.dart';

class PreviewCreatedReelsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PreviewCreatedReelsController>(() => PreviewCreatedReelsController());
  }
}

