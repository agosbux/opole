import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:opole/custom/custom_icon_button.dart';
import 'package:opole/routes/app_routes.dart';
import 'package:opole/ui/app_button_ui.dart';
import 'package:opole/ui/loading_ui.dart';
import 'package:opole/main.dart';
import 'package:opole/pages/preview_created_reels_page/controller/preview_created_reels_controller.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class PreviewCreatedReelsView extends GetView<PreviewCreatedReelsController> {
  const PreviewCreatedReelsView({super.key});

  @override
  Widget build(BuildContext context) {
    Timer(
      const Duration(milliseconds: 300),
      () {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: AppColor.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        );
      },
    );
    return Scaffold(
      body: GetBuilder<PreviewCreatedReelsController>(
        id: "onChangeLoading",
        builder: (controller) => SizedBox(
          height: Get.height,
          width: Get.width,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: controller.onClickVideo,
                child: Container(
                  color: AppColor.black,
                  height: Get.height,
                  width: Get.width,
                  child: controller.isVideoLoading
                      ? const LoadingUi()
                      : SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: controller.videoPlayerController?.value.size.width ?? 0,
                              height: controller.videoPlayerController?.value.size.height ?? 0,
                              child: Chewie(controller: controller.chewieController!),
                            ),
                          ),
                        ),
                ),
              ),
              GetBuilder<PreviewCreatedReelsController>(
                id: "onShowPlayPauseIcon",
                builder: (controller) => controller.isShowPlayPauseIcon
                    ? Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: controller.onClickPlayPause,
                          child: GetBuilder<PreviewCreatedReelsController>(
                            id: "onChangePlayPauseIcon",
                            builder: (controller) => Container(
                              height: 70,
                              width: 70,
                              padding: EdgeInsets.only(left: controller.isPlaying ? 0 : 2),
                              decoration: BoxDecoration(color: AppColor.black.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: Center(
                                child: Image.asset(
                                  controller.isPlaying ? AppAsset.icPause : AppAsset.icPlay,
                                  width: 30,
                                  height: 30,
                                  color: AppColor.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const Offstage(),
              ),
              Positioned(
                top: 0,
                child: Container(
                  height: 150,
                  width: Get.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColor.black.withValues(alpha: 0.7), AppColor.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  height: 150,
                  width: Get.width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColor.transparent, AppColor.black.withValues(alpha: 0.7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 30,
                left: 15,
                child: Row(
                  children: [
                    CustomIconButton(
                      icon: AppAsset.icBack,
                      iconColor: AppColor.white,
                      callback: () {
                        Get.back();
                      },
                    ),
                    15.width,
                    Text(
                      EnumLocal.txtPreview.name.tr,
                      style: AppFontStyle.styleW700(AppColor.white, 20),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 35,
                right: 15,
                child: GestureDetector(
                  onTap: () {
                    controller.onStopVideo();
                    Get.offAndToNamed(AppRoutes.trimVideoPage, arguments: {
                      "videoPath": controller.videoUrl,
                      "songId": controller.songId,
                    });
                  },
                  child: Container(
                    height: 45,
                    width: 45,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColor.primaryLinearGradient,
                    ),
                    child: Image.asset(
                      AppAsset.icTrim,
                      height: 25,
                      width: 25,
                      color: AppColor.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                child: SizedBox(
                  width: Get.width,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Get.width / 5),
                    child: AppButtonUi(
                      fontSize: 18,
                      gradient: AppColor.primaryLinearGradient,
                      title: EnumLocal.txtNext.name.tr,
                      callback: () {
                        controller.onClickNext();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

