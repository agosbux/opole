import 'package:get/get.dart';
import '../../services/contact_service.dart';

class ViewContactController extends GetxController {
  final ContactService _contactService = ContactService();

  RxBool isLoading = true.obs;
  RxMap<String, dynamic>? contact;

  late String reelId;

  @override
  void onInit() {
    reelId = Get.arguments;
    loadContact();
    super.onInit();
  }

  Future<void> loadContact() async {
    final result = await _contactService.getContact(reelId);

    if (result != null) {
      contact = result.obs;
    }

    isLoading.value = false;
  }
}

