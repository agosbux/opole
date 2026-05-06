// lib/pages/fill_profile_page/controller/fill_profile_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opole/core/services/auth_service.dart';
import 'package:opole/core/services/supabase_client.dart' as supabase;
import 'package:opole/controllers/session_controller.dart';

class FillProfileController extends GetxController {
  final username = ''.obs;
  final photoUrl = ''.obs;
  final country = ''.obs;
  final zone = ''.obs;
  final gender = Rxn<String>();

  File? pickImage;
  final selectedCountry = <String, String>{}.obs;
  final selectedGender = ''.obs;

  final isLoading = false.obs;
  final ImagePicker _picker = ImagePicker();

  // ðŸ”¹ Getter para la imagen actual (local o remota)
  String get profileImage => pickImage != null ? pickImage!.path : photoUrl.value;

  // ðŸ”¹ MÃ©todo legacy para cambio de paÃ­s
  void onChangeCountry(Map<String, String> countryData) => selectCountry(countryData);

  Future<void> pickImageFromGallery() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        pickImage = File(picked.path);
        update(); // Notifica a la UI
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo seleccionar la imagen');
    }
  }

  Future<void> saveProfile() async {
    if (username.value.isEmpty) {
      Get.snackbar('Error', 'El nombre de usuario es obligatorio');
      return;
    }
    if (country.value.isEmpty || zone.value.isEmpty) {
      Get.snackbar('Error', 'PaÃ­s y zona son obligatorios');
      return;
    }

    isLoading.value = true;
    try {
      final userId = supabase.SupabaseClient.currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Subida de imagen (pendiente implementaciÃ³n)
      String? finalPhotoUrl = photoUrl.value;
      // if (pickImage != null) finalPhotoUrl = await uploadToCloudinary(pickImage!);

      await supabase.SupabaseClient
          .from('users')
          .update({
            'username': username.value.trim(),
            'photo_url': finalPhotoUrl,
            'country': country.value,
            'locality': zone.value,
            'gender': gender.value,
            'profile_completed': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      if (Get.isRegistered<SessionController>()) {
        await Get.find<SessionController>().loadUserData();
      }

      await GetStorage().write('loginUserId', userId);
      await GetStorage().write('loginType', 2);

      Get.snackbar('Ã‰xito', 'Perfil completado correctamente');
      Get.offAllNamed('/bottom-bar');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo guardar: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void selectCountry(Map<String, String> countryData) {
    selectedCountry.value = countryData;
    country.value = countryData['code'] ?? '';
  }

  void selectGender(String value) {
    selectedGender.value = value;
    gender.value = value;
  }

  Future<void> logout() async {
    await Get.find<AuthService>().signOut();
    Get.offAllNamed('/login');
  }
}
