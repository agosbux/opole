import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opole/pages/splash_screen_page/model/fetch_login_user_profile_model.dart';
import 'package:opole/utils/api.dart';
import 'package:opole/utils/utils.dart';

class FetchLoginUserProfileApi {
  static Future<FetchLoginUserProfileModel?> callApi({required String loginUserId}) async {
    Utils.showLog("Get Login User Profile Api Calling...");

    final uri = Uri.parse("${Api.loginUserProfile}?userId=$loginUserId");

    final headers = {"key": Api.secretKey};

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        Utils.showLog("Get Login User Profile Response => ${response.body}");

        return FetchLoginUserProfileModel.fromJson(jsonResponse);
      } else {
        Utils.showLog("Get Login User Profile StateCode Error");
      }
    } catch (error) {
      Utils.showLog("Get Login User Profile Api Error => $error");
    }
    return null;
  }
}

