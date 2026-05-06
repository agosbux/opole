import 'package:get/get.dart';
import 'package:opole/pages/privacy_policy_page/controller/privacy_policy_controller.dart';
import 'package:opole/utils/utils.dart';

class PrivacyPolicyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrivacyPolicyController>(() => PrivacyPolicyController());
  }
}

