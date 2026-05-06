import 'package:flutter/cupertino.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class PreviewCountryFlagUi {
  static Widget show(String? flag) {
    if (flag != null && flag != "") {
      return Text(
        flag,
        style: AppFontStyle.styleW700(AppColor.primary, 22),
      );
    } else {
      return Text(
        "ðŸ‡®ðŸ‡³",
        style: AppFontStyle.styleW700(AppColor.primary, 22),
      );
    }
  }
}

