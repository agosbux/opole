// ARCHIVO DUMMY TEMPORAL - LIVE FUNCIONALIDAD DESHABILITADA
// Este archivo existe solo para evitar errores de importaciÃ³n

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/utils/utils.dart';

class LiveUserSendGiftBottomSheetUi {
  static RxString giftUrl = "".obs;
  static RxInt giftType = 0.obs;
  static RxBool isShowGift = false.obs;
  
  static Widget onShowGift() {
    return Container(); // Widget vacÃ­o temporal
  }
  
  static void show({required BuildContext context, String? liveRoomId, String? senderUserId, String? receiverUserId}) {
    // ParÃ¡metros son opcionales - ignorarlos
    Get.snackbar(
      "InformaciÃ³n", 
      "FunciÃ³n de Live temporalmente deshabilitada",
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

