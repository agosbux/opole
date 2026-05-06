// lib/ui/preview_profile_bottom_sheet_ui.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/pages/profile_page/model/profile_models.dart';
import 'package:opole/core/services/supabase_client.dart' as local;
import 'package:opole/ui/preview_country_flag_ui.dart';
import 'package:opole/ui/preview_network_image_ui.dart';
import 'package:opole/pages/splash_screen_page/model/fetch_login_user_profile_model.dart';
import 'package:opole/shimmer/preview_profile_bottom_sheet_shimmer_ui.dart';
import 'package:opole/ui/app_button_ui.dart';
import 'package:opole/main.dart';
import 'package:opole/routes/app_routes.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/font_style.dart';
import 'package:opole/utils/utils.dart';

class PreviewProfileBottomSheetUi {
  static FetchProfileModel? fetchProfileModel;
  static RxBool isLoadingProfile = false.obs;
  static RxBool isFollow = false.obs;

  // ===================================================================
  // ðŸ”¹ OBTENER PERFIL DESDE SUPABASE
  // ===================================================================
  static Future<void> onGetProfile(String userId) async {
    isLoadingProfile.value = true;

    try {
      final currentUserId = local.SupabaseClient.currentUserId;

      // Obtener datos del perfil desde la tabla 'profiles'
      final profile = await local.SupabaseClient.from('profiles')
          .select('''
            id,
            username,
            name,
            avatar,
            is_verified,
            gender,
            country_flag_image,
            is_fake
          ''')
          .eq('id', userId)
          .single();

      // Verificar si el usuario actual sigue a este perfil
      bool following = false;
      if (currentUserId != null) {
        final followCheck = await local.SupabaseClient.from('follows')
            .select('id')
            .eq('follower_id', currentUserId)
            .eq('following_id', userId)
            .maybeSingle();
        following = followCheck != null;
      }

      // Construir un mapa con la estructura que espera FetchProfileModel
      final userMap = {
        'id': profile['id'],
        'name': profile['name'] ?? '',
        'userName': profile['username'] ?? '',
        'image': profile['avatar'] ?? '',
        'isVerified': profile['is_verified'] ?? false,
        'gender': profile['gender'] ?? '',
        'countryFlagImage': profile['country_flag_image'] ?? '',
        'isFake': profile['is_fake'] ?? false,
        'isFollow': following,
        // Campos adicionales que el modelo pueda requerir (valores por defecto)
        'bio': '',
        'totalFollower': 0,
        'totalFollowing': 0,
      };

      final profileMap = {
        'userProfileData': {
          'user': userMap,
        },
      };

      // Crear el modelo usando fromJson
      fetchProfileModel = FetchProfileModel.fromJson(profileMap);
      isFollow.value = following;
    } catch (e, stack) {
      Utils.showLog("âŒ Error obteniendo perfil: $e");
      print(stack);
    } finally {
      isLoadingProfile.value = false;
    }
  }

  // ===================================================================
  // ðŸ”¹ SEGUIR / DEJAR DE SEGUIR
  // ===================================================================
  static Future<void> onClickFollow(String userId) async {
    final currentUserId = local.SupabaseClient.currentUserId;
    if (currentUserId == null) {
      Utils.showToast("Debes iniciar sesiÃ³n");
      return;
    }

    if (userId == currentUserId) {
      Utils.showToast(EnumLocal.txtYouCantFollowYourOwnAccount.name.tr);
      return;
    }

    // Optimistic update
    isFollow.value = !isFollow.value;

    try {
      if (isFollow.value) {
        // Seguir
        await local.SupabaseClient.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': userId,
        });
        // Opcional: actualizar contadores (si tienes RPC o updates manuales)
      } else {
        // Dejar de seguir
        await local.SupabaseClient.from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', userId);
      }
    } catch (e, stack) {
      Utils.showLog("âŒ Error en follow/unfollow: $e");
      print(stack);
      // Revertir cambio optimista
      isFollow.value = !isFollow.value;
    }
  }

  // ===================================================================
  // ðŸ”¹ MOSTRAR BOTTOM SHEET
  // ===================================================================
  static void show({
    required String userId,
    required BuildContext context,
  }) {
    onGetProfile(userId);
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: AppColor.transparent,
      builder: (context) => Container(
        height: 428,
        width: Get.width,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 65,
              color: AppColor.grey_100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 4,
                        width: 35,
                        decoration: BoxDecoration(
                          color: AppColor.colorTextDarkGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      10.height,
                      Text(
                        EnumLocal.txtViewProfile.name.tr,
                        style: AppFontStyle.styleW700(AppColor.black, 17),
                      ),
                    ],
                  ).paddingOnly(left: 50),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 30,
                      width: 30,
                      margin: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.transparent,
                        border: Border.all(color: AppColor.black),
                      ),
                      child: Center(
                        child: Image.asset(
                          width: 18,
                          AppAsset.icClose,
                          color: AppColor.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(
                () => isLoadingProfile.value
                    ? const PreviewProfileBottomSheetShimmerUi()
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                          child: Column(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColor.primaryLinearGradient,
                                ),
                                child: Container(
                                    height: 110,
                                    width: 110,
                                    margin: const EdgeInsets.all(2),
                                    clipBehavior: Clip.antiAlias,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColor.white),
                                    child: Stack(
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 1,
                                          child: Image.asset(AppAsset.icProfilePlaceHolder),
                                        ),
                                        AspectRatio(
                                          aspectRatio: 1,
                                          child: PreviewNetworkImageUi(image: fetchProfileModel?.userProfileData?.user?.image),
                                        ),
                                      ],
                                    )),
                              ),
                              10.height,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    fetchProfileModel?.userProfileData?.user?.name ?? "",
                                    style: AppFontStyle.styleW700(AppColor.black, 18),
                                  ),
                                  Visibility(
                                    visible: fetchProfileModel?.userProfileData?.user?.isVerified ?? false,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 3),
                                      child: Image.asset(AppAsset.icBlueTick, width: 20),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                fetchProfileModel?.userProfileData?.user?.userName ?? "",
                                style: AppFontStyle.styleW400(AppColor.colorGreyHasTagText, 13),
                              ),
                              10.height,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  (fetchProfileModel?.userProfileData?.user?.isFake ?? false)
                                      ? (fetchProfileModel?.userProfileData?.user?.countryFlagImage != null) && (fetchProfileModel?.userProfileData?.user?.countryFlagImage != "")
                                          ? Image.network(
                                              fetchProfileModel?.userProfileData?.user?.countryFlagImage ?? "",
                                              width: 25,
                                            )
                                          : const Offstage()
                                      : SizedBox(
                                          width: 22,
                                          child: PreviewCountryFlagUi.show(fetchProfileModel?.userProfileData?.user?.countryFlagImage),
                                        ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColor.secondary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          fetchProfileModel?.userProfileData?.user?.gender?.toLowerCase().trim() == "male" ? AppAsset.icMale : AppAsset.icFemale,
                                          width: 14,
                                          color: AppColor.white,
                                        ),
                                        5.width,
                                        Text(
                                          fetchProfileModel?.userProfileData?.user?.gender?.toLowerCase().trim() == "male"
                                              ? EnumLocal.txtMale.name.tr
                                              : EnumLocal.txtFemale.name.tr,
                                          style: AppFontStyle.styleW600(AppColor.white, 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () => onClickFollow(userId),
                                    child: Obx(
                                      () => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColor.colorBorder.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: AppColor.colorBorder.withValues(alpha: 0.6), width: 1),
                                        ),
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              isFollow.value ? AppAsset.icFollowing : AppAsset.icFollow,
                                              height: 18,
                                              color: AppColor.primary,
                                            ),
                                            8.width,
                                            Text(
                                              isFollow.value ? EnumLocal.txtFollowing.name.tr : EnumLocal.txtFollow.name.tr,
                                              style: AppFontStyle.styleW600(AppColor.primary, 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButtonUi(
                                      height: 54,
                                      fontSize: 18,
                                      gradient: AppColor.primaryLinearGradient,
                                      title: EnumLocal.txtViewDetails.name.tr,
                                      callback: () {
                                        Get.back();
                                        Get.toNamed(AppRoutes.previewUserProfilePage, arguments: userId);
                                      },
                                    ),
                                  ),
                                  15.width,
                                  GestureDetector(
                                    onTap: () {
                                      // CHAT DESHABILITADO - Mostrar mensaje informativo
                                      Utils.showToast("Chat deshabilitado en esta versiÃ³n");
                                    },
                                    child: Container(
                                      height: 56,
                                      width: 56,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        gradient: AppColor.primaryLinearGradient,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.asset(AppAsset.icSayHey, width: 28),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
