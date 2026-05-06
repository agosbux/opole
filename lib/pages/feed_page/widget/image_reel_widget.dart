// lib/pages/feed_page/widget/image_reel_widget.dart
// ===================================================================
// IMAGE REEL WIDGET v1.2 - Swipe Horizontal + Hearts + Preload (PROD)
// ===================================================================
// ✅ FIX: intensity corregido de String a HeartIntensity enum

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:opole/core/ui/heart_animation_layer.dart';
import 'package:opole/core/ui/image_preload_manager.dart';

class ImageReelWidget extends StatefulWidget {
  final List<String> images;
  final void Function(Offset tapPosition)? onDoubleTap;
  final VoidCallback? onInteraction;

  const ImageReelWidget({
    super.key,
    required this.images,
    this.onDoubleTap,
    this.onInteraction,
  });

  @override
  State<ImageReelWidget> createState() => _ImageReelWidgetState();
}

class _ImageReelWidgetState extends State<ImageReelWidget> {
  late final PageController _pageController;
  int _currentIndex = 0;
  final GlobalKey<HeartAnimationLayerState> _heartKey = GlobalKey();
  Timer? _preloadDebounce;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadNextImages();
    });
  }

  void _preloadNextImages() {
    if (!mounted) return;
    final next = widget.images.skip(_currentIndex).take(3).toList();
    ImagePreloadManager.instance.preload(context, next);
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _preloadDebounce?.cancel();
    _preloadDebounce = Timer(const Duration(milliseconds: 120), () {
      _preloadNextImages();
    });
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_isDragging) return;
    widget.onDoubleTap?.call(details.localPosition);
    // ✅ FIX: HeartIntensity.normal en lugar de String 'normal'
    _heartKey.currentState?.spawnHeart(
      details.localPosition,
      intensity: HeartIntensity.normal,
    );
  }

  @override
  void dispose() {
    _preloadDebounce?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HeartAnimationLayer(
      key: _heartKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onInteraction,
        onDoubleTapDown: _handleDoubleTap,
        onHorizontalDragStart: (_) => _isDragging = true,
        onHorizontalDragEnd: (_) => _isDragging = false,
        onHorizontalDragCancel: () => _isDragging = false,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: _onPageChanged,
              physics: widget.images.length > 1
                  ? const PageScrollPhysics().applyTo(const ClampingScrollPhysics())
                  : const NeverScrollableScrollPhysics(),
              itemBuilder: (_, index) => CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                fadeInDuration: const Duration(milliseconds: 100),
                memCacheWidth: 1080,
                placeholder: (_, __) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[900],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),

            // Indicador de posición (solo si hay más de 1 imagen)
            if (widget.images.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length.clamp(0, 6),
                    (i) {
                      final active = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 8 : 6,
                        height: active ? 8 : 6,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white54,
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
