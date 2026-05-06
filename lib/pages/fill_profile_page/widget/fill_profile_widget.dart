// lib/pages/fill_profile_page/widget/fill_profile_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/core/services/auth_service.dart';
import 'package:opole/pages/fill_profile_page/controller/fill_profile_controller.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class FillProfileAppBarUi extends StatelessWidget {
  const FillProfileAppBarUi({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColor.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async => await Get.find<AuthService>().signOut(),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: const BoxDecoration(
                    color: AppColor.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Image.asset(AppAsset.icBack, width: 25)),
                ),
              ),
              5.width,
              Text(
                title,
                style: AppFontStyle.styleW700(AppColor.black, 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FillProfileFieldUi extends StatelessWidget {
  const FillProfileFieldUi({
    super.key,
    required this.title,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.height,
    this.enabled = true,
    this.contentTopPadding = 15,
    this.isOptional = false,
    // Opciones para el modo reactivo (sin controller)
    this.initialValue,
    this.onChanged,
    // Mantenemos el controller para compatibilidad
    this.controller,
  });

  final String title;
  final int maxLines;
  final TextInputType keyboardType;
  final bool enabled;
  final bool isOptional;
  final double? height;
  final double contentTopPadding;
  final Widget? suffixIcon;

  // Nuevos parÃ¡metros para modo reactivo
  final String? initialValue;
  final ValueChanged<String>? onChanged;

  // Mantenido para compatibilidad
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOptional)
          RichText(
            text: TextSpan(
              text: title,
              style: AppFontStyle.styleW500(AppColor.coloGreyText, 14),
              children: [
                TextSpan(
                  text: " ${EnumLocal.txtOptionalInBrackets.name.tr}",
                  style: AppFontStyle.styleW400(AppColor.coloGreyText, 12),
                ),
              ],
            ),
          )
        else
          Text(
            title,
            style: AppFontStyle.styleW500(AppColor.coloGreyText, 14),
          ),
        const SizedBox(height: 5),
        Container(
          height: height ?? 55,
          width: Get.width,
          padding: const EdgeInsets.only(left: 15),
          decoration: BoxDecoration(
            color: AppColor.colorBorder.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColor.colorBorder.withValues(alpha: 0.8)),
          ),
          child: TextFormField(
            enabled: enabled,
            keyboardType: keyboardType,
            controller: controller,
            initialValue: initialValue, // Se usa si no se proporciona controller
            onChanged: onChanged,
            maxLines: maxLines,
            cursorColor: AppColor.colorTextGrey,
            style: AppFontStyle.styleW600(AppColor.black, 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixIcon: suffixIcon,
              contentPadding: EdgeInsets.only(top: contentTopPadding),
              hintStyle: AppFontStyle.styleW500(AppColor.coloGreyText, 15),
            ),
          ),
        ),
      ],
    );
  }
}

class FillProfileRadioItem extends StatelessWidget {
  const FillProfileRadioItem({
    super.key,
    required this.isSelected,
    required this.title,
    required this.callback,
  });

  final bool isSelected;
  final String title;
  final VoidCallback callback;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: callback,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        color: AppColor.transparent,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? null : AppColor.colorBorder.withValues(alpha: 0.2),
                gradient: isSelected ? AppColor.primaryLinearGradient : null,
              ),
              child: Container(
                height: 25,
                width: 25,
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? null : AppColor.colorGreyBg,
                  border: Border.all(color: isSelected ? AppColor.white : AppColor.primary.withValues(alpha: 0.3), width: 1.5),
                ),
              ),
            ),
            12.width,
            Text(
              title,
              style: AppFontStyle.styleW600(AppColor.black, 15),
            ),
          ],
        ),
      ),
    );
  }
}

class FillProfileCountyFieldUi extends StatelessWidget {
  const FillProfileCountyFieldUi({super.key, required this.flag, required this.title, required this.country});

  final String title;
  final String flag;
  final String country;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFontStyle.styleW500(AppColor.coloGreyText, 14),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () {
            // Alternativa temporal para selecciÃ³n de paÃ­s
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("SelecciÃ³n de paÃ­s".tr),
                content: Text("Seleccione una opciÃ³n:".tr),
                actions: [
                  TextButton(
                    onPressed: () {
                      final controller = Get.find<FillProfileController>();
                      controller.onChangeCountry({"name": "United States", "flag": "ðŸ‡ºðŸ‡¸"});
                      Navigator.pop(context);
                    },
                    child: Text("Estados Unidos (ðŸ‡ºðŸ‡¸)".tr),
                  ),
                  TextButton(
                    onPressed: () {
                      final controller = Get.find<FillProfileController>();
                      controller.onChangeCountry({"name": "MÃ©xico", "flag": "ðŸ‡²ðŸ‡½"});
                      Navigator.pop(context);
                    },
                    child: Text("MÃ©xico (ðŸ‡²ðŸ‡½)".tr),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancelar".tr),
                  ),
                ],
              ),
            );
          },
          child: Container(
            height: 55,
            width: Get.width,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: AppColor.colorBorder.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColor.colorBorder.withValues(alpha: 0.8)),
            ),
            child: Row(
              children: [
                Text(
                  flag,
                  style: AppFontStyle.styleW500(AppColor.coloGreyText, 20),
                ),
                const SizedBox(width: 10),
                Text(
                  country,
                  style: AppFontStyle.styleW600(AppColor.black, 15),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Image.asset(AppAsset.icArrowDown, height: 14, width: 14),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FillProfileCountryPicker {
  static final controller = Get.find<FillProfileController>();

  static void pickCountry(BuildContext context) {
    // Alternativa temporal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("SelecciÃ³n de paÃ­s".tr),
        content: Text("Seleccione una opciÃ³n:".tr),
        actions: [
          TextButton(
            onPressed: () {
              controller.onChangeCountry({"name": "United States", "flag": "ðŸ‡ºðŸ‡¸"});
              Navigator.pop(context);
            },
            child: Text("Estados Unidos (ðŸ‡ºðŸ‡¸)".tr),
          ),
          TextButton(
            onPressed: () {
              controller.onChangeCountry({"name": "MÃ©xico", "flag": "ðŸ‡²ðŸ‡½"});
              Navigator.pop(context);
            },
            child: Text("MÃ©xico (ðŸ‡²ðŸ‡½)".tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar".tr),
          ),
        ],
      ),
    );
  }
}
