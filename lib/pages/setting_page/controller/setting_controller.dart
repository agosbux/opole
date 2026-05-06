import 'package:get/get.dart';
import 'package:opole/controllers/session_controller.dart';
import 'package:opole/custom/custom_share.dart';
import 'package:opole/ui/loading_ui.dart';

class SettingController extends GetxController {
  final SessionController sessionController = Get.find<SessionController>();

  bool isSharing = false;

  Future<void> logout() async {
    // El diÃ¡logo de confirmaciÃ³n ya existe, solo llamamos al mÃ©todo de sesiÃ³n
    sessionController.logout();
  }

  Future<void> deleteAccount() async {
    Get.back(); // Cierra el diÃ¡logo de confirmaciÃ³n
    Get.dialog(const LoadingUi(), barrierDismissible: false);
    try {
      await sessionController.deleteAccount();
    } catch (e) {
      Get.snackbar("Error", "No se pudo eliminar la cuenta. Vuelve a iniciar sesiÃ³n.");
    } finally {
      Get.back();
    }
  }

  Future<void> shareProfile() async {
    if (isSharing) return;
    isSharing = true;
    update();

    Get.dialog(const LoadingUi(), barrierDismissible: false);
    try {
      final link = await sessionController.generateReferralLink();
      await CustomShare.onShareLink(link: link);
    } catch (e) {
      Get.snackbar("Error", "No se pudo generar el enlace");
    } finally {
      Get.back();
      isSharing = false;
      update();
    }
  }
}

