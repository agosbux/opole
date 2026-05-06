import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:opole/main.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.title,
    required this.hintText,
    required this.contentTopPadding,
    this.height,
    this.maxLines,
    this.controller,
    this.keyboardType,
  });

  final String title;
  final String hintText;
  final double? height;
  final double contentTopPadding;
  final int? maxLines;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFontStyle.styleW500(AppColor.coloGreyText, 14),
        ),
        const SizedBox(height: 5),
        Container(
          height: height ?? 55,
          width: Get.width,
          padding: const EdgeInsets.only(left: 15),
          // alignment: height == null ? Alignment.center : null,
          decoration: BoxDecoration(
            color: AppColor.colorBorder.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColor.colorBorder.withValues(alpha: 0.8)),
          ),
          child: TextFormField(
            keyboardType: keyboardType,
            controller: controller,
            maxLines: maxLines ?? 1,
            cursorColor: AppColor.colorTextGrey,
            style: AppFontStyle.styleW600(AppColor.black, 14.5),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              contentPadding: EdgeInsets.only(top: contentTopPadding),
              hintStyle: AppFontStyle.styleW500(AppColor.coloGreyText, 15),
            ),
          ),
        ),
      ],
    );
  }
}

