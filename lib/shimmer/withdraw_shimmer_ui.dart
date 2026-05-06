import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:opole/main.dart';
import 'package:opole/utils/color.dart';
import 'package:flutter/widgets.dart';
import 'package:opole/utils/utils.dart';

class WithdrawShimmerUi extends StatelessWidget {
  const WithdrawShimmerUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColor.shimmer,
      highlightColor: AppColor.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Container(
              height: 148,
              width: Get.width,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(30)),
            ),
            Container(
              height: 25,
              width: 150,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(8)),
            ),
            Container(
              height: 54,
              width: Get.width,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(15)),
            ),
            Container(
              height: 25,
              width: 150,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(8)),
            ),
            Container(
              height: 54,
              width: Get.width,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(15)),
            ),
            const Spacer(),
            Container(
              height: 54,
              width: Get.width,
              margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
              decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(50)),
            ),
          ],
        ),
      ),
    );
  }
}

