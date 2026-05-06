import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../profile_controller.dart';
import '../profile_model.dart';
import '../../../utils/color.dart';
import '../../../utils/font_style.dart';

class StatsSection extends StatelessWidget {
  final ProfileController controller;
  final ProfileModel profile;
  const StatsSection({required this.controller, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      width: double.infinity,
      color: AppColor.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() => Text(
                  '${controller.totalReels.value}',
                  style: AppFontStyle.styleW700(AppColor.black, 18),
                )),
                const SizedBox(height: 2),
                Text(
                  'Reels',
                  style: AppFontStyle.styleW400(AppColor.coloGreyText, 12),
                ),
              ],
            ),
          ),
          VerticalDivider(
            indent: 20,
            endIndent: 20,
            thickness: 2,
            color: AppColor.coloGreyText.withValues(alpha: 0.2),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Navegar a "Los quiero dados"
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(() => Text(
                    '${controller.loQuieroGiven.value}',
                    style: AppFontStyle.styleW700(AppColor.black, 18),
                  )),
                  const SizedBox(height: 2),
                  Text(
                    'Los quiero',
                    style: AppFontStyle.styleW400(AppColor.coloGreyText, 12),
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(
            indent: 20,
            endIndent: 20,
            thickness: 2,
            color: AppColor.coloGreyText.withValues(alpha: 0.2),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Navegar a "Recibidos"
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${profile.loQuieroReceived}',
                    style: AppFontStyle.styleW700(AppColor.black, 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Recibidos',
                    style: AppFontStyle.styleW400(AppColor.coloGreyText, 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}