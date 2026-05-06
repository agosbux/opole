import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:opole/main.dart';
import 'package:opole/utils/color.dart';
import 'package:flutter/widgets.dart';
import 'package:opole/utils/utils.dart';

class PreviewUserProfileShimmerUi extends StatelessWidget {
  const PreviewUserProfileShimmerUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColor.shimmer,
      highlightColor: AppColor.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          10.height,
          Container(
            height: 135,
            width: 135,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: const BoxDecoration(color: AppColor.black, shape: BoxShape.circle),
          ),
          Container(
            height: 26,
            width: 175,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(20)),
          ),
          Container(
            height: 26,
            width: 250,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(20)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 38,
                width: 38,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: const BoxDecoration(color: AppColor.black, shape: BoxShape.circle),
              ),
              8.width,
              Container(
                height: 38,
                width: 130,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(20)),
              ),
            ],
          ),
          Container(
            height: 85,
            width: Get.width,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: const BoxDecoration(color: AppColor.black),
          ),
        ],
      ),
    );
  }
}

