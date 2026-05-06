import 'dart:io';
import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:opole/pages/create_reels_page/controller/create_reels_controller.dart';
import 'package:opole/routes/app_routes.dart';
import 'package:opole/utils/utils.dart';

class PreviewCreatedReelsController extends GetxController {
  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;
  
  final String videoUrl = Get.arguments["video"] ?? "";
  final String image = Get.arguments["image"] ?? "";
  final int time = Get.arguments["time"] ?? 0;
  final String songId = Get.arguments["songId"] ?? "";
  
  bool isVideoLoading = true;
  bool isPlaying = true;
  bool isShowPlayPauseIcon = false;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    try {
      // ðŸ‘‡ SOLUCIÃ“N CRÃTICA: Detectar tipo de video
      if (videoUrl.startsWith('http')) {
        // Es URL remota
        videoPlayerController = VideoPlayerController.network(videoUrl);
      } else {
        // Es archivo local
        videoPlayerController = VideoPlayerController.file(File(videoUrl));
      }

      await videoPlayerController!.initialize();
      
      chewieController = ChewieController(
        videoPlayerController: videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: false,
        allowedScreenSleep: false,
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      );
      
      videoPlayerController!.addListener(_onVideoControllerListener);
      isVideoLoading = false;
      update(["onChangeLoading"]);
      
    } catch (e) {
      Utils.showLog("Error initializing video player: $e");
      isVideoLoading = false;
      update(["onChangeLoading"]);
    }
  }

  void _onVideoControllerListener() {
    if (videoPlayerController?.value.hasError ?? false) {
      Utils.showLog("Video player error: ${videoPlayerController?.value.errorDescription}");
    }
  }

  void onClickVideo() {
    isShowPlayPauseIcon = true;
    update(["onShowPlayPauseIcon"]);
    
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      isShowPlayPauseIcon = false;
      update(["onShowPlayPauseIcon"]);
    });
  }

  void onClickPlayPause() {
    if (isPlaying) {
      videoPlayerController?.pause();
    } else {
      videoPlayerController?.play();
    }
    isPlaying = !isPlaying;
    update(["onChangePlayPauseIcon"]);
  }

  void onStopVideo() {
    videoPlayerController?.pause();
  }

  void onClickNext() {
    onStopVideo();
    
    // Obtener el controller de CreateReels
    final createReelsController = Get.find<CreateReelsController>();
    
    // Llamar al mÃ©todo uploadReel
    createReelsController.uploadReel(
      videoPath: videoUrl,
      thumbnailPath: image,
      caption: "", // AquÃ­ puedes agregar caption si lo necesitas
      soundId: songId,
    );
  }

  @override
  void onClose() {
    _timer?.cancel();
    videoPlayerController?.dispose();
    chewieController?.dispose();
    super.onClose();
  }
}

