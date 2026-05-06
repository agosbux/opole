import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/main.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class NoDataFoundUi extends StatelessWidget {
  const NoDataFoundUi({
    super.key,
    required this.iconSize,
    required this.fontSize,
  });

  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppAsset.icNoDataFound, width: iconSize),
          const SizedBox(height: 5),
          Text(
            EnumLocal.txtNoDataFound.name.tr,
            style: AppFontStyle.styleW500(AppColor.colorGreyHasTagText, fontSize),
          ),
        ],
      ),
    );
  }
}

