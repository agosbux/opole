import 'package:opole/utils/utils.dart';
class CustomCapitalizeFirstLetter {
  static String convert(String input) {
    return input.split(' ').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1);
      }
      return word;
    }).join(' ');
  }
}

