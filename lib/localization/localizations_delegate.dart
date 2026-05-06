import 'package:get/get.dart';
import 'package:opole/localization/languages/language_ar.dart';
import 'package:opole/localization/languages/language_bn.dart';
import 'package:opole/localization/languages/language_de.dart';
import 'package:opole/localization/languages/language_es.dart';
import 'package:opole/localization/languages/language_fr.dart';
import 'package:opole/localization/languages/language_hi.dart';
import 'package:opole/localization/languages/language_id.dart';
import 'package:opole/localization/languages/language_it.dart';
import 'package:opole/localization/languages/language_ja.dart';
import 'package:opole/localization/languages/language_ko.dart';
import 'package:opole/localization/languages/language_mr.dart';
import 'package:opole/localization/languages/language_pt.dart';
import 'package:opole/localization/languages/language_ru.dart';
import 'package:opole/localization/languages/language_sw.dart';
import 'package:opole/localization/languages/language_ta.dart';
import 'package:opole/localization/languages/language_te.dart';
import 'package:opole/localization/languages/language_tr.dart';
import 'package:opole/localization/languages/language_ur.dart';
import 'package:opole/localization/languages/language_zh.dart';

import 'languages/language_en.dart';
import 'package:opole/utils/utils.dart';

class AppLanguages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        "ar_DZ": arDZ,
        "bn_In": bnIn,
        "zh_CN": zhCN,
        "en_US": enUS,
        "fr_Fr": frFr,
        "de_De": deDe,
        "hi_IN": hiIN,
        "it_In": itIn,
        "id_ID": idID,
        "ja_JP": jaJP,
        "ko_KR": koKR,
        "mr_IN": mrIN,
        "pt_PT": ptPT,
        "ru_RU": ruRU,
        "es_ES": esES,
        "sw_KE": swKE,
        "tr_TR": trTR,
        "te_IN": teIN,
        "ta_IN": taIN,
        "ur_PK": urPK,
      };
}

final List<LanguageModel> languages = [
  LanguageModel("dz", "Arabic (Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©)", 'ar', 'DZ'),
  LanguageModel("ðŸ‡®ðŸ‡³", "Bengali (à¦¬à¦¾à¦‚à¦²à¦¾)", 'bn', 'IN'),
  LanguageModel("ðŸ‡¨ðŸ‡³", "Chinese Simplified (ä¸­å›½äºº)", 'zh', 'CN'),
  LanguageModel("ðŸ‡ºðŸ‡¸", "English (English)", 'en', 'US'),
  LanguageModel("ðŸ‡«ðŸ‡·", "French (franÃ§ais)", 'fr', 'FR'),
  LanguageModel("ðŸ‡©ðŸ‡ª", "German (Deutsche)", 'de', 'DE'),
  LanguageModel("ðŸ‡®ðŸ‡³", "Hindi (à¤¹à¤¿à¤‚à¤¦à¥€)", 'hi', 'IN'),
  LanguageModel("ðŸ‡®ðŸ‡¹", "Italian (italiana)", 'it', 'IT'),
  LanguageModel("ðŸ‡®ðŸ‡©", "Indonesian (bahasa indo)", 'id', 'ID'),
  LanguageModel("ðŸ‡¯ðŸ‡µ", "Japanese (æ—¥æœ¬èªž)", 'ja', 'JP'),
  LanguageModel("ðŸ‡°ðŸ‡µ", "Korean (í•œêµ­ì¸)", 'ko', 'KR'),
  LanguageModel("ðŸ‡®ðŸ‡³", "Marathi (à¤®à¤°à¤¾à¤ à¥€)", 'mr', 'IN'),
  LanguageModel("ðŸ‡µðŸ‡¹", "Portuguese (portuguÃªs)", 'pt', 'PT'),
  LanguageModel("ðŸ‡·ðŸ‡º", "Russian (Ñ€ÑƒÑÑÐºÐ¸Ð¹)", 'ru', 'RU'),
  LanguageModel("ðŸ‡ªðŸ‡¸", "Spanish (EspaÃ±ol)", 'es', 'ES'),
  LanguageModel("ðŸ‡°ðŸ‡ª", "Swahili (Kiswahili)", 'sw', 'KE'),
  LanguageModel("ðŸ‡¹ðŸ‡·", "Turkish (TÃ¼rk)", 'tr', 'TR'),
  LanguageModel("ðŸ‡®ðŸ‡³", "Telugu (à°¤à±†à°²à±à°—à±)", 'te', 'IN'),
  LanguageModel("ðŸ‡®ðŸ‡³", "Tamil (à®¤à®®à®¿à®´à¯)", 'ta', 'IN'),
  LanguageModel("ðŸ‡µðŸ‡°", "(Ø§Ø±Ø¯Ùˆ) Urdu", 'ur', 'PK'),
];

class LanguageModel {
  LanguageModel(
    this.symbol,
    this.language,
    this.languageCode,
    this.countryCode,
  );

  String language;
  String symbol;
  String countryCode;
  String languageCode;
}

