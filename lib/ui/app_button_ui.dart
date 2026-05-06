import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/constant.dart';
import 'package:opole/utils/utils.dart';

class AppButtonUi extends StatelessWidget {
  const AppButtonUi({
    super.key,
    this.height,
    required this.title,
    this.color,
    this.icon,
    this.gradient,
    required this.callback,
    this.iconSize,
    this.fontSize,
    this.fontColor,
    this.fontWeight,
    this.iconColor,
    this.enabled = true, // âœ… nuevo parÃ¡metro
  });

  final double? height;
  final double? iconSize;
  final double? fontSize;
  final String title;
  final Color? color;
  final Color? fontColor;
  final Color? iconColor;
  final String? icon;
  final Gradient? gradient;
  final FontWeight? fontWeight;
  final Callback callback;
  final bool enabled; // âœ… campo agregado

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.6, // âœ… efecto visual cuando estÃ¡ deshabilitado
      child: IgnorePointer(
        ignoring: !enabled, // âœ… desactiva los toques si enabled es false
        child: GestureDetector(
          onTap: enabled ? callback : null, // âœ… solo ejecuta callback si estÃ¡ habilitado
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: color,
              gradient: gradient,
            ),
            height: height ?? 56,
            width: Get.width,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null)
                    Image.asset(
                      icon!,
                      width: iconSize ?? 30,
                      color: iconColor,
                    ).paddingOnly(right: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: fontColor ?? AppColor.white,
                      fontFamily: AppConstant.appFontMedium,
                      fontSize: fontSize ?? 18,
                      letterSpacing: 0.3,
                      fontWeight: fontWeight ?? FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
