import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opole/core/services/supabase_client.dart' as local;

class HashtagModel {
  final String hashTag;
  final int? totalHashTagUsedCount;

  HashtagModel({required this.hashTag, this.totalHashTagUsedCount});
}

class UploadReelsController extends GetxController {
  // Video
  VideoPlayerController? _controller;
  final RxBool isVideoPlaying = false.obs;
  final RxBool isVideoLoading = false.obs;

  // Video & Thumbnail
  final RxString selectedVideoPath = ''.obs;
  final RxString videoThumbnail = RxString('');
  final RxBool hasVideo = false.obs;

  // Caption
  late TextEditingController captionController;
  final RxInt captionLength = 0.obs;
  final int maxCaptionLength = 150;

  // Hashtags
  final RxBool isShowHashTag = false.obs;
  final RxBool isLoadingHashTag = false.obs;
  final RxList<HashtagModel> filterHashtag = <HashtagModel>[].obs;
  final RxString searchHashtag = ''.obs;

  // Upload
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString uploadMessage = ''.obs;

  @override
  void onInit() async {
    super.onInit();
    captionController = TextEditingController();
    captionController.addListener(_onCaptionChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await init();
      } catch (e) {
        Get.snackbar('Error', 'No se pudo cargar el video',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    });
  }

  @override
  void onClose() {
    captionController.removeListener(_onCaptionChanged);
    captionController.dispose();
    _controller?.dispose();
    super.onClose();
  }

  Future<void> init() async {
    final data = Get.arguments;
    if (data == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickVideo());
      return;
    }
    final videoData = data["video"];
    if (videoData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickVideo());
      return;
    }
    selectedVideoPath.value = videoData.toString();
    hasVideo.value = true;
    await _initializeVideoController(selectedVideoPath.value);
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        selectedVideoPath.value = pickedFile.path;
        hasVideo.value = true;
        videoThumbnail.value = pickedFile.path; // placeholder
        await _initializeVideoController(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo seleccionar el video', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _initializeVideoController(String path) async {
    try {
      isVideoLoading.value = true;
      await _controller?.dispose();
      _controller = VideoPlayerController.file(File(path))
        ..initialize().then((_) {
          isVideoLoading.value = false;
          _controller?.setLooping(true);
          _controller?.play();
          isVideoPlaying.value = true;
          update();
        });
    } catch (e) {
      isVideoLoading.value = false;
      rethrow;
    }
  }

  void _onCaptionChanged() {
    captionLength.value = captionController.text.length;
  }

  // ===================================================================
  // ðŸ”¹ THUMBNAIL METHODS
  // ===================================================================
  void onChangeThumbnail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Seleccionar de galerÃ­a'),
            onTap: () {
              Navigator.pop(context);
              _pickThumbnailFromGallery();
            },
          ),
          // Agrega mÃ¡s opciones si lo deseas (por ejemplo, cÃ¡mara)
        ],
      ),
    );
  }

  Future<void> _pickThumbnailFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        videoThumbnail.value = pickedFile.path;
        Get.snackbar('Ã‰xito', 'Miniatura actualizada', snackPosition: SnackPosition.BOTTOM);
        update(['onChangeThumbnail']);
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo seleccionar la imagen', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ===================================================================
  // ðŸ”¹ HASHTAG METHODS
  // ===================================================================
  void onToggleHashTag(bool value) {
    isShowHashTag.value = value;
    if (value && filterHashtag.isEmpty) {
      _loadHashtags();
    }
  }

  void onChangeHashtag() {
    final query = searchHashtag.value.trim();
    if (query.isEmpty) {
      _loadHashtags();
    } else {
      _loadHashtags().then((_) {
        final filtered = filterHashtag.value
            .where((h) => h.hashTag.toLowerCase().contains(query.toLowerCase()))
            .toList();
        filterHashtag.value = filtered;
        update(['onGetHashTag']);
      });
    }
  }

  Future<void> _loadHashtags() async {
    try {
      isLoadingHashTag.value = true;
      update(['onGetHashTag']);

      // Datos de prueba (reemplazar con llamada real a Supabase)
      filterHashtag.value = [
        HashtagModel(hashTag: 'opole', totalHashTagUsedCount: 1250),
        HashtagModel(hashTag: 'opole', totalHashTagUsedCount: 890),
        HashtagModel(hashTag: 'viral', totalHashTagUsedCount: 2340),
        HashtagModel(hashTag: 'trending', totalHashTagUsedCount: 1567),
        HashtagModel(hashTag: 'foryou', totalHashTagUsedCount: 3421),
      ];

      isLoadingHashTag.value = false;
      update(['onGetHashTag']);
    } catch (e) {
      isLoadingHashTag.value = false;
      update(['onGetHashTag']);
    }
  }

  void onSelectHashtag(int index) {
    if (index >= 0 && index < filterHashtag.value.length) {
      final hashtag = filterHashtag.value[index].hashTag;
      final formatted = '#$hashtag';
      if (!captionController.text.contains(formatted)) {
        if (captionController.text.isNotEmpty && !captionController.text.endsWith(' ')) {
          captionController.text += ' ';
        }
        captionController.text += formatted;
        _onCaptionChanged();
      }
    }
  }

  // ===================================================================
  // ðŸ”¹ UPLOAD METHOD
  // ===================================================================
  Future<void> onUploadReels() async {
    if (selectedVideoPath.value.isEmpty) {
      Get.snackbar('Error', 'Selecciona un video primero', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isUploading.value = true;
    uploadProgress.value = 0.0;

    try {
      final userId = local.SupabaseClient.currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');

      final videoFile = File(selectedVideoPath.value);
      final videoPath = 'reels/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4';

      await local.SupabaseClient.storage.from('reels').upload(videoPath, videoFile);
      uploadProgress.value = 0.5;

      final videoUrl = local.SupabaseClient.storage.from('reels').getPublicUrl(videoPath);

      await local.SupabaseClient.from('reels').insert({
        'user_id': userId,
        'video_url': videoUrl,
        'thumbnail_url': videoThumbnail.value.isNotEmpty ? videoThumbnail.value : null,
        'caption': captionController.text.trim(),
        'is_public': true,
        'total_likes': 0,
        'total_comments': 0,
        'total_views': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      uploadProgress.value = 1.0;

      Get.snackbar('Ã‰xito', 'Reel publicado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);

      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed('/bottom-bar');
      });
    } catch (e) {
      Get.snackbar('Error', 'No se pudo subir el reel',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isUploading.value = false;
    }
  }

  // ===================================================================
  // ðŸ”¹ GETTERS
  // ===================================================================
  VideoPlayerController? get videoController => _controller;
  String get thumbnailPath => videoThumbnail.value;
  bool get canUpload => selectedVideoPath.value.isNotEmpty && !isUploading.value;
}
