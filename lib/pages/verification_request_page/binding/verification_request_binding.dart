import 'package:get/get.dart';
import 'package:opole/pages/verification_request_page/controller/verification_request_controller.dart';
import 'package:opole/utils/utils.dart';

class VerificationRequestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerificationRequestController>(() => VerificationRequestController());
  }
}

