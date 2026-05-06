import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/session_controller.dart';
// âœ… Importamos el modelo unificado desde profile_models.dart
import 'package:opole/pages/profile_page/model/profile_models.dart';
import 'package:opole/core/services/supabase_client.dart' as local;
import 'package:opole/routes/app_routes.dart';

// ===================================================================
// MODELO COMPATIBLE CON EL WIDGET (fetchProfileModel)
// ===================================================================
class _UserProfileData {
  _User? user;
  _UserProfileData(this.user);
}

class _User {
  String? name;
  _User(this.name);
}

class _FetchProfileModel {
  _UserProfileData? userProfileData;
  _FetchProfileModel(this.userProfileData);
}

class ProfileController extends GetxController with GetSingleTickerProviderStateMixin {
  final SessionController session = Get.find<SessionController>();

  late final TabController tabController;

  // ===================================================================
  // ESTADO BASE
  // ===================================================================
  final isLoading = true.obs;
  final user = Rx<OpoleUser?>(null); // âœ… Ahora usa OpoleUser de profile_models.dart
  final totalReels = 0.obs;
  final RxList<Map<String, dynamic>> myReels = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> loQuieroSent = <Map<String, dynamic>>[].obs;

  // ===================================================================
  // NUEVAS VARIABLES REACTIVAS PARA COMPATIBILIDAD CON EL WIDGET
  // ===================================================================
  final RxBool isTabBarPinned = false.obs;
  final RxBool isLoadingVideo = false.obs;
  final RxBool isLoadingPost = false.obs;
  final RxBool isLoadingCollection = false.obs;

  final RxList<Map<String, dynamic>> videoCollection = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> postCollection = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> giftCollection = <Map<String, dynamic>>[].obs;

  // Getters compatibles (fetchProfileModel)
  _FetchProfileModel? get fetchProfileModel {
    if (user.value == null) return null;
    return _FetchProfileModel(
      _UserProfileData(
        _User(user.value!.name),
      ),
    );
  }

  // Getters desde SessionController
  int get loQuieroReceived => session.loQuieroReceived;
  int get loQuieroGiven => session.dailyLoQuieroUsed;

  // Getters para la vista (desde user)
  String get name => user.value?.name ?? '';
  String get username => user.value?.username ?? '';
  String get photoUrl => user.value?.photoUrl ?? '';
  String get country => user.value?.country ?? '';
  String get zone => user.value?.zone ?? '';
  String? get gender => user.value?.gender;
  int get level => user.value?.level ?? 1;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    loadUserData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // ===================================================================
  // CARGA DE DATOS PRINCIPAL (con todas las colecciones)
  // ===================================================================
  Future<void> loadUserData() async {
    try {
      isLoading.value = true;
      final currentUser = session.user.value; // âœ… ya es OpoleUser de profile_models.dart
      if (currentUser != null) {
        user.value = currentUser; // âœ… asignaciÃ³n directa, sin conversiÃ³n

        // Cargar todas las colecciones en paralelo
        await Future.wait([
          _loadMyReels(currentUser.id ?? ''),
          _loadLoQuieroSent(currentUser.id ?? ''),
          _loadPosts(currentUser.id ?? ''),
          _loadGifts(currentUser.id ?? ''),
        ]);
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el perfil');
    } finally {
      isLoading.value = false;
    }
  }

  /// Carga los reels publicados por el usuario (myReels y videoCollection)
  Future<void> _loadMyReels(String userId) async {
    isLoadingVideo.value = true;
    try {
      final response = await local.SupabaseClient
          .from('reels')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response != null) {
        final List<Map<String, dynamic>> reels = List<Map<String, dynamic>>.from(response);
        myReels.value = reels;
        videoCollection.value = reels;
        totalReels.value = reels.length;
      } else {
        myReels.clear();
        videoCollection.clear();
        totalReels.value = 0;
      }
    } catch (e) {
      print('Error cargando reels: $e');
    } finally {
      isLoadingVideo.value = false;
    }
  }

  /// Carga los "lo quiero" enviados
  Future<void> _loadLoQuieroSent(String userId) async {
    try {
      final response = await local.SupabaseClient
          .from('lo_quiero')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response != null) {
        loQuieroSent.value = List<Map<String, dynamic>>.from(response);
      } else {
        loQuieroSent.clear();
      }
    } catch (e) {
      print('Error cargando "lo quiero": $e');
    }
  }

  /// Carga los posts del usuario (postCollection)
  Future<void> _loadPosts(String userId) async {
    isLoadingPost.value = true;
    try {
      final response = await local.SupabaseClient
          .from('posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response != null) {
        postCollection.value = List<Map<String, dynamic>>.from(response);
      } else {
        postCollection.clear();
      }
    } catch (e) {
      print('Error cargando posts: $e');
      postCollection.clear();
    } finally {
      isLoadingPost.value = false;
    }
  }

  /// Carga los gifts del usuario (giftCollection)
  Future<void> _loadGifts(String userId) async {
    isLoadingCollection.value = true;
    try {
      final response = await local.SupabaseClient
          .from('user_gifts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response != null) {
        giftCollection.value = List<Map<String, dynamic>>.from(response);
      } else {
        giftCollection.clear();
      }
    } catch (e) {
      print('Error cargando gifts: $e');
      giftCollection.clear();
    } finally {
      isLoadingCollection.value = false;
    }
  }

  // ===================================================================
  // MÃ‰TODOS DE NAVEGACIÃ“N Y ACCIÃ“N
  // ===================================================================

  /// Abre el feed de reels en la posición del reel seleccionado.
  void onClickReels(int index) {
    final reelId = videoCollection[index]['id'] as String?;
    if (reelId != null) {
      Get.toNamed(AppRoutes.feedPage, arguments: {'reelId': reelId});
    } else {
      Get.toNamed(AppRoutes.feedPage);
    }
  }

  /// Elimina un post
  Future<void> onClickDeletePost({required String postId}) async {
    try {
      await local.SupabaseClient
          .from('posts')
          .delete()
          .eq('id', postId);

      await loadUserData();
      Get.back();
      Get.snackbar('Ã‰xito', 'Post eliminado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar el post');
    }
  }

  // ===================================================================
  // REFRESH
  // ===================================================================
  Future<void> refreshData() async {
    await loadUserData();
  }
}