// lib/utils/utils.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:opole/utils/constants.dart';

abstract class Utils {
  static RxBool isAppOpen = false.obs;

  /// Logs
  static void showLog(String text) {
    if (kDebugMode) {
      log(text);
    }
  }

  /// Toast
  static void showToast(
    String message, [
    Color? backgroundColor,
  ]) {
    if (Get.context == null) return;

    Get.snackbar(
      '',
      '',
      titleText: const SizedBox.shrink(),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor ?? Colors.black87,
      borderRadius: 30,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      duration: const Duration(seconds: 2),
    );
  }

  // >>>>> >>>>> PARA MOSTRAR EN LA UI (NO para formularios) <<<<< <<<<<
  static TextEditingController countryController = 
      TextEditingController(text: AppConstants.countryName);
  static TextEditingController flagController = 
      TextEditingController(text: AppConstants.countryFlag);
  
  // âœ… Controladores GLOBALES para MOSTRAR ubicaciÃ³n en otras pantallas
  static TextEditingController provinceController = TextEditingController();
  static TextEditingController cityController = TextEditingController();

  // âœ… Actualizar desde Firebase (llamar despuÃ©s de cargar/guardar)
  static void updateLocationFromFirebase(Map<String, dynamic> userData) {
    provinceController.text = userData['province'] ?? '';
    cityController.text = userData['city'] ?? '';
    countryController.text = userData['country'] ?? AppConstants.countryName;
    flagController.text = userData['countryFlagImage'] ?? AppConstants.countryFlag;
  }

  // âœ… Getters Ãºtiles para toda la app
  static String get fullLocation {
    if (provinceController.text.isNotEmpty && cityController.text.isNotEmpty) {
      return '${provinceController.text}, ${cityController.text}, Argentina';
    }
    return 'Argentina';
  }

  // >>>>> >>>>> Otras configuraciones (sin cambios) <<<<< <<<<<
  static int waterMarkSize = 25;
  static bool isShowWaterMark = false;
  static String waterMarkIcon = "";
  
  static final bool isShowReelsEffect = false;
  static final int shortsDuration = 0;
  static final String effectAndroidLicenseKey = "";
  static final String effectIosLicenseKey = "";
  static final String privacyPolicyLink = "";
  static final String termsOfUseLink = "";
  static const String serverSecret = "";
  static final String liveAppSign = "";
  static final int liveAppId = 0;
  static String razorpayTestKey = "";
  static String razorpayCurrencyCode = "";
  static String flutterWaveId = "";
  static String flutterWaveCurrencyCode = "";

  static Future<void> onInitCreateEngine() async {
    showLog("Live streaming engine disabled.");
  }

  static Future<void> onInitPayment() async {
    showLog("Payment system disabled.");
  }
}

// âœ… ESTO ARREGLALOS ERRORES DE .height Y .width EN TODA LA APP
extension SizeExtension on int {
  Widget get height => SizedBox(height: toDouble());
  Widget get width => SizedBox(width: toDouble());
}

