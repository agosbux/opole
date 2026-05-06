import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:opole/main.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
// IMPORT TEMPORALMENTE COMENTADO - country_picker causa problemas de compatibilidad
// import 'package:country_picker/country_picker.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:opole/pages/edit_profile_page/controller/edit_profile_controller.dart';
import 'package:opole/utils/utils.dart';

class EditProfileFieldUi extends StatelessWidget {
  const EditProfileFieldUi({
    super.key,
    required this.title,
    required this.maxLines,
    required this.controller,
    required this.keyboardType,
    this.suffixIcon,
    this.height,
    required this.enabled,
    required this.contentPadding,
    this.isOptional,
  });

  final String title;
  final int? maxLines;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool enabled;
  final double? height;
  final bool? isOptional;
  final Widget? suffixIcon;
  final double contentPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (isOptional ?? false)
            ? RichText(
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
            : Text(
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
            maxLines: maxLines ?? 1,
            cursorColor: AppColor.colorTextGrey,
            style: AppFontStyle.styleW600(AppColor.black, 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixIcon: suffixIcon,
              contentPadding: EdgeInsets.only(top: contentPadding),
              hintStyle: AppFontStyle.styleW500(AppColor.coloGreyText, 15),
            ),
          ),
        ),
      ],
    );
  }
}

class RadioItem extends StatelessWidget {
  const RadioItem({super.key, required this.isSelected, required this.title, required this.callback});

  final bool isSelected;
  final String title;
  final Callback callback;

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

class CountyField extends StatelessWidget {
  const CountyField({super.key, required this.flag, required this.title, required this.country});

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
        GetBuilder<EditProfileController>(
          id: "onChangeCountry",
          builder: (controller) {
            return GestureDetector(
              onTap: () {
                // FUNCIÃ“N TEMPORALMENTE DESHABILITADA - country_picker incompatible
                // controller.onChangeCountry(context);
                
                // Alternativa temporal: Mostrar mensaje o diÃ¡logo simple
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("SelecciÃ³n de paÃ­s".tr),
                    content: Text("FunciÃ³n temporalmente deshabilitada para compatibilidad".tr),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("OK".tr),
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
                      Utils.flagController.text,
                      style: AppFontStyle.styleW500(AppColor.coloGreyText, 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      Utils.countryController.text,
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
            );
          },
        ),
      ],
    );
  }
}

class CustomCountryPicker {
  static void pickCountry(BuildContext context) {
    // FUNCIÃ“N TEMPORALMENTE COMENTADA - country_picker incompatible
    /*
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: AppColor.white,
        textStyle: AppFontStyle.styleW500(AppColor.black, 15),
        bottomSheetHeight: Get.height / 1.5,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        inputDecoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          labelText: EnumLocal.txtSearch.name.tr,
          hintText: EnumLocal.txtTypeSomething.name.tr,
          prefixIcon: const Icon(Icons.search),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: AppColor.grey_400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: AppColor.grey_400),
          ),
        ),
      ),
      onSelect: (Country country) {
        Utils.countryController = TextEditingController(text: country.name);
        Utils.flagController = TextEditingController(text: country.flagEmoji);
      },
    );
    */
    
    // Alternativa temporal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("SelecciÃ³n de paÃ­s".tr),
        content: Text("Esta funciÃ³n estÃ¡ temporalmente deshabilitada. Se usarÃ¡ Estados Unidos por defecto.".tr),
        actions: [
          TextButton(
            onPressed: () {
              // Configurar valores por defecto
              Utils.countryController = TextEditingController(text: "United States");
              Utils.flagController = TextEditingController(text: "ðŸ‡ºðŸ‡¸");
              Navigator.pop(context);
            },
            child: Text("Usar Estados Unidos".tr),
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

