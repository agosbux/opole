import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:opole/main.dart';
import 'package:opole/utils/color.dart';
import 'package:flutter/widgets.dart';
import 'package:opole/utils/utils.dart';

class ProfileShimmerUi extends StatelessWidget {
  const ProfileShimmerUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColor.shimmer,
      highlightColor: AppColor.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 124,
            width: 124,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(color: AppColor.black, shape: BoxShape.circle),
          ),
          Container(
            height: 22,
            width: 175,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(20)),
          ),
          Container(
            height: 22,
            width: 250,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(20)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 33,
                width: 33,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: const BoxDecoration(color: AppColor.black, shape: BoxShape.circle),
              ),
              8.width,
              Container(
                height: 33,
                width: 100,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(20)),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 70,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: const BoxDecoration(color: AppColor.black),
                ),
              ),
              5.width,
              Expanded(
                child: Container(
                  height: 70,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: const BoxDecoration(color: AppColor.black),
                ),
              ),
              5.width,
              Expanded(
                child: Container(
                  height: 70,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: const BoxDecoration(color: AppColor.black),
                ),
              ),
            ],
          ),
          Container(
            height: 90,
            width: Get.width,
            margin: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
            decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(20)),
          ),
        ],
      ),
    );
  }
}

