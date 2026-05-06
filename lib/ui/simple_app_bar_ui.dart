import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/main.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class SimpleAppBarUi extends StatelessWidget {
  const SimpleAppBarUi({super.key, required this.title});

  final String title;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColor.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: const BoxDecoration(
                    color: AppColor.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Image.asset(AppAsset.icBack, width: 25)),
                ),
              ),
              5.width,
              Text(
                title,
                style: AppFontStyle.styleW700(AppColor.black, 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

