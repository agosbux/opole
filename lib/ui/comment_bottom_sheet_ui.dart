import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:get_storage/get_storage.dart';  // âœ… AGREGADO
import 'package:opole/controllers/session_controller.dart';  // âœ… AGREGADO
import 'package:opole/shimmer/comment_shimmer_ui.dart';
import 'package:opole/ui/no_data_found_ui.dart';
import 'package:opole/ui/preview_network_image_ui.dart';
import 'package:opole/main.dart';
import 'package:opole/pages/splash_screen_page/api/create_comment_api.dart';
import 'package:opole/pages/splash_screen_page/api/fetch_comment_api.dart';
import 'package:opole/pages/splash_screen_page/model/comment_model.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/database.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class CommentBottomSheetUi {
  static RxBool isLoading = false.obs;
  static CommentModel? commentModel;
  static RxList<PostOrVideoComment> comments = <PostOrVideoComment>[].obs;
  static TextEditingController commentController = TextEditingController();
  static ScrollController scrollController = ScrollController();

  static Future<void> onGetComments({
    required int commentType,
    required String commentTypeId,
  }) async {
    isLoading.value = true;
    comments.clear();
    // âœ… Reemplazo: GetStorage().read("loginUserId") ?? "" â†’ GetStorage().read
    commentModel = await FetchCommentApi.callApi(
      loginUserId: GetStorage().read("loginUserId") ?? "",
      commentType: commentType,
      commentTypeId: commentTypeId,
    );

    if (commentModel?.postOrVideoComment != null) {
      isLoading.value = false;
      comments.addAll(commentModel?.postOrVideoComment ?? []);
    }
  }

  static Future<void> onSendComment({
    required int commentType,
    required String commentTypeId,
  }) async {
    if (commentController.text.trim().isNotEmpty) {
      final commentText = commentController.text;

      // âœ… Reemplazo: Database.fetchLoginUserProfileModel â†’ SessionController
      final session = Get.find<SessionController>();
      comments.add(
        PostOrVideoComment(
          name: session.user.value?.name ?? "",
          userImage: session.user.value?.photoUrl ?? "",
          commentText: commentText,
          time: "Now",
        ),
      );
      commentController.clear();

      if (comments.length > 4) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
        await 500.milliseconds.delay();
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      }

      await CreateCommentApi.callApi(
        // âœ… Reemplazo: GetStorage().read("loginUserId") ?? "" â†’ GetStorage().read
        loginUserId: GetStorage().read("loginUserId") ?? "",
        commentType: commentType,
        commentTypeId: commentTypeId,
        commentText: commentText,
      );
    }
  }

  static String onFormatTime(String time) {
    List<String> parts = time.split(' ');

    if (parts.length == 3 && parts[2] == 'ago' && parts[1] == 'minutes' && parts[0].isNotEmpty) {
      return '${parts[0]}m';
    } else if (parts.length == 3 && parts[2] == 'ago' && parts[1] == 'hours' && parts[0].isNotEmpty) {
      return '${parts[0]}h';
    } else if (parts.length == 3 && parts[2] == 'ago' && parts[1] == 'seconds' && parts[0].isNotEmpty) {
      return '${parts[0]}s';
    } else {
      return time;
    }
  }

  static Future<int> show({
    required BuildContext context,
    required int commentType,
    required String commentTypeId,
    required int totalComments,
  }) async {
    onGetComments(commentType: commentType, commentTypeId: commentTypeId);

    await showModalBottomSheet(
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: Get.height,
      context: context,
      backgroundColor: AppColor.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          height: 500,
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
                          EnumLocal.txtComment.name.tr,
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
              Expanded(
                child: Obx(
                  () => isLoading.value
                      ? const CommentShimmerUi()
                      : comments.isEmpty
                          ? const NoDataFoundUi(iconSize: 160, fontSize: 19)
                          : SingleChildScrollView(
                              controller: scrollController,
                              child: ListView.builder(
                                itemCount: comments.length,
                                shrinkWrap: true,
                                padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                          height: 45,
                                          width: 45,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: const BoxDecoration(shape: BoxShape.circle),
                                          child: Stack(
                                            children: [
                                              AspectRatio(
                                                aspectRatio: 1,
                                                child: Image.asset(AppAsset.icProfilePlaceHolder),
                                              ),
                                              AspectRatio(
                                                aspectRatio: 1,
                                                child: PreviewNetworkImageUi(image: comments[index].userImage),
                                              ),
                                            ],
                                          )),
                                      12.width,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                text: comments[index].name,
                                                style: AppFontStyle.styleW700(AppColor.black, 15),
                                                children: [
                                                  TextSpan(
                                                    text: "   ${onFormatTime(comments[index].time ?? "")}",
                                                    style: AppFontStyle.styleW600(AppColor.colorGreyHasTagText, 14),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              comments[index].commentText ?? "",
                                              style: AppFontStyle.styleW500(AppColor.colorDarkGrey, 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                ),
              ),
              CommentTextFieldUi(
                controller: commentController,
                onSend: () {
                  onSendComment(commentType: commentType, commentTypeId: commentTypeId);
                },
              ),
            ],
          ),
        ),
      ),
    );
    return comments.isEmpty ? totalComments : comments.length;
  }
}

class CommentTextFieldUi extends StatelessWidget {
  const CommentTextFieldUi({
    super.key,
    required this.onSend,
    required this.controller,
  });

  final Callback onSend;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 15, right: 5),
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: AppColor.colorBorder.withValues(alpha: 0.3),
        border: Border.all(color: AppColor.colorBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            height: 22,
            width: 22,
            AppAsset.icCommentGradiant,
          ),
          5.width,
          VerticalDivider(
            indent: 12,
            endIndent: 12,
            color: AppColor.coloGreyText.withValues(alpha: 0.3),
          ),
          5.width,
          Expanded(
            child: TextFormField(
              controller: controller,
              cursorColor: AppColor.colorTextGrey,
              maxLines: 1,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 3),
                hintText: EnumLocal.txtTypeComment.name.tr,
                hintStyle: AppFontStyle.styleW400(AppColor.coloGreyText, 14.5),
              ),
            ),
          ),
          GestureDetector(
            onTap: onSend,
            child: Container(
              height: 40,
              width: 40,
              color: AppColor.transparent,
              child: Center(child: Image.asset(width: 25, AppAsset.icSend)),
            ),
          ),
        ],
      ),
    );
  }
}
