import 'package:flutter/material.dart';
import 'package:opole/utils/constant.dart';
import 'package:opole/utils/utils.dart';
import 'package:get_storage/get_storage.dart';  // âœ… Import aÃ±adido

Future<Locale> getLocale() async {
  // âœ… Se leen los valores desde GetStorage en lugar de Database
  String languageCode = GetStorage().read("language") ?? "en";
  String countryCode = GetStorage().read("countryCode") ?? "US";

  Utils.showLog("Selected Language => $languageCode >>> $countryCode");
  return _locale(languageCode, countryCode);
}

Locale _locale(String languageCode, String countryCode) {
  return languageCode.isNotEmpty
      ? Locale(languageCode, countryCode)
      : const Locale(AppConstant.languageEn, AppConstant.countryCodeEn);
}
