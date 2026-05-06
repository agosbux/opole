import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/localization/localizations_delegate.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/database.dart';
import 'package:opole/utils/utils.dart';

class LanguageController extends GetxController {
  LanguageModel? languageModel;
  String? languageCode;
  String? countryCode;

  @override
  void onInit() {
    init();
    super.onInit();
  }

  final List countryFlags = [
    AppAsset.icArabia,
    AppAsset.icBangladesh,
    AppAsset.icChinese,
    AppAsset.icUnitedStates,
    AppAsset.icFrance,
    AppAsset.icGermany,
    AppAsset.icIndia,
    AppAsset.icItalian,
    AppAsset.icIndonesia,
    AppAsset.icJapan,
    AppAsset.icKorean,
    AppAsset.icIndia,
    AppAsset.icBrazil,
    AppAsset.icRussian,
    AppAsset.icSpain,
    AppAsset.icSwahili,
    AppAsset.icTurkey,
    AppAsset.icIndia,
    AppAsset.icIndia,
    AppAsset.icPakistan,
  ];

  void init() {
    languageCode = GetStorage().read("language") ?? "en";
    countryCode = GetStorage().read("countryCode") ?? "US";
    languageModel = languages
        .where((element) => (element.languageCode == languageCode && element.countryCode == countryCode))
        .toList()[0];
    update(["onChangeLanguage"]);
  }

  void onChangeLanguage(LanguageModel value) {
    languageModel = value;
    GetStorage().write("language", languageModel!.languageCode);
    GetStorage().write("countryCode", languageModel!.countryCode);

    Get.updateLocale(Locale(languageModel!.languageCode, languageModel!.countryCode));
    update(["onChangeLanguage"]);
  }
}

