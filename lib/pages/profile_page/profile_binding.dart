// lib/pages/profile_page/profile_binding.dart
import 'package:get/get.dart';
import 'profile_controller.dart';

class ProfileBinding extends Bindings {
  final String userId;

  ProfileBinding({required this.userId});

  @override
  void dependencies() {
    Get.lazyPut(() => ProfileController(userId: userId));
  }
}