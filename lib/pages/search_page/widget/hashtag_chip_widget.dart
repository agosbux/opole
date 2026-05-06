import 'package:flutter/material.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/font_style.dart';

class HashtagChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const HashtagChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary : AppColor.colorGreyBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColor.colorBorderGrey,
          ),
        ),
        child: Text(
          label,
          style: AppFontStyle.styleW500(
            isSelected ? AppColor.white : AppColor.colorTextGrey,
            14,
          ),
        ),
      ),
    );
  }
}

