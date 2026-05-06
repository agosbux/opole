// lib/pages/search_page/widget/search_reel_thumb.dart
// ===================================================================
// SEARCH REEL THUMB - OPTIMIZADO PARA MEMORIA
// ===================================================================
// ✅ Libera VideoPlayerController al salir de pantalla
// ✅ Reinicializa solo cuando vuelve a ser visible (>50%)
// ✅ Mantiene thumbnail estático como fallback
// ✅ Previene múltiples inicializaciones simultáneas
// ✅ Sin AutomaticKeepAliveClientMixin para evitar retención
// ===================================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SearchReelThumb extends StatefulWidget {
  final dynamic reel;
  final bool autoPlay;

  const SearchReelThumb({
    super.key,
    required this.reel,
    this.autoPlay = true,
  });

  @override
  State<SearchReelThumb> createState() => _SearchReelThumbState();
}

class _SearchReelThumbState extends State<SearchReelThumb> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isVideoAvailable = false;
  bool _hasError = false;
  
  // Evitar múltiples inicializaciones concurrentes
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    // El video se inicializará cuando el widget sea visible
  }

  Future<void> _initializeVideo() async {
    // Evitar inicializaciones duplicadas
    if (_videoController != null || _isInitializing) return;
    
    final videoUrl = widget.reel.videoUrl ?? widget.reel.mediaUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      if (mounted) {
        setState(() => _isVideoAvailable = false);
      }
      return;
    }

    _isInitializing = true;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _isInitialized = true;
        _isVideoAvailable = true;
        _hasError = false;
      });

      _videoController!
        ..setVolume(0)
        ..setLooping(true);

      if (widget.autoPlay) {
        _videoController!.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideoAvailable = false;
          _hasError = true;
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  void _handleVisibility(VisibilityInfo info) {
    final isFullyInvisible = info.visibleFraction == 0;
    final isMainlyVisible = info.visibleFraction > 0.5;

    if (isFullyInvisible) {
      // Liberar recursos inmediatamente al salir completamente de pantalla
      _videoController?.dispose();
      _videoController = null;
      _isInitialized = false;
    } else if (isMainlyVisible && _videoController == null) {
      // Reinicializar cuando vuelve a ser visible
      _initializeVideo();
    } else if (_videoController != null) {
      // Controlar reproducción/pausa según visibilidad parcial
      if (isMainlyVisible && !_videoController!.value.isPlaying) {
        _videoController!.play();
      } else if (!isMainlyVisible && _videoController!.value.isPlaying) {
        _videoController!.pause();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('vis_${widget.reel.id}'),
      onVisibilityChanged: _handleVisibility,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.hardEdge,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isVideoAvailable && _isInitialized && _videoController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return _ThumbnailFallback(
      reel: widget.reel,
      hasError: _hasError,
    );
  }
}

// 🖼️ Fallback con thumbnail estático (mismo que tu implementación original)
class _ThumbnailFallback extends StatelessWidget {
  final dynamic reel;
  final bool hasError;

  const _ThumbnailFallback({
    required this.reel,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = reel.thumbnailUrl ?? reel.coverImage ?? reel.videoImage;
    
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty && !hasError) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildShimmer(),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }
    
    return _buildPlaceholder();
  }

  Widget _buildShimmer() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasError ? Icons.error_outline : Icons.video_library,
              color: Colors.grey[400],
              size: 32,
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Text(
                'Error al cargar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}