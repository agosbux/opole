import 'dart:async';
import 'dart:io';
import 'package:opole/pages/preview_hash_tag_page/model/hash_tag_data.dart';
import 'package:opole/pages/preview_hash_tag_page/model/hash_tag_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opole/core/services/supabase_client.dart' as local;
import 'package:opole/custom/custom_image_picker.dart';
import 'package:opole/pages/preview_hash_tag_page/model/create_hash_tag_model.dart';
import 'package:opole/pages/preview_hash_tag_page/model/fetch_hash_tag_model.dart';
import 'package:opole/pages/edit_reels_page/model/edit_reels_model.dart';
import 'package:opole/services/cloudinary_service.dart'; // ðŸ‘ˆ Importar Cloudinary
import 'package:opole/ui/image_picker_bottom_sheet_ui.dart';
import 'package:opole/ui/loading_ui.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/internet_connection.dart';
import 'package:opole/utils/utils.dart';

class EditReelsController extends GetxController {
  EditReelsModel? editReelsModel;

  String videoCaption = "";
  String videoUrl = "";
  String videoId = "";
  String videoThumbnail = "";
  String? selectedImage; // nueva imagen seleccionada (path local)

  TextEditingController captionController = TextEditingController();

  FetchHashTagModel? fetchHashTagModel;
  CreateHashTagModel? createHashTagModel;

  bool isLoadingHashTag = false;
  List<HashTagData> hastTagCollection = [];
  List<HashTagData> filterHashtag = [];

  RxBool isShowHashTag = false.obs;
  List<String> userInputHashtag = [];

  final CloudinaryService _cloudinaryService = CloudinaryService(); // ðŸ‘ˆ Instancia

  @override
  void onInit() {
    init();
    Utils.showLog("Upload Reels Controller Initialized...");
    super.onInit();
  }

  Future<void> init() async {
    final arguments = Get.arguments;
    Utils.showLog("Selected Video => $arguments");

    videoUrl = arguments["video"] ?? "";
    videoThumbnail = arguments["image"] ?? "";
    videoCaption = arguments["caption"] ?? "";
    videoId = arguments["videoId"] ?? "";
    captionController.text = videoCaption;

    await onGetHashTag();
  }

  // ===================================================================
  // ðŸ”¹ CARGAR HASHTAGS DESDE SUPABASE
  // ===================================================================
  Future<void> onGetHashTag() async {
    fetchHashTagModel = null;
    isLoadingHashTag = true;
    update(["onGetHashTag"]);

    try {
      final response = await local.SupabaseClient.from('hashtags')
          .select()
          .order('usage_count', ascending: false);

      if (response is List) {
        final data = response.map((e) => HashTagData.fromJson(e)).toList();
        fetchHashTagModel = FetchHashTagModel(data: data);
        hastTagCollection.assignAll(data);
        Utils.showLog("Hashtags cargados: ${hastTagCollection.length}");
      }
    } catch (e, stack) {
      Utils.showLog("âŒ Error cargando hashtags: $e");
      print(stack);
    } finally {
      isLoadingHashTag = false;
      update(["onGetHashTag"]);
    }
  }

  void onSelectHashtag(int index) {
    String text = captionController.text;
    List<String> words = text.split(' ');
    if (words.isNotEmpty) words.removeLast();

    captionController.text = "${words.join(' ')} #${filterHashtag[index].hashTag} ";
    captionController.selection = TextSelection.fromPosition(TextPosition(offset: captionController.text.length));
    isShowHashTag.value = false;
    update(["onChangeHashtag"]);
  }

  void onChangeHashtag() async {
    String text = captionController.text;
    List<String> words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (words[i].length > 1 && words[i].indexOf('#') == words[i].lastIndexOf('#')) {
        if (words[i].endsWith('#')) {
          words[i] = words[i].replaceFirst('#', ' #');
        }
      }
    }
    captionController.text = words.join(' ');
    captionController.selection = TextSelection.fromPosition(
      TextPosition(offset: captionController.text.length),
    );

    String updatedText = captionController.text;
    List<String> parts = updatedText.split(' ');

    await 10.milliseconds.delay();

    final captionText = parts.where((element) => !element.startsWith('#')).join(' ');
    userInputHashtag = parts.where((element) => element.startsWith('#')).toList();

    if (parts.isNotEmpty) {
      final lastWord = parts.last;
      Utils.showLog("Caption => $captionText");
      Utils.showLog("Last Word => $lastWord");

      if (lastWord.startsWith("#")) {
        final searchHashtag = lastWord.substring(1);
        filterHashtag = hastTagCollection
            .where((element) => (element.hashTag?.toLowerCase() ?? "").contains(searchHashtag.toLowerCase()))
            .toList();
        isShowHashTag.value = true;
        update(["onGetHashTag"]);
      } else {
        filterHashtag.clear();
        isShowHashTag.value = false;
      }
    }
    update(["onChangeHashtag"]);
  }

  void onToggleHashTag(bool value) {
    isShowHashTag.value = value;
  }

  Future<void> onChangeThumbnail(BuildContext context) async {
    await ImagePickerBottomSheetUi.show(
      context: context,
      onClickCamera: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.camera);
        if (imagePath != null) {
          selectedImage = imagePath;
          videoThumbnail = imagePath; // actualizamos vista previa
          update(["onChangeThumbnail"]);
        }
      },
      onClickGallery: () async {
        final imagePath = await CustomImagePicker.pickImage(ImageSource.gallery);
        if (imagePath != null) {
          selectedImage = imagePath;
          videoThumbnail = imagePath;
          update(["onChangeThumbnail"]);
        }
      },
    );
  }

  // ===================================================================
  // ðŸ”¹ SUBIR NUEVA MINIATURA A CLOUDINARY (si se cambiÃ³)
  // ===================================================================
  Future<String?> _uploadThumbnailToCloudinary(File imageFile) async {
    try {
      final url = await _cloudinaryService.uploadImage(
        imageFile,
        folder: "thumbnails",
      );
      return url;
    } catch (e) {
      Utils.showLog("âŒ Error subiendo thumbnail a Cloudinary: $e");
      return null;
    }
  }

  // ===================================================================
  // ðŸ”¹ EDITAR REEL
  // ===================================================================
  Future<void> onEditUploadReels() async {
    Utils.showLog("Reels Uploading...");
    if (!InternetConnection.isConnect.value) {
      Utils.showToast(EnumLocal.txtConnectionLost.name.tr);
      Utils.showLog("Internet Connection Lost !!");
      return;
    }

    Get.dialog(const PopScope(canPop: false, child: LoadingUi()), barrierDismissible: false);

    try {
      final currentUserId = local.SupabaseClient.currentUserId;
      if (currentUserId == null) throw Exception("Usuario no autenticado");

      // 1. Procesar hashtags
      List<String> hashTagIds = [];

      for (int index = 0; index < userInputHashtag.length; index++) {
        final hashTag = userInputHashtag[index];
        if (hashTag.isEmpty || !hashTag.startsWith("#")) continue;

        final searchHashtag = hashTag.substring(1).trim();
        if (searchHashtag.isEmpty) continue;

        Utils.showLog("Procesando hashtag: $searchHashtag");

        final existing = await local.SupabaseClient.from('hashtags')
            .select()
            .eq('name', searchHashtag)
            .maybeSingle();

        if (existing != null) {
          hashTagIds.add(existing['id'] as String);
        } else {
          final newHashTag = await local.SupabaseClient.from('hashtags')
              .insert({'name': searchHashtag})
              .select()
              .single();
          hashTagIds.add(newHashTag['id'] as String);
        }
      }

      Utils.showLog("IDs de hashtags: $hashTagIds");

      // 2. Si se cambiÃ³ la miniatura, subirla a Cloudinary
      String finalThumbnailUrl = videoThumbnail;
      if (selectedImage != null && selectedImage!.isNotEmpty && selectedImage != videoThumbnail) {
        final file = File(selectedImage!);
        if (await file.exists()) {
          final uploadedUrl = await _uploadThumbnailToCloudinary(file);
          if (uploadedUrl != null) {
            finalThumbnailUrl = uploadedUrl;
          }
        }
      }

      // 3. Actualizar el reel en Supabase
      await local.SupabaseClient.from('reels')
          .update({
            'caption': captionController.text.trim(),
            if (finalThumbnailUrl != videoThumbnail) 'thumbnail': finalThumbnailUrl,
          })
          .eq('id', videoId)
          .eq('user_id', currentUserId);

      // 4. Actualizar relaciones reel-hashtags
      await local.SupabaseClient.from('reel_hashtags')
          .delete()
          .eq('reel_id', videoId);

      if (hashTagIds.isNotEmpty) {
        for (final hashtagId in hashTagIds) {
          await local.SupabaseClient.from('reel_hashtags').insert({
            'reel_id': videoId,
            'hashtag_id': hashtagId,
          });
        }
      }

      // 5. Incrementar contador de uso
      for (final hashtagId in hashTagIds) {
        await local.SupabaseClient.rpc('incrementar_uso_hashtag', params: {'hashtag_id': hashtagId});
      }

      Utils.showToast(EnumLocal.txtReelsUploadSuccessfully.name.tr);
      Get.close(2);
    } catch (e, stack) {
      Utils.showLog("âŒ Error en onEditUploadReels: $e");
      print(stack);
      Utils.showToast(EnumLocal.txtSomeThingWentWrong.name.tr);
    } finally {
      Get.back();
    }
  }
}
