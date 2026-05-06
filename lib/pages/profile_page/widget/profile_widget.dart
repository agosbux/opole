import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:opole/custom/custom_format_number.dart';
import 'package:opole/main.dart';
import 'package:opole/pages/profile_page/controller/profile_controller.dart';
import 'package:opole/routes/app_routes.dart';
import 'package:opole/shimmer/grid_view_shimmer_ui.dart';
import 'package:opole/shimmer/post_list_shimmer_ui.dart';
import 'package:opole/ui/no_data_found_ui.dart';
import 'package:opole/ui/preview_image_ui.dart';
import 'package:opole/ui/preview_network_image_ui.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/database.dart';
import 'package:opole/utils/font_style.dart';
// IMPORT TEMPORALMENTE COMENTADO - svgaplayer_flutter incompatible
// import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:opole/utils/utils.dart';

class ProfileAppBarUi extends StatelessWidget {
  const ProfileAppBarUi({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            40.width,
            const Spacer(),
            Obx(
              () => Visibility(
                visible: controller.isTabBarPinned.value,
                child: Text(
                  controller.fetchProfileModel?.userProfileData?.user?.name ?? "",
                  style: AppFontStyle.styleW700(AppColor.black, 19),
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.settingPage),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(border: Border.all(color: AppColor.colorBorder), shape: BoxShape.circle),
                child: Center(child: Image.asset(AppAsset.icSetting, width: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReelsTabView extends StatelessWidget {
  const ReelsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
        id: "onGetVideo",
        builder: (controller) => controller.isLoadingVideo
            ? const GridViewShimmerUi()
            : controller.videoCollection.isEmpty
                ? const Center(
                    child: SingleChildScrollView(
                      child: NoDataFoundUi(
                        iconSize: 140,
                        fontSize: 16,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: controller.videoCollection.length,
                      padding: const EdgeInsets.all(10),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        return Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (!(controller.videoCollection[index].isBanned ?? false)) {
                                  controller.onClickReels(index);
                                }
                              },
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                    color: AppColor.colorTextGrey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14)),
                                child: AspectRatio(
                                  aspectRatio: 0.75,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(AppAsset.icImagePlaceHolder, width: 60),
                                      AspectRatio(
                                        aspectRatio: 0.75,
                                        child: PreviewNetworkImageUi(
                                          image: controller.videoCollection[index].videoImage,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: (controller.videoCollection[index].isBanned ?? false),
                              child: Container(
                                height: Get.height,
                                alignment: Alignment.topRight,
                                decoration: BoxDecoration(
                                  color: AppColor.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(AppAsset.icNone, color: AppColor.colorRedContainer, width: 20),
                                ),
                              ),
                            ),
                            Container(
                              height: 35,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(14),
                                  bottomRight: Radius.circular(14),
                                ),
                                gradient: LinearGradient(
                                  colors: [AppColor.transparent, AppColor.black.withValues(alpha: 0.6)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      AppAsset.icLike,
                                      width: 18,
                                      color: (controller.videoCollection[index].isLike ?? false)
                                          ? AppColor.colorTextRed
                                          : AppColor.white,
                                    ),
                                    Text(
                                      " ${CustomFormatNumber.convert(controller.videoCollection[index].totalLikes ?? 0)}",
                                      style: AppFontStyle.styleW600(AppColor.white, 11),
                                    ),
                                    8.width,
                                    Image.asset(AppAsset.icComment, width: 18),
                                    Text(
                                      " ${CustomFormatNumber.convert(controller.videoCollection[index].totalComments ?? 0)}",
                                      style: AppFontStyle.styleW600(AppColor.white, 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ));
  }
}

class FeedsTabView extends StatelessWidget {
  const FeedsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: "onGetPost",
      builder: (controller) => controller.isLoadingPost
          ? const PostListShimmerUi()
          : controller.postCollection.isEmpty
              ? const Center(
                  child: SingleChildScrollView(
                    child: NoDataFoundUi(
                      iconSize: 140,
                      fontSize: 16,
                    ),
                  ),
                )
              : GridView.builder(
                  itemCount: controller.postCollection.length,
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (context, index) {
                    return AspectRatio(
                      aspectRatio: 0.88,
                      child: GestureDetector(
                        onTap: () => Get.to(
                          PreviewImageUi(
                            name: Database.fetchLoginUserProfileModel?.user?.name ?? "",
                            userName: Database.fetchLoginUserProfileModel?.user?.userName ?? "",
                            userImage: Database.fetchLoginUserProfileModel?.user?.image ?? "",
                            images: controller.postCollection[index].postImage ?? [],
                            id: controller.postCollection[index].id,
                            caption: controller.postCollection[index].caption,
                          ),
                        ),
                        child: Container(
                          color: AppColor.colorTextGrey.withValues(alpha: 0.1),
                          child: AspectRatio(
                            aspectRatio: 0.88,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(AppAsset.icImagePlaceHolder, width: 70),
                                AspectRatio(
                                  aspectRatio: 0.88,
                                  child: PreviewNetworkImageUi(image: controller.postCollection[index].mainPostImage),
                                ),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    height: Get.height,
                                    width: Get.width,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppColor.transparent, AppColor.black.withValues(alpha: 0.5)],
                                        end: Alignment.topCenter,
                                        begin: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: !(controller.postCollection[index].postImage?.length == 1),
                                  child: Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Image.asset(
                                      AppAsset.icMultipleImage,
                                      color: AppColor.white,
                                      width: 25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class CollectionsTabView extends StatelessWidget {
  const CollectionsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      id: "onGetCollection",
      builder: (controller) => controller.isLoadingCollection
          ? const GridViewShimmerUi()
          : controller.giftCollection.isEmpty
              ? const Center(
                  child: SingleChildScrollView(
                    child: NoDataFoundUi(
                      iconSize: 140,
                      fontSize: 16,
                    ),
                  ),
                )
              : GridView.builder(
                  itemCount: controller.giftCollection.length,
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    return Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppColor.colorBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 5),
                          // GIFTS TIPO 1 y 2 (imÃ¡genes normales)
                          controller.giftCollection[index].giftType == 1 ||
                                  controller.giftCollection[index].giftType == 2
                              ? Expanded(
                                  child: PreviewNetworkImageUi(image: controller.giftCollection[index].giftImage ?? ""),
                                )
                              // GIFTS TIPO 3 (SVG) - TEMPORALMENTE REEMPLAZADO
                              : controller.giftCollection[index].giftType == 3
                                  ? Expanded(
                                      child: Container(
                                        width: Get.width,
                                        color: AppColor.colorGreyBg,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                AppAsset.icGift,
                                                width: 50,
                                                color: AppColor.primary,
                                              ),
                                              10.height,
                                              Text(
                                                "Gift Animado",
                                                style: AppFontStyle.styleW600(AppColor.primary, 14),
                                              ),
                                              Text(
                                                "(SVG temporalmente deshabilitado)",
                                                style: AppFontStyle.styleW400(AppColor.colorTextGrey, 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      /*
                                      // CÃ“DIGO ORIGINAL COMENTADO:
                                      child: SizedBox(
                                        width: Get.width,
                                        child: SVGASimpleImage(
                                            resUrl: controller.giftCollection[index].giftImage ?? ""),
                                      ),
                                      */
                                    )
                                  : const Offstage(),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${CustomFormatNumber.convert(controller.giftCollection[index].giftCoin ?? 0)} Coins",
                              style: AppFontStyle.styleW700(AppColor.primary, 12),
                            ),
                          ),
                          8.height,
                          Container(
                            height: 35,
                            width: Get.width,
                            decoration: const BoxDecoration(
                              gradient: AppColor.primaryLinearGradient,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                            ),
                            child: Center(
                              child: Text(
                                "X ${CustomFormatNumber.convert(controller.giftCollection[index].total ?? 0)}",
                                style: AppFontStyle.styleW600(AppColor.white, 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

