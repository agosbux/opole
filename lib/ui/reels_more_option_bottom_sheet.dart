import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:opole/main.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class ReelsMoreOptionBottomSheet {
  static void show({
    required BuildContext context,
    required Callback reportCallBack,
    required Callback deleteCallBack,
    required Callback editCallBack,
  }) async {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: AppColor.transparent,
      builder: (context) => Container(
        height: 220,
        width: Get.width,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 65,
              color: AppColor.grey_100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 4,
                        width: 35,
                        decoration: BoxDecoration(
                          color: AppColor.colorTextDarkGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      10.height,
                      Text(
                        EnumLocal.txtMoreOption.name.tr,
                        style: AppFontStyle.styleW700(AppColor.black, 17),
                      ),
                    ],
                  ).paddingOnly(left: 50),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 30,
                      width: 30,
                      margin: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.transparent,
                        border: Border.all(color: AppColor.black),
                      ),
                      child: Center(
                        child: Image.asset(
                          width: 18,
                          AppAsset.icClose,
                          color: AppColor.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: editCallBack,
              child: Container(
                height: 50,
                color: AppColor.transparent,
                padding: const EdgeInsets.only(left: 15),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Center(
                        child: Image.asset(
                          AppAsset.icEditPen,
                          width: 20,
                          color: AppColor.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      EnumLocal.txtEdit.name.tr,
                      style: AppFontStyle.styleW600(AppColor.black, 17),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: reportCallBack,
              child: Container(
                height: 50,
                color: AppColor.transparent,
                padding: const EdgeInsets.only(left: 15),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 30,
                      child: Center(
                        child: Icon(
                          Icons.report,
                          color: AppColor.black,
                          size: 27,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      EnumLocal.txtReport.name.tr,
                      style: AppFontStyle.styleW600(AppColor.black, 17),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: deleteCallBack,
              child: Container(
                height: 50,
                color: AppColor.transparent,
                padding: const EdgeInsets.only(left: 15),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Center(
                        child: Image.asset(
                          AppAsset.icDelete,
                          width: 27,
                          color: AppColor.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      EnumLocal.txtDelete.name.tr,
                      style: AppFontStyle.styleW600(AppColor.black, 17),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

