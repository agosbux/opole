import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/custom/custom_format_number.dart';
import 'package:opole/main.dart';
import 'package:opole/pages/edit_reels_page/controller/edit_reels_controller.dart';
import 'package:opole/shimmer/hash_tag_bottom_sheet_shimmer_ui.dart';
import 'package:opole/ui/no_data_found_ui.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class EditPreviewReelsCaptionUi extends StatefulWidget {
  const EditPreviewReelsCaptionUi({super.key});

  @override
  State<EditPreviewReelsCaptionUi> createState() => _EditPreviewReelsCaptionUiState();
}

class _EditPreviewReelsCaptionUiState extends State<EditPreviewReelsCaptionUi> {
  final controller = Get.find<EditReelsController>();
  FocusNode focusNode = FocusNode();

  String caption = "";

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
                  45.width,
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
                  5.width,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 5),
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
          const SizedBox(height: 5),
          Expanded(
            child: Obx(
              () => Visibility(
                visible: controller.isShowHashTag.value,
                child: GetBuilder<EditReelsController>(
                  id: "onGetHashTag",
                  builder: (controller) => controller.isLoadingHashTag
                      ? const HashTagBottomSheetShimmerUi()
                      : controller.filterHashtag.isEmpty
                          ? const Center(child: SingleChildScrollView(child: NoDataFoundUi(iconSize: 160, fontSize: 19)))
                          : SingleChildScrollView(
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: controller.filterHashtag.length,
                                itemBuilder: (context, index) => GetBuilder<EditReelsController>(
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
                                                  text: controller.filterHashtag[index].hashTag,
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
                                              5.width,
                                              Text(
                                                CustomFormatNumber.convert(controller.filterHashtag[index].totalHashTagUsedCount ?? 0),
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
                            ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

