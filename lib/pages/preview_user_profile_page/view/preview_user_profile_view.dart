import 'package:flutter/material.dart';
import 'package:opole/utils/utils.dart'; // <-- AÃ‘ADIR ESTE IMPORT
import 'package:get/get.dart';
import 'package:opole/custom/custom_format_number.dart';
import 'package:opole/ui/preview_country_flag_ui.dart';
import 'package:opole/ui/preview_network_image_ui.dart';
import 'package:opole/main.dart';
import 'package:opole/pages/preview_user_profile_page/controller/preview_user_profile_controller.dart';
import 'package:opole/routes/app_routes.dart';
import 'package:opole/pages/preview_user_profile_page/widget/preview_user_profile_widget.dart';
import 'package:opole/shimmer/preview_user_profile_shimmer_ui.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';

class PreviewUserProfileView extends GetView<PreviewUserProfileController> {
  const PreviewUserProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: GestureDetector(
        onTap: () {
          // CHAT DESHABILITADO - Mostrar mensaje informativo
          Utils.showToast("Chat deshabilitado en esta versiÃ³n");
          
          /*
          // CÃ³digo original comentado:
          if (controller.fetchProfileModel?.userProfileData?.user?.isFake == true) {
            Get.toNamed(
              AppRoutes.fakeChatPage,
              arguments: {
                "id": controller.userId,
                "name": controller.fetchProfileModel?.userProfileData?.user?.name ?? "",
                "userName": controller.fetchProfileModel?.userProfileData?.user?.userName ?? "",
                "image": controller.fetchProfileModel?.userProfileData?.user?.image ?? "",
                "isBlueTik": controller.fetchProfileModel?.userProfileData?.user?.isVerified ?? false,
              },
            );
          } else {
            Get.toNamed(
              AppRoutes.chatPage,
              arguments: {
                "id": controller.userId,
                "name": controller.fetchProfileModel?.userProfileData?.user?.name ?? "",
                "userName": controller.fetchProfileModel?.userProfileData?.user?.userName ?? "",
                "image": controller.fetchProfileModel?.userProfileData?.user?.image ?? "",
                "isBlueTik": controller.fetchProfileModel?.userProfileData?.user?.isVerified ?? false,
              },
            );
          }
          */
        },
        child: Container(
          height: 65,
          width: 65,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColor.primaryLinearGradient,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Image.asset(AppAsset.icSayHey, width: 33),
        ),
      ),
      appBar: const PreviewUserProfileAppBar(),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: AppColor.white,
              pinned: true,
              automaticallyImplyLeading: false,
              expandedHeight: 450,
              floating: true,
              flexibleSpace: FlexibleSpaceBar(
                background: GetBuilder<PreviewUserProfileController>(
                  id: "onGetProfile",
                  builder: (controller) => controller.isLoadingProfile
                      ? const PreviewUserProfileShimmerUi()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            10.height,
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColor.primaryLinearGradient,
                              ),
                              child: Container(
                                height: 118,
                                width: 118,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColor.white, width: 1.5),
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      height: 118,
                                      width: 118,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: const BoxDecoration(shape: BoxShape.circle),
                                      child: Image.asset(AppAsset.icProfilePlaceHolder, fit: BoxFit.cover),
                                    ),
                                    Container(
                                      height: 118,
                                      width: 118,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: const BoxDecoration(shape: BoxShape.circle),
                                      child: PreviewNetworkImageUi(image: controller.fetchProfileModel?.userProfileData?.user?.image),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            10.height,
                            SizedBox(
                              width: Get.width,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Text(
                                      maxLines: 1,
                                      controller.fetchProfileModel?.userProfileData?.user?.name ?? "",
                                      style: AppFontStyle.styleW700(AppColor.black, 18),
                                    ),
                                  ),
                                  Visibility(
                                    visible: controller.fetchProfileModel?.userProfileData?.user?.isVerified ?? false,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 3),
                                      child: Image.asset(AppAsset.icBlueTick, width: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              controller.fetchProfileModel?.userProfileData?.user?.userName ?? "",
                              style: AppFontStyle.styleW400(AppColor.colorGreyHasTagText, 13),
                            ),
                            10.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                (controller.fetchProfileModel?.userProfileData?.user?.isFake ?? false)
                                    ? (controller.fetchProfileModel?.userProfileData?.user?.countryFlagImage != null) &&
                                            (controller.fetchProfileModel?.userProfileData?.user?.countryFlagImage != "")
                                        ? Image.network(
                                            controller.fetchProfileModel?.userProfileData?.user?.countryFlagImage ?? "",
                                            width: 25,
                                          )
                                        : const Offstage()
                                    : SizedBox(
                                        width: 22,
                                        child: PreviewCountryFlagUi.show(controller.fetchProfileModel?.userProfileData?.user?.countryFlagImage),
                                      ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColor.secondary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        ((controller.fetchProfileModel?.userProfileData?.user?.gender?.toLowerCase() ?? "male") == "male") ? AppAsset.icMale : AppAsset.icFemale,
                                        width: 14,
                                        color: AppColor.white,
                                      ),
                                      5.width,
                                      Text(
                                        ((controller.fetchProfileModel?.userProfileData?.user?.gender?.toLowerCase() ?? "male") == "male")
                                            ? EnumLocal.txtMale.name.tr
                                            : EnumLocal.txtFemale.name.tr,
                                        style: AppFontStyle.styleW600(AppColor.white, 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GetBuilder<PreviewUserProfileController>(
                                  id: "onClickFollow",
                                  builder: (controller) => GestureDetector(
                                    onTap: controller.onClickFollow,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColor.colorBorder.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColor.colorBorder.withValues(alpha: 0.6), width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            controller.isFollow ? AppAsset.icFollowing : AppAsset.icFollow,
                                            height: 18,
                                            color: AppColor.primary,
                                          ),
                                          8.width,
                                          Text(
                                            controller.isFollow ? EnumLocal.txtFollowing.name.tr : EnumLocal.txtFollow.name.tr,
                                            style: AppFontStyle.styleW600(AppColor.primary, 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Container(
                              height: 75,
                              width: Get.width,
                              color: AppColor.colorBorder.withValues(alpha: 0.35),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          CustomFormatNumber.convert(controller.fetchProfileModel?.userProfileData?.totalLikesOfVideoPost ?? 0),
                                          style: AppFontStyle.styleW700(AppColor.colorDarkBlue, 18),
                                        ),
                                        2.height,
                                        Text(
                                          EnumLocal.txtLikes.name.tr,
                                          style: AppFontStyle.styleW400(AppColor.colorDarkBlue, 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const VerticalDivider(
                                    indent: 20,
                                    endIndent: 20,
                                    width: 0,
                                    thickness: 2,
                                    color: AppColor.white,
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Get.toNamed(
                                          AppRoutes.previewUserProfilePage,
                                          arguments: {
                                            "userId": controller.userId,
                                            "name": controller.fetchProfileModel?.userProfileData?.user?.name ?? "",
                                            "userName": controller.fetchProfileModel?.userProfileData?.user?.userName ?? "",
                                            "image": controller.fetchProfileModel?.userProfileData?.user?.image ?? "",
                                            "type": 0,
                                          },
                                        ); // Arguments Type => Following..
                                      },
                                      child: Container(
                                        color: AppColor.transparent,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              CustomFormatNumber.convert(controller.fetchProfileModel?.userProfileData?.totalFollowing ?? 0),
                                              style: AppFontStyle.styleW700(AppColor.colorDarkBlue, 18),
                                            ),
                                            2.height,
                                            Text(
                                              EnumLocal.txtFollowing.name.tr,
                                              style: AppFontStyle.styleW400(AppColor.colorDarkBlue, 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const VerticalDivider(
                                    indent: 20,
                                    endIndent: 20,
                                    width: 0,
                                    thickness: 2,
                                    color: AppColor.white,
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Get.toNamed(
                                          AppRoutes.previewUserProfilePage,
                                          arguments: {
                                            "userId": controller.userId,
                                            "name": controller.fetchProfileModel?.userProfileData?.user?.name ?? "",
                                            "userName": controller.fetchProfileModel?.userProfileData?.user?.userName ?? "",
                                            "image": controller.fetchProfileModel?.userProfileData?.user?.image ?? "",
                                            "type": 1,
                                          },
                                        ); // Arguments Type => Followers
                                      },
                                      child: Container(
                                        color: AppColor.transparent,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              CustomFormatNumber.convert(controller.fetchProfileModel?.userProfileData?.totalFollowers ?? 0),
                                              style: AppFontStyle.styleW700(AppColor.colorDarkBlue, 18),
                                            ),
                                            2.height,
                                            Text(
                                              EnumLocal.txtFollowers.name.tr,
                                              style: AppFontStyle.styleW400(AppColor.colorDarkBlue, 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(75),
                child: Container(
                  color: AppColor.white,
                  child: TabBar(
                    controller: controller.tabController,
                    labelColor: AppColor.colorTabBar,
                    labelStyle: AppFontStyle.styleW600(AppColor.black.withValues(alpha: 0.8), 13),
                    unselectedLabelColor: AppColor.colorUnselectedIcon,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 2,
                    indicatorPadding: const EdgeInsets.only(top: 72, right: 10, left: 10),
                    indicator: const BoxDecoration(
                      gradient: AppColor.primaryLinearGradient,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    tabs: <Tab>[
                      Tab(
                        icon: const ImageIcon(AssetImage(AppAsset.icReels), size: 30),
                        text: EnumLocal.txtReels.name.tr,
                      ),
                      Tab(
                        icon: const ImageIcon(AssetImage(AppAsset.icFeeds), size: 30),
                        text: EnumLocal.txtFeeds.name.tr,
                      ),
                      Tab(
                        icon: const ImageIcon(AssetImage(AppAsset.icCollections), size: 30),
                        text: EnumLocal.txtCollections.name.tr,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(controller: controller.tabController, physics: const BouncingScrollPhysics(), children: const [
          ReelsTabView(),
          FeedsTabView(),
          CollectionsTabView(),
        ]),
      ),
    );
  }
}

