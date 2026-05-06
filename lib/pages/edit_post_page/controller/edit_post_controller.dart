import 'package:flutter/material.dart';
import 'package:opole/pages/preview_hash_tag_page/model/hash_tag_data.dart';
import 'package:get/get.dart';
import 'package:opole/core/services/supabase_client.dart' as local;
import 'package:opole/pages/preview_hash_tag_page/model/create_hash_tag_model.dart';
import 'package:opole/pages/preview_hash_tag_page/model/fetch_hash_tag_model.dart';
import 'package:opole/pages/edit_post_page/model/edit_post_model.dart';
import 'package:opole/ui/loading_ui.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/internet_connection.dart';
import 'package:opole/utils/utils.dart';

class EditPostController extends GetxController {
  List<String> selectedImages = [];
  EditPostModel? editPostModel;

  String caption = "";
  String postId = "";

  bool isLoadingHashTag = false;
  List<HashTagData> hastTagCollection = [];
  List<HashTagData> filterHashtag = [];

  RxBool isShowHashTag = false.obs;
  List<String> userInputHashtag = [];

  FetchHashTagModel? fetchHashTagModel;
  CreateHashTagModel? createHashTagModel;

  TextEditingController captionController = TextEditingController();
  TextEditingController hashTagController = TextEditingController();

  @override
  void onInit() {
    init();
    super.onInit();
    Utils.showLog("Upload Post Controller Initialized...");
  }

  Future<void> init() async {
    Utils.showLog("Selected Images Length => ${Get.arguments["images"]?.length ?? 0}");

    captionController.clear();

    if (Get.arguments["images"] != null) {
      selectedImages.addAll(Get.arguments["images"]);
    }
    if (Get.arguments["postId"] != null) {
      postId = Get.arguments["postId"];
    }
    if (Get.arguments["caption"] != null) {
      caption = Get.arguments["caption"];
      captionController = TextEditingController(text: caption);
    }
    await onGetHashTag();
    createHashTagModel = null;
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

  // ===================================================================
  // ðŸ”¹ CARGAR HASHTAGS DESDE SUPABASE (tabla 'hashtags')
  // ===================================================================
  Future<void> onGetHashTag() async {
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

  // ===================================================================
  // ðŸ”¹ EDITAR POST (SOLO DATOS, NO ARCHIVOS)
  // ===================================================================
  Future<void> onEditPost() async {
    Utils.showLog(EnumLocal.txtPostUploading.name.tr);
    if (!InternetConnection.isConnect.value) {
      Utils.showToast(EnumLocal.txtConnectionLost.name.tr);
      Utils.showLog("Internet Connection Lost !!");
      return;
    }

    Get.dialog(const PopScope(canPop: false, child: LoadingUi()), barrierDismissible: false);

    try {
      final currentUserId = local.SupabaseClient.currentUserId;
      if (currentUserId == null) throw Exception("Usuario no autenticado");

      // 1. Procesar hashtags (obtener o crear)
      List<String> hashTagIds = [];

      for (int index = 0; index < userInputHashtag.length; index++) {
        final hashTag = userInputHashtag[index];
        if (hashTag.isEmpty || !hashTag.startsWith("#")) continue;

        final searchHashtag = hashTag.substring(1).trim();
        if (searchHashtag.isEmpty) continue;

        Utils.showLog("Procesando hashtag: $searchHashtag");

        // Buscar si ya existe
        final existing = await local.SupabaseClient.from('hashtags')
            .select()
            .eq('name', searchHashtag)
            .maybeSingle();

        if (existing != null) {
          hashTagIds.add(existing['id'] as String);
          Utils.showLog("Hashtag existente: ${existing['name']}");
        } else {
          // Crear nuevo hashtag
          final newHashTag = await local.SupabaseClient.from('hashtags')
              .insert({'name': searchHashtag})
              .select()
              .single();
          hashTagIds.add(newHashTag['id'] as String);
          Utils.showLog("Nuevo hashtag creado: $searchHashtag");
        }
      }

      Utils.showLog("IDs de hashtags: $hashTagIds");

      // 2. Actualizar el post (tabla 'reels')
      await local.SupabaseClient.from('reels')
          .update({'caption': captionController.text.trim()})
          .eq('id', postId)
          .eq('user_id', currentUserId);

      // 3. Actualizar relaciones post-hashtag
      await local.SupabaseClient.from('reel_hashtags')
          .delete()
          .eq('reel_id', postId);

      if (hashTagIds.isNotEmpty) {
        for (final hashtagId in hashTagIds) {
          await local.SupabaseClient.from('reel_hashtags').insert({
            'reel_id': postId,
            'hashtag_id': hashtagId,
          });
        }
      }

      // 4. Incrementar contador de uso de hashtags (opcional)
      for (final hashtagId in hashTagIds) {
        await local.SupabaseClient.rpc('incrementar_uso_hashtag', params: {'hashtag_id': hashtagId});
      }

      Utils.showToast(EnumLocal.txtPostUploadSuccessfully.name.tr);
      Get.close(2);
    } catch (e, stack) {
      Utils.showLog("âŒ Error en onEditPost: $e");
      print(stack);
      Utils.showToast(EnumLocal.txtSomeThingWentWrong.name.tr);
    } finally {
      Get.back();
    }
  }
}
