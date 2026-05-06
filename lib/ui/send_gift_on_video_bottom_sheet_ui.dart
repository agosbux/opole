// ARCHIVO DUMMY COMPLETO - FUNCIONALIDAD DE GIFTS DESHABILITADA
// ESTE ARCHIVO ES CRÃTICO PARA QUE COMPILE

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/utils/utils.dart';

class SendGiftOnVideoBottomSheetUi {
  // MÃ©todo que piden los errores en preview_shorts_video_widget.dart y reels_widget.dart
  static Widget onShowGift() {
    return Container(); // Widget vacÃ­o
  }
  
  // MÃ©todo show que piden varios archivos
  static void show({required BuildContext context, String? videoId}) {
    // videoId es parÃ¡metro opcional - ignorarlo
    Get.snackbar(
      "InformaciÃ³n", 
      "FunciÃ³n de envÃ­o de regalos temporalmente deshabilitada",
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  // MÃ©todo que pide bottom_bar_controller.dart
  static Future<void> onGetGift() async {
    return; // No hacer nada
  }
}

