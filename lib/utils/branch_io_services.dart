import 'package:opole/utils/utils.dart';
class BranchIoServices {
  static String eventType = "";
  static String eventId = "";

  static Future<void> onListenBranchIoLinks() async {}

  static Future<void> onCreateBranchIoLink({
    required String id,
    required String name,
    required String userId,
    required String image,
    required String pageRoutes,
  }) async {}

  static Future<String?> onGenerateLink() async {
    return null;
  }
}

