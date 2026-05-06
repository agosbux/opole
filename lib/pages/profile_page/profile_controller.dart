// lib/pages/profile_page/profile_controller.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/painting.dart'; // ✅ Necesario para ImageCache
import 'package:get/get.dart';
import '../../controllers/session_controller.dart'; // SessionController v4.1-GALACTIC
import '../feed_page/controller/feed_controller.dart'; // FeedController con update(['feed_state'])
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_model.dart';

class ProfileController extends GetxController {
  final supabase = Supabase.instance.client;
  final Rx<ProfileModel?> profile = Rx<ProfileModel?>(null);
  final RxBool isLoading = true.obs;
  final RxInt totalReels = 0.obs;
  final RxInt loQuieroGiven = 0.obs;

  // Estados UI
  final RxBool isBoostClaiming = false.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isUpdatingUsername = false.obs;

  final String userId;

  ProfileController({required this.userId});

  @override
  void onInit() {
    super.onInit();
    print('🟢 [PROFILE] Controller inicializado para userId: $userId');
    loadProfile();
    loadExtraCounters();
  }

  // ----------------------------------------------------------------------
  // Carga principal del perfil
  // ----------------------------------------------------------------------
  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final currentUser = supabase.auth.currentUser;
      final viewerId = currentUser?.id;

      final response = await supabase.rpc('obtener_perfil_completo', params: {
        'p_user_id': userId,
        'p_viewer_id': viewerId,
      });

      if (response == null) {
        throw Exception('La RPC devolvió null');
      }

      Map<String, dynamic> data;
      if (response is String) {
        data = Map<String, dynamic>.from(jsonDecode(response));
      } else if (response is Map) {
        data = Map<String, dynamic>.from(response as Map);
      } else {
        throw Exception('Tipo de respuesta inesperado: ${response.runtimeType}');
      }

      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      profile.value = ProfileModel.fromJson(data, viewerId: viewerId);
    } catch (e, stack) {
      print('❌ Error loadProfile: $e');
      profile.value = null;
      if (Get.context != null) {
        Get.snackbar('Error', 'No se pudo cargar el perfil');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ----------------------------------------------------------------------
  // Contadores extra
  // ----------------------------------------------------------------------
  Future<void> loadExtraCounters() async {
    try {
      final reelsResponse = await supabase
          .from('reels')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'active')
          .count(CountOption.exact);
      totalReels.value = reelsResponse.count ?? 0;

      final loQuieroResponse = await supabase
          .from('lo_quiero')
          .select('id')
          .eq('comprador_id', userId)
          .count(CountOption.exact);
      loQuieroGiven.value = loQuieroResponse.count ?? 0;
    } catch (e) {
      totalReels.value = 0;
      loQuieroGiven.value = 0;
    }
  }

  // ----------------------------------------------------------------------
  // Privacidad
  // ----------------------------------------------------------------------
  Future<void> updatePrivacy({
    bool? showPhone,
    bool? showEmail,
    bool? showLocation,
    bool? showFullName,
  }) async {
    if (profile.value == null) return;

    final updates = <String, dynamic>{};
    if (showPhone != null) updates['show_phone'] = showPhone;
    if (showEmail != null) updates['show_email'] = showEmail;
    if (showLocation != null) updates['show_location'] = showLocation;
    if (showFullName != null) updates['show_full_name'] = showFullName;
    if (updates.isEmpty) return;

    try {
      await supabase.from('users').update(updates).eq('id', userId);
      await loadProfile();
      Get.snackbar('Éxito', 'Privacidad actualizada');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar');
    }
  }

  // ----------------------------------------------------------------------
  // Boost diario
  // ----------------------------------------------------------------------
  Future<void> claimDailyBoost() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    isBoostClaiming.value = true;
    try {
      await supabase.rpc('claim_daily_login', params: {'p_user_id': currentUserId});
      await loadProfile();
      Get.snackbar('¡Boost!', 'Recompensa diaria reclamada');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo reclamar');
    } finally {
      isBoostClaiming.value = false;
    }
  }

  // ----------------------------------------------------------------------
  // Pull-to-refresh
  // ----------------------------------------------------------------------
  Future<void> refreshData() async {
    await loadProfile();
    await loadExtraCounters();
  }

  // ----------------------------------------------------------------------
  // 🖼️ SUBIR IMAGEN DE PERFIL (FIX QUIRÚRGICO - CACHE + SYNC GLOBAL)
  // ----------------------------------------------------------------------
  Future<void> updateProfileImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null) return;

    isUploadingImage.value = true;
    try {
      final bytes = await image.readAsBytes();
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 1️⃣ Subir a Supabase con upsert para evitar conflictos
      await supabase.storage.from('avatars').uploadBinary(
        fileName, 
        bytes, 
        fileOptions: const FileOptions(upsert: true)
      );

      // 2️⃣ URL pública + cache-busting para forzar reload en CDN y cliente
      final baseUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final newPhotoUrl = '$baseUrl?v=$cacheBuster';

      // 3️⃣ ✅ CRÍTICO: Evict imagen vieja del cache de Flutter para evitar flicker
      final oldPhotoUrl = profile.value?.photoUrl;
      if (oldPhotoUrl != null && oldPhotoUrl.isNotEmpty) {
        final baseOldUrl = oldPhotoUrl.split('?').first;
        await PaintingBinding.instance.imageCache.evict(NetworkImage(baseOldUrl));
      }

      // 4️⃣ Actualizar DB con la nueva URL con cache-buster
      await supabase.from('users').update({'photo_url': newPhotoUrl}).eq('id', userId);

      // 5️⃣ Refrescar perfil LOCAL
      await loadProfile();

      // 6️⃣ ✅ CRÍTICO: Si es el usuario logueado, actualizar SessionController (fuente global de verdad)
      final currentUserId = supabase.auth.currentUser?.id;
      if (userId == currentUserId) {
        try {
          final sessionCtrl = Get.find<SessionController>();
          sessionCtrl.profile.value = sessionCtrl.profile.value?.copyWith(
            photoUrl: newPhotoUrl,
            updatedAt: DateTime.now(),
          );
          sessionCtrl.profile.refresh(); // Forzar rebuild de observers
        } catch (_) {
          // Si SessionController no está registrado, ignorar (fallback seguro)
        }
      }

      // 7️⃣ ✅ Notificar al feed para que refresque avatares en reels existentes
      if (Get.isRegistered<FeedController>()) {
        Get.find<FeedController>().update(['feed_state']);
      }

      Get.snackbar('¡Listo!', 'Foto de perfil actualizada');
    } catch (e) {
      print('❌ Error subiendo imagen: $e');
      Get.snackbar('Error', 'No se pudo subir la imagen');
    } finally {
      isUploadingImage.value = false;
    }
  }

  // ----------------------------------------------------------------------
  // Actualizar username (opcional)
  // ----------------------------------------------------------------------
  Future<void> updateUsername(String newUsername) async {
    if (newUsername.trim().isEmpty) {
      Get.snackbar('Error', 'Nombre de usuario vacío');
      return;
    }

    isUpdatingUsername.value = true;
    try {
      await supabase.from('users').update({'username': newUsername}).eq('id', userId);
      await loadProfile();
      Get.snackbar('Éxito', 'Nombre de usuario actualizado');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cambiar el nombre de usuario');
    } finally {
      isUpdatingUsername.value = false;
    }
  }

  // ----------------------------------------------------------------------
  // Navegar a edición completa
  // ----------------------------------------------------------------------
  void goToEditProfile() {
    Get.toNamed('/edit-profile', arguments: {'userId': userId});
  }

  // ----------------------------------------------------------------------
  // Cerrar sesión
  // ----------------------------------------------------------------------
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      Get.offAllNamed('/splash');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cerrar sesión');
    }
  }
}