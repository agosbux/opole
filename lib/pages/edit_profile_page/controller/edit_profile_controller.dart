// lib/pages/edit_profile_page/controllers/edit_profile_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:opole/custom/custom_image_picker.dart';
import 'package:opole/ui/image_picker_bottom_sheet_ui.dart';
import 'package:opole/ui/loading_ui.dart';
import 'package:opole/services/cloudinary_service.dart';
import 'package:opole/utils/constants.dart';
import 'package:opole/utils/internet_connection.dart';
import 'package:opole/utils/utils.dart';

// âœ… Importar Supabase en lugar de Firebase
import 'package:opole/core/services/supabase_client.dart' as local;

class EditProfileController extends GetxController {
  // Text Controllers - SOLO PARA EL FORMULARIO
  late TextEditingController fullNameController;
  late TextEditingController userNameController;
  late TextEditingController bioDetailsController;
  late TextEditingController provinceController;  // â† Controlador del formulario
  late TextEditingController cityController;      // â† Controlador del formulario

  // âš ï¸ AÃ‘ADIDO: idCodeController para resolver el error
  TextEditingController idCodeController = TextEditingController();

  // Variables de estado
  final CloudinaryService _cloudinaryService = CloudinaryService();
  String selectedGender = "male";
  String profileImage = "";
  String? pickImage;
  String? userId;
  bool _isSaving = false;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _loadUserData();
    _initializeCloudinary();
  }

  void _initializeControllers() {
    fullNameController = TextEditingController();
    userNameController = TextEditingController();
    bioDetailsController = TextEditingController();
    provinceController = TextEditingController();  // â† Solo para el form
    cityController = TextEditingController();      // â† Solo para el form
  }

  Future<void> _initializeCloudinary() async {
    await _cloudinaryService.init();
  }

  Future<void> _loadUserData() async {
    // âœ… Reemplazar GetStorage().read("loginUserId") ?? "" por GetStorage
    userId = GetStorage().read("loginUserId") ?? "";

    if (userId == null || userId!.isEmpty) {
      Utils.showLog("âŒ Error: No hay usuario logueado");
      return;
    }

    try {
      // âœ… Reemplazar Firestore con Supabase
      final response = await local.SupabaseClient
          .from('profiles')
          .select()
          .eq('id', userId!)
          .maybeSingle();

      if (response != null) {
        // Mapear campos de Supabase (ajusta segÃºn tu esquema)
        profileImage = response['image'] ?? "";
        fullNameController.text = response['name'] ?? "";
        userNameController.text = response['userName'] ?? "";
        bioDetailsController.text = response['bio'] ?? "";
        selectedGender = response['gender']?.toString().toLowerCase() ?? "male";

        // âœ… Cargar ubicaciÃ³n en los controllers del FORMULARIO
        provinceController.text = response['province'] ?? "";
        cityController.text = response['city'] ?? "";

        // âœ… ACTUALIZAR Utils (para otras partes de la app)
        // Asume que Utils.updateLocationFromFirebase estÃ¡ adaptado para trabajar con un Map de Supabase
        Utils.updateLocationFromFirebase(response);

        update();
        Utils.showLog("âœ… Perfil cargado correctamente");
      }
    } catch (e) {
      Utils.showLog("âŒ Error cargando perfil: $e");
    }
  }

  /// Seleccionar imagen de perfil
  Future<void> onPickImage(BuildContext context) async {
    await ImagePickerBottomSheetUi.show(
      context: context,
      onClickCamera: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.camera);
        if (imagePath != null) {
          pickImage = imagePath;
          update(["onPickImage"]);
        }
      },
      onClickGallery: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.gallery);
        if (imagePath != null) {
          pickImage = imagePath;
          update(["onPickImage"]);
        }
      },
    );
  }

  /// Cambiar gÃ©nero
  void onChangeGender(String gender) {
    selectedGender = gender;
    update(["onChangeGender"]);
  }

  /// Validar formulario
  bool _validateForm() {
    if (fullNameController.text.trim().isEmpty) {
      Utils.showToast("Por favor, ingresÃ¡ tu nombre");
      return false;
    }

    if (userNameController.text.trim().isEmpty) {
      Utils.showToast("Por favor, ingresÃ¡ tu usuario");
      return false;
    }

    if (provinceController.text.trim().isEmpty) {
      Utils.showToast("Por favor ingresÃ¡ tu provincia");
      return false;
    }

    if (cityController.text.trim().isEmpty) {
      Utils.showToast("Por favor ingresÃ¡ tu ciudad");
      return false;
    }

    return true;
  }

  /// Guardar perfil
  Future<void> onSaveProfile() async {
    if (_isSaving) return;

    if (!_validateForm()) return;

    if (!InternetConnection.isConnect.value) {
      Utils.showToast(AppConstants.errorNoInternet);
      return;
    }

    _isSaving = true;

    Get.dialog(
      const PopScope(canPop: false, child: LoadingUi()),
      barrierDismissible: false,
    );

    try {
      String? imageUrl = profileImage;

      // Subir nueva imagen si existe
      if (pickImage != null) {
        Utils.showLog("ðŸ“¸ Procesando nueva imagen...");

        // âœ… CORREGIDO: Ahora pasamos los parÃ¡metros requeridos
        imageUrl = await _cloudinaryService.uploadProfileImage(
          pickImage!, // Primer parÃ¡metro: String filePath
          folder: 'profile_images', // ParÃ¡metro opcional: folder
        );

        if (imageUrl == null) {
          Get.back();
          _isSaving = false;

          final shouldContinue = await Get.dialog<bool>(
            AlertDialog(
              title: const Text("Error con la imagen"),
              content: const Text("Â¿Deseas continuar sin cambiar la foto de perfil?"),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text("Continuar"),
                ),
              ],
            ),
          ) ?? false;

          if (!shouldContinue) return;

          Get.dialog(
            const PopScope(canPop: false, child: LoadingUi()),
            barrierDismissible: false,
          );

          imageUrl = profileImage;
        }
      }

      // âœ… Preparar datos SOLO con campos necesarios
      final updateData = {
        'name': fullNameController.text.trim(),
        'userName': userNameController.text.trim(),
        'bio': bioDetailsController.text.trim(),
        'gender': selectedGender,
        'province': provinceController.text.trim(), // â† Del formulario
        'city': cityController.text.trim(),         // â† Del formulario
        'countryCode': AppConstants.countryCode,
        'countryName': AppConstants.countryName,
        'country': AppConstants.countryName,
        'countryFlagImage': AppConstants.countryFlag,
        'locationCode': AppConstants.countryCode,
        'locationName': AppConstants.countryName,
        'updated_at': DateTime.now().toIso8601String(), // âœ… Reemplazo de FieldValue.serverDateTime()
      };

      if (imageUrl != null) {
        updateData['image'] = imageUrl;
      }

      // âœ… Reemplazar Firestore con Supabase update
      await local.SupabaseClient
          .from('profiles')
          .update(updateData)
          .eq('id', userId);

      // âœ… Actualizar Utils despuÃ©s de guardar
      Utils.provinceController.text = provinceController.text;
      Utils.cityController.text = cityController.text;
      Utils.countryController.text = AppConstants.countryName;
      Utils.flagController.text = AppConstants.countryFlag;

      profileImage = imageUrl ?? profileImage;
      pickImage = null;

      Get.back(); // cerrar loading
      _isSaving = false;

      Utils.showToast(AppConstants.successProfileUpdated);
      Get.back(); // volver a la pantalla anterior

    } catch (e) {
      Get.back(); // cerrar loading
      _isSaving = false;

      Utils.showLog("âŒ Error guardando perfil: $e");

      Get.dialog(
        AlertDialog(
          title: const Text("Error"),
          content: Text(AppConstants.errorSaveFailed),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Aceptar"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    userNameController.dispose();
    bioDetailsController.dispose();
    provinceController.dispose();
    cityController.dispose();
    idCodeController.dispose(); // â† AÃ±adido para liberar el recurso
    super.onClose();
  }
}
