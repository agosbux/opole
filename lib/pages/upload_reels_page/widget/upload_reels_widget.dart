import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/custom/custom_format_number.dart';
import 'package:opole/main.dart';
import 'package:opole/pages/upload_reels_page/controller/upload_reels_controller.dart';
import 'package:opole/shimmer/hash_tag_bottom_sheet_shimmer_ui.dart';
import 'package:opole/ui/no_data_found_ui.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';

class PreviewReelsCaptionUi extends StatefulWidget {
  const PreviewReelsCaptionUi({super.key});

  @override
  State<PreviewReelsCaptionUi> createState() => _PreviewReelsCaptionUiState();
}

class _PreviewReelsCaptionUiState extends State<PreviewReelsCaptionUi> {
  final controller = Get.find<UploadReelsController>();
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    focusNode.requestFocus();
    controller.onToggleHashTag(false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.white,
        surfaceTintColor: AppColor.transparent,
        flexibleSpace: SafeArea(
          bottom: false,
          child: Container(
            color: AppColor.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 45),
                  const Spacer(),
                  Text(
                    EnumLocal.txtCaption.name.tr,
                    style: AppFontStyle.styleW700(AppColor.black, 19),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 40,
                      width: 50,
                      decoration: const BoxDecoration(
                        color: AppColor.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        EnumLocal.txtDone.name.tr,
                        style: AppFontStyle.styleW700(AppColor.primary, 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          Container(
            height: 130,
            width: Get.width,
            padding: const EdgeInsets.only(left: 15),
            margin: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColor.colorBorder.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColor.colorBorder.withValues(alpha: 0.8)),
            ),
            child: TextFormField(
              onChanged: (value) => controller.onChangeHashtag(),
              controller: controller.captionController,
              maxLines: 4,
              focusNode: focusNode,
              cursorColor: AppColor.colorTextGrey,
              style: AppFontStyle.styleW600(AppColor.black, 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: EnumLocal.txtEnterYourTextWithHashtag.name.tr,
                hintStyle: AppFontStyle.styleW400(AppColor.coloGreyText, 15),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: Obx(
              () => Visibility(
                visible: controller.isShowHashTag.value,
                child: GetBuilder<UploadReelsController>(
                  id: "onGetHashTag",
                  builder: (controller) {
                    if (controller.isLoadingHashTag.value) {
                      return const HashTagBottomSheetShimmerUi();
                    } else if (controller.filterHashtag.value.isEmpty) {
                      return const Center(child: SingleChildScrollView(child: NoDataFoundUi(iconSize: 160, fontSize: 19)));
                    } else {
                      return SingleChildScrollView(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.filterHashtag.value.length,
                          itemBuilder: (context, index) => GetBuilder<UploadReelsController>(
                            id: "onSelectHastTag",
                            builder: (controller) => GestureDetector(
                              onTap: () => controller.onSelectHashtag(index),
                              child: Container(
                                height: 70,
                                width: Get.width,
                                padding: const EdgeInsets.only(left: 20, right: 20),
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: AppColor.grey_100)),
                                ),
                                child: Row(
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        text: "# ",
                                        style: AppFontStyle.styleW600(AppColor.primary, 20),
                                        children: [
                                          TextSpan(
                                            text: controller.filterHashtag.value[index].hashTag,
                                            style: AppFontStyle.styleW700(AppColor.black, 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Image.asset(
                                          AppAsset.icViewBorder,
                                          color: AppColor.colorTextGrey,
                                          width: 20,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          CustomFormatNumber.convert(controller.filterHashtag.value[index].totalHashTagUsedCount ?? 0),
                                          style: AppFontStyle.styleW700(AppColor.colorTextGrey, 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
