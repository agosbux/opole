import 'package:flutter/material.dart';
import 'package:opole/utils/utils.dart';

extension HeightExtension on num {
  SizedBox get height => SizedBox(height: toDouble());
}

extension WidthExtension on num {
  SizedBox get width => SizedBox(width: toDouble());
}

