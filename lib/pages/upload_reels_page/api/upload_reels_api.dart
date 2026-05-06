import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opole/pages/upload_reels_page/model/upload_reels_model.dart';
import 'package:opole/utils/api.dart';
import 'package:opole/utils/utils.dart';

class UploadReelsApi {
  static Future<UploadReelsModel?> callApi({
    required String loginUserId,
    required String videoImage,
    required String videoUrl,
    required String videoTime,
    required String hashTag,
    required String caption,
    required String songId,
  }) async {
    Utils.showLog("Upload Reels Api Calling...");

    try {
      var headers = {'key': Api.secretKey};

      var request = http.MultipartRequest('POST', Uri.parse("${Api.uploadReels}?userId=$loginUserId"));

      if (songId != "") {
        request.fields.addAll({
          'songId': songId,
          'caption': caption,
          'hashTagId': hashTag,
          'videoTime': videoTime,
        });
      } else {
        request.fields.addAll({
          'caption': caption,
          'hashTagId': hashTag,
          'videoTime': videoTime,
        });
      }

      request.files.add(await http.MultipartFile.fromPath('videoImage', videoImage));

      request.files.add(await http.MultipartFile.fromPath('videoUrl', videoUrl));

      request.headers.addAll(headers);

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResult = jsonDecode(responseBody);
        Utils.showLog("Upload Reels Api Response => $jsonResult");
        return UploadReelsModel.fromJson(jsonResult);
      } else {
        Utils.showLog("Upload Reels Api Response Error");
        return null;
      }
    } catch (e) {
      Utils.showLog("Upload Reels Api Error => $e");
      return null;
    }
  }
}

