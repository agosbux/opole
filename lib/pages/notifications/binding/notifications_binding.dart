// lib/pages/notifications/binding/notifications_binding.dart
import 'package:get/get.dart';
import '../controller/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationsController>(() => NotificationsController(), fenix: true);
  }
}