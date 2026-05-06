import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:opole/main.dart';
import 'package:opole/utils/color.dart';
import 'package:flutter/widgets.dart';
import 'package:opole/utils/utils.dart';

class CoinHistoryShimmerUi extends StatelessWidget {
  const CoinHistoryShimmerUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColor.shimmer,
      highlightColor: AppColor.white,
      child: ListView.builder(
        itemCount: 15,
        shrinkWrap: true,
        padding: const EdgeInsets.only(left: 10, top: 15, right: 10),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),

          child: Container(
            height: 70,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColor.black),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 10),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColor.colorBorderGrey.withValues(alpha: 0.4)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 12,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(5)),
                      ),
                      Container(
                        height: 12,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(5)),
                      ),
                      Container(
                        height: 12,
                        decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 32,
                  width: 70,
                  decoration: BoxDecoration(
                    color: AppColor.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          // child: Row(
          //   mainAxisAlignment: MainAxisAlignment.start,
          //   crossAxisAlignment: CrossAxisAlignment.center,
          //   children: [
          //     Container(
          //       height: 54,
          //       width: 54,
          //       decoration: const BoxDecoration(color: AppColor.black, shape: BoxShape.circle),
          //     ),
          //     const SizedBox(width: 10),
          //     Expanded(
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Container(
          //             height: 22,
          //             margin: const EdgeInsets.only(bottom: 5),
          //             decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(5)),
          //           ),
          //           Container(
          //             height: 22,
          //             decoration: BoxDecoration(color: AppColor.black, borderRadius: BorderRadius.circular(5)),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
        ),
      ),
    );
  }
}

