import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opole/pages/profile_page/model/fetch_profile_post_model.dart';
import 'package:opole/utils/api.dart';
import 'package:opole/utils/utils.dart';

class FetchProfilePostApi {
  static Future<FetchProfilePostModel?> callApi({required String userId}) async {
    Utils.showLog("Get Profile Post Api Calling...");

    final uri = Uri.parse("${Api.profilePost}?userId=$userId");

    final headers = {"key": Api.secretKey};

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        Utils.showLog("Get Profile Post Api Response => ${response.body}");

        return FetchProfilePostModel.fromJson(jsonResponse);
      } else {
        Utils.showLog("Get Profile Post Api StateCode Error");
      }
    } catch (error) {
      Utils.showLog("Get Profile Post Api Error => $error");
    }
    return null;
  }
}

