import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/main.dart';
import 'package:opole/pages/edit_post_page/controller/edit_post_controller.dart';
import 'package:opole/pages/edit_post_page/widget/edit_post_widget.dart';
import 'package:opole/ui/app_button_ui.dart';
import 'package:opole/ui/simple_app_bar_ui.dart';
import 'package:opole/utils/api.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class EditPostView extends GetView<EditPostController> {
  const EditPostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.white,
        shadowColor: AppColor.black.withValues(alpha: 0.4),
        surfaceTintColor: AppColor.transparent,
        flexibleSpace: SimpleAppBarUi(title: EnumLocal.txtEditPost.name.tr),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 170,
            width: Get.width,
            color: AppColor.colorBorder.withValues(alpha: 0.2),
            child: GetBuilder<EditPostController>(
              id: "onChangeImages",
              builder: (logic) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: logic.selectedImages.length,
                  padding: const EdgeInsets.only(left: 15, top: 15, bottom: 15),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: SizedBox(
                      width: 135,
                      child: Container(
                        height: 140,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.network(Api.baseUrl + controller.selectedImages[index], fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: RichText(
              text: TextSpan(
                text: EnumLocal.txtCaption.name.tr,
                style: AppFontStyle.styleW700(AppColor.black, 15),
                children: [
                  TextSpan(
                    text: " ${EnumLocal.txtOptionalInBrackets.name.tr}",
                    style: AppFontStyle.styleW400(AppColor.coloGreyText, 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () {
              Get.to(
                const PreviewPostCaptionUi(),
                transition: Transition.downToUp,
                duration: const Duration(milliseconds: 300),
              );
            },
            child: GetBuilder<EditPostController>(
              id: "onChangeHashtag",
              builder: (controller) => Container(
                height: 130,
                width: Get.width,
                padding: const EdgeInsets.only(left: 15, top: 5),
                margin: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: AppColor.colorBorder.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColor.colorBorder.withValues(alpha: 0.8)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    controller.captionController.text.isEmpty ? EnumLocal.txtEnterYourTextWithHashtag.name.tr : controller.captionController.text,
                    style: controller.captionController.text.isEmpty ? AppFontStyle.styleW400(AppColor.coloGreyText, 15) : AppFontStyle.styleW600(AppColor.black, 15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppButtonUi(
        title: EnumLocal.txtSubmit.name.tr,
        gradient: AppColor.primaryLinearGradient,
        callback: controller.onEditPost,
      ).paddingSymmetric(horizontal: Get.width / 6.5, vertical: 25),
    );
  }
}

