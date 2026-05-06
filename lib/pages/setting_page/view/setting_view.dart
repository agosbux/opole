import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/ui/app_button_ui.dart';
import 'package:opole/ui/delete_user_dialog_ui.dart';
import 'package:opole/ui/logout_user_dialog_ui.dart';
import 'package:opole/pages/setting_page/controller/setting_controller.dart';
import 'package:opole/routes/app_routes.dart';
import 'package:opole/ui/simple_app_bar_ui.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/pages/setting_page/widget/setting_widget.dart';

class SettingView extends GetView<SettingController> {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.white,
        shadowColor: AppColor.black.withValues(alpha: 0.4),
        surfaceTintColor: AppColor.transparent,
        flexibleSpace: SimpleAppBarUi(title: EnumLocal.txtSettings.name.tr),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        height: Get.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),

                // SecciÃ³n Cuenta (solo Compartir perfil)
                Text(
                  EnumLocal.txtAccount.name.tr,
                  style: AppFontStyle.styleW500(AppColor.colorTextGrey, 16),
                ),
                GetBuilder<SettingController>(
                  builder: (controller) => ItemsView(
                    icon: AppAsset.icShare,
                    title: EnumLocal.txtShareProfile.name.tr,
                    callback: controller.shareProfile,
                  ),
                ),
                const SizedBox(height: 10),

                // SecciÃ³n General
                Text(
                  EnumLocal.txtGeneral.name.tr,
                  style: AppFontStyle.styleW500(AppColor.colorTextGrey, 16),
                ),
                ItemsView(
                  icon: AppAsset.icHelp,
                  title: EnumLocal.txtHelp.name.tr,
                  callback: () => Get.toNamed(AppRoutes.helpPage),
                ),
                ItemsView(
                  icon: AppAsset.icTerms,
                  title: EnumLocal.txtTermsOfUse.name.tr,
                  callback: () => Get.toNamed(AppRoutes.termsOfUsePage),
                ),
                ItemsView(
                  icon: AppAsset.icPrivacy,
                  title: EnumLocal.txtPrivacyPolicy.name.tr,
                  callback: () => Get.toNamed(AppRoutes.privacyPolicyPage),
                ),
                ItemsView(
                  icon: AppAsset.icLogOut,
                  title: EnumLocal.txtLogOut.name.tr,
                  callback: () => LogoutUserDialogUi.onShow(
                    onConfirm: controller.logout,
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        child: AppButtonUi(
          height: 56,
          color: AppColor.primary,
          icon: AppAsset.icDelete,
          iconColor: AppColor.white,
          title: EnumLocal.txtDeleteAccount.name.tr,
          gradient: AppColor.redGradient,
          fontWeight: FontWeight.w700,
          iconSize: 24,
          fontSize: 15,
          callback: () => DeleteUserDialogUi.onShow(
            onConfirm: controller.deleteAccount,
          ),
        ),
      ),
    );
  }
}
