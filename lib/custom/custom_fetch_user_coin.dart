import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:opole/pages/splash_screen_page/api/fetch_user_coin_api.dart';
import 'package:opole/pages/splash_screen_page/model/fetch_user_coin_model.dart';
import 'package:opole/utils/database.dart';
import 'package:opole/utils/utils.dart';

class CustomFetchUserCoin {
  static RxInt coin = 0.obs;
  static FetchUserCoinModel? fetchUserCoinModel;
  static RxBool isLoading = false.obs;

  static Future<void> init() async {
    isLoading.value = true;
    fetchUserCoinModel = await FetchUserCoinApi.callApi(loginUserId: GetStorage().read("loginUserId") ?? "");

    if (fetchUserCoinModel?.userCoin != null) {
      coin.value = fetchUserCoinModel?.userCoin ?? 0;
      isLoading.value = false;
    }
  }
}

