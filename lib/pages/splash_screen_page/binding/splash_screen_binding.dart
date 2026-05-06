import 'package:get/get.dart';
import 'package:opole/pages/splash_screen_page/controller/splash_controller.dart';

class SplashScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}
