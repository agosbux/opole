// delete_user_dialog_ui.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';

class DeleteUserDialogUi {
  static Future<void> onShow({VoidCallback? onConfirm}) async {
    return Get.dialog(
      AlertDialog(
        backgroundColor: AppColor.white,
        surfaceTintColor: AppColor.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        content: Container(
          width: Get.width,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                EnumLocal.txtDeleteAccount.name.tr,
                style: AppFontStyle.styleW700(AppColor.black, 20),
              ),
              const SizedBox(height: 15),
              Text(
                EnumLocal.txtAreYouSureYouWantToDeleteAccount.name.tr,
                textAlign: TextAlign.center,
                style: AppFontStyle.styleW400(AppColor.coloGreyText, 16),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: AppColor.grey_300, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            EnumLocal.txtCancel.name.tr,
                            style: AppFontStyle.styleW700(AppColor.black, 17),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Get.back();
                        if (onConfirm != null) {
                          onConfirm();
                        }
                      },
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(35),
                          gradient: AppColor.redGradient,
                        ),
                        child: Center(
                          child: Text(
                            EnumLocal.txtYesDelete.name.tr,
                            style: AppFontStyle.styleW700(AppColor.white, 17),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
