import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opole/pages/feed_page/model/fetch_post_model.dart';
import 'package:opole/utils/api.dart';
import 'package:opole/utils/utils.dart';

class FetchPostApi {
  static int startPagination = 0;
  static int limitPagination = 20;

  static Future<FetchPostModel?> callApi({required String loginUserId, required String postId}) async {
    Utils.showLog("Get Post Api Calling... ");

    startPagination += 1;

    Utils.showLog("Get Post Pagination Page => $startPagination");

    final uri =
        Uri.parse("${Api.post}?start=$startPagination&limit=$limitPagination&userId=$loginUserId&postId=$postId");

    final headers = {"key": Api.secretKey};

    try {
      var response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        Utils.showLog("Get Post Api Response => ${response.body}");

        return FetchPostModel.fromJson(jsonResponse);
      } else {
        Utils.showLog("Get Post Api StateCode Error");
      }
    } catch (error) {
      Utils.showLog("Get Post Api Error => $error");
    }
    return null;
  }
}

