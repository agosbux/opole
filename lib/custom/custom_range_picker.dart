import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class CustomRangePicker {
  static Future<DateTimeRange?> onShow(BuildContext context) async {
    return await showRangePickerDialog(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      contentPadding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      context: context,
      slidersColor: AppColor.black,
      maxDate: DateTime.now(),
      initialDate: DateTime.now(),
      minDate: DateTime(1900, 1, 1),
      barrierColor: AppColor.black.withValues(alpha: 0.8),
      enabledCellsTextStyle: AppFontStyle.styleW500(AppColor.black, 16),
      disabledCellsTextStyle: AppFontStyle.styleW500(AppColor.coloGreyText, 16),
      singleSelectedCellTextStyle: AppFontStyle.styleW500(AppColor.white, 14),
      singleSelectedCellDecoration: const BoxDecoration(color: AppColor.primary, shape: BoxShape.circle),
      currentDateTextStyle: AppFontStyle.styleW500(AppColor.white, 16),
      currentDateDecoration: const BoxDecoration(color: AppColor.secondary, shape: BoxShape.circle),
      daysOfTheWeekTextStyle: AppFontStyle.styleW500(AppColor.black.withValues(alpha: 0.6), 14),
      leadingDateTextStyle: AppFontStyle.styleW500(AppColor.black, 20),
      centerLeadingDate: true,
    );
  }
}

