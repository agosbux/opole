import 'package:flutter/widgets.dart';
import 'package:opole/utils/utils.dart';

extension SizeExtension on num {
  SizedBox get height => SizedBox(height: toDouble());
  SizedBox get width => SizedBox(width: toDouble());
}

