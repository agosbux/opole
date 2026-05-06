// lib/pages/fill_profile_page/view/fill_profile_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/core/services/auth_service.dart';
import 'package:opole/ui/app_button_ui.dart';
import 'package:opole/ui/preview_network_image_ui.dart';
import 'package:opole/pages/fill_profile_page/controller/fill_profile_controller.dart';
import 'package:opole/pages/fill_profile_page/widget/fill_profile_widget.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class FillProfileView extends GetView<FillProfileController> {
  const FillProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await controller.logout();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColor.white,
          shadowColor: AppColor.black.withOpacity(0.4),
          surfaceTintColor: AppColor.transparent,
          flexibleSpace: FillProfileAppBarUi(title: EnumLocal.txtFillProfile.name.tr),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                // Avatar
                GestureDetector(
                  onTap: () => controller.pickImageFromGallery(),
                  child: Center(
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColor.primaryLinearGradient,
                      ),
                      child: Container(
                        height: 124,
                        width: 124,
                        margin: const EdgeInsets.all(2),
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.white,
                          border: Border.all(color: AppColor.white, width: 1.5),
                        ),
                        child: Stack(
                          children: [
                            Obx(
                              () => Container(
                                height: 125,
                                width: 125,
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColor.white,
                                ),
                                child: controller.pickImage == null
                                    ? controller.photoUrl.value.isNotEmpty
                                        ? Stack(
                                            children: [
                                              AspectRatio(
                                                aspectRatio: 1,
                                                child: Image.asset(AppAsset.icProfilePlaceHolder),
                                              ),
                                              AspectRatio(
                                                aspectRatio: 1,
                                                child: PreviewNetworkImageUi(image: controller.photoUrl.value),
                                              ),
                                            ],
                                          )
                                        : Image.asset(AppAsset.icProfilePlaceHolder, fit: BoxFit.cover)
                                    : Image.file(controller.pickImage!, fit: BoxFit.cover),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                height: 36,
                                width: 36,
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColor.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColor.colorBorder, width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Image.asset(AppAsset.icCameraGradiant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                40.height,
                // Nombre de usuario
                Obx(
                  () => FillProfileFieldUi(
                    enabled: true,
                    title: EnumLocal.txtUserName.name.tr,
                    maxLines: 1,
                    keyboardType: TextInputType.name,
                    initialValue: controller.username.value,
                    onChanged: (value) => controller.username.value = value,
                    contentTopPadding: 15,
                    suffixIcon: SizedBox(
                      height: 20,
                      width: 20,
                      child: Center(
                        child: Image.asset(AppAsset.icEditPen, height: 20, width: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // PaÃ­s (con GestureDetector)
                GestureDetector(
                  onTap: () async {
                    final result = await Get.toNamed('/select-country');
                    if (result != null && result is Map<String, String>) {
                      controller.selectCountry(result);
                    }
                  },
                  child: Obx(
                    () => FillProfileCountyFieldUi(
                      title: EnumLocal.txtCountry.name.tr,
                      flag: controller.selectedCountry["flag"] ?? "ðŸŒ",
                      country: controller.selectedCountry["name"] ?? "",
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Zona
                Obx(
                  () => FillProfileFieldUi(
                    enabled: true,
                    title: EnumLocal.txtZone.name.tr,
                    maxLines: 1,
                    keyboardType: TextInputType.text,
                    initialValue: controller.zone.value,
                    onChanged: (value) => controller.zone.value = value,
                    contentTopPadding: 15,
                    suffixIcon: const Icon(Icons.location_on, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 5),
                // GÃ©nero
                Text(
                  EnumLocal.txtGender.name.tr,
                  style: AppFontStyle.styleW500(AppColor.coloGreyText, 14),
                ),
                const SizedBox(height: 5),
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FillProfileRadioItem(
                        isSelected: controller.selectedGender.value == "male",
                        title: EnumLocal.txtMale.name.tr,
                        callback: () => controller.selectGender("male"),
                      ),
                      FillProfileRadioItem(
                        isSelected: controller.selectedGender.value == "female",
                        title: EnumLocal.txtFemale.name.tr,
                        callback: () => controller.selectGender("female"),
                      ),
                      FillProfileRadioItem(
                        isSelected: controller.selectedGender.value == "other",
                        title: EnumLocal.txtOther.name.tr,
                        callback: () => controller.selectGender("other"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          child: Obx(
            () => Stack(
              children: [
                AppButtonUi(
                  height: 56,
                  color: AppColor.primary,
                  title: EnumLocal.txtSaveProfile.name.tr,
                  gradient: AppColor.primaryLinearGradient,
                  fontSize: 18,
                  callback: () => controller.saveProfile(),
                  enabled: !controller.isLoading.value,
                ),
                if (controller.isLoading.value)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
