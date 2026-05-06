// lib/pages/reels_page/widget/video_player_widget.dart
// ===================================================================
// VIDEO PLAYER WIDGET v8.1 - PRODUCTION SAFE (FULL ALIGNMENT)
// ===================================================================
// ✅ reelId pasado como parámetro (no parseado de URL)
// ✅ Logging defensivo en debug para errores de listener
// ✅ Retry con límite máximo + fallback UI
// ✅ _finalRetentionSent persistente para evitar duplicados
// ✅ try-catch en controller.value, granularidad de notifiers, performance
// 🆕 v8.1: Reordenamiento de dispose() y protección extra en _processAnalytics
// ===================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, unawaited;
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:opole/core/video/video_controller_pool.dart';
import 'package:opole/core/engagement/reel_engagement_service.dart';
import 'package:opole/core/services/supabase_client.dart';
import 'package:opole/core/utils/cloudinary_url_normalizer.dart';
import 'package:opole/core/video/video_analytics_ticker.dart';

// -------------------------------------------------------------------
// ESTADO UNIFICADO
// -------------------------------------------------------------------
@immutable
class _VideoState {
  final bool isControllerReady;
  final bool hasError;
  final bool isFirstFrameReady;

  const _VideoState({
    this.isControllerReady = false,
    this.hasError = false,
    this.isFirstFrameReady = false,
  });

  bool get shouldShowVideo =>
      isControllerReady && !hasError && isFirstFrameReady;
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  final String reelId; // 🆕 Pasado explícitamente desde el padre
  final VoidCallback? onComplete;
  final VoidCallback? onVideoStart;
  final Function(int milliseconds)? onWatchTimeUpdate;
  final Function(Duration position)? onVideoProgress; // 🆕 Callback de progreso continuo

  const VideoPlayerWidget({
    Key? key,
    required this.url,
    required this.reelId, // 🆕 Requerido
    this.onComplete,
    this.onVideoStart,
    this.onWatchTimeUpdate,
    this.onVideoProgress, // 🆕 Agregado al constructor
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  int _retryCount = 0; // 🆕 Contador de reintentos
  static const int _maxRetries = 2; // 🆕 Límite configurable
  bool _disposed = false;

  // ===================================================================
  // 🛡️ HELPER DE SEGURIDAD (SIN .disposed)
  // ===================================================================
  bool get _isControllerSafe {
    final c = _controller;
    if (c == null) return false;
    try {
      return c.value.isInitialized;
    } catch (_) {
      return false;
    }
  }

  // -----------------------------------------------------------------
  // NOTIFIERS OPTIMIZADOS
  // -----------------------------------------------------------------
  final ValueNotifier<_VideoState> _videoStateNotifier =
      ValueNotifier(const _VideoState());
  final ValueNotifier<bool> _isBufferingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);

  // -----------------------------------------------------------------
  // ANIMACIÓN DE CROSSFADE
  // -----------------------------------------------------------------
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final ValueNotifier<bool> _showThumbnailNotifier = ValueNotifier<bool>(true);

  VoidCallback? _controllerListener;

  // Analytics y estado interno
  final VideoControllerPool _pool = VideoControllerPool.instance;
  final ReelEngagementService _engagement = ReelEngagementService.instance;

  Duration _currentWatchTime = Duration.zero;
  Duration _lastReportedPosition = Duration.zero;
  bool _hasStarted = false;
  bool _hasTracked3s = false;
  bool _hasTracked10s = false;
  bool _hasNotifiedComplete = false;
  bool _hasTrackedFinalRetention = false;
  bool _isCleaning = false;
  bool _finalRetentionSent = false; // 🆕 Flag persistente para evitar duplicados

  String get _userId => SupabaseClient.currentUserId ?? '';

  String get _thumbnailUrl {
    if (widget.url.isEmpty) return '';
    return CloudinaryUrlNormalizer.normalize(
      widget.url,
      isVideo: false,
      transformations: ['so_0', 'f_auto', 'q_auto:good', 'w_540', 'c_limit'],
    );
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _initController();
    VideoAnalyticsTicker.instance.addListener(_processAnalytics);
  }

  // -----------------------------------------------------------------
  // REACTIVE LISTENER (PROTEGIDO CON TRY-CATCH)
  // -----------------------------------------------------------------
  void _onControllerChanged() {
    if (!mounted || _disposed) return;
    final c = _controller;
    if (c == null) return;

    final VideoPlayerValue v;
    try {
      v = c.value;
    } catch (_) {
      return;
    }

    if (v.isBuffering != _isBufferingNotifier.value) {
      _isBufferingNotifier.value = v.isBuffering;
    }

    if (!_videoStateNotifier.value.isFirstFrameReady && v.buffered.isNotEmpty) {
      _activateFirstFrame();
    }
  }

  void _activateFirstFrame() {
    if (_disposed) return;

    _updateState(isFirstFrameReady: true);
    _fadeController.forward();

    Future.delayed(_Constants.thumbnailFadeDelay, () {
      if (mounted && !_disposed) {
        _showThumbnailNotifier.value = false;
      }
    });
  }

  void _updateState({
    bool? isControllerReady,
    bool? hasError,
    bool? isFirstFrameReady,
  }) {
    final current = _videoStateNotifier.value;
    final newState = _VideoState(
      isControllerReady: isControllerReady ?? current.isControllerReady,
      hasError: hasError ?? current.hasError,
      isFirstFrameReady: isFirstFrameReady ?? current.isFirstFrameReady,
    );
    if (current != newState) {
      _videoStateNotifier.value = newState;
    }
  }

  // -----------------------------------------------------------------
  // ANALYTICS (PROTEGIDO CON TRY-CATCH + NULL CHECK)
  // -----------------------------------------------------------------
  void _processAnalytics() {
    if (!mounted || _disposed) return;

    final controller = _controller;
    if (controller == null) return;

    // 🆕 PROTECCIÓN EXTRA: try-catch para evitar crash si el controlador fue dispuesto
    final VideoPlayerValue v;
    try {
      v = controller.value;
    } catch (_) {
      return; // El controlador ya no es válido, salir silenciosamente
    }

    if (!v.isInitialized) return;
    if (!v.isPlaying) return;

    final position = v.position;
    final duration = v.duration;
    if (duration == Duration.zero) return;

    _currentWatchTime = position;

    final double progress =
        (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    if ((progress - progressNotifier.value).abs() > 0.001) {
      progressNotifier.value = progress;
    }

    // Callback de progreso continuo (posición actual como Duration)
    if (widget.onVideoProgress != null) {
      widget.onVideoProgress!(position);
    }

    if (widget.onWatchTimeUpdate != null &&
        (position - _lastReportedPosition).inMilliseconds >= 500) {
      _lastReportedPosition = position;
      widget.onWatchTimeUpdate!(position.inMilliseconds);
    }

    if (!_hasTracked3s && position.inSeconds >= 3) {
      _hasTracked3s = true;
      if (_userId.isNotEmpty) {
        _engagement.trackWatchProgress(widget.reelId, _userId, position);
      }
    }

    if (!_hasTracked10s && position.inSeconds >= 10) {
      _hasTracked10s = true;
      if (_userId.isNotEmpty) {
        _engagement.trackWatchProgress(widget.reelId, _userId, position);
      }
    }

    if (!_hasStarted && position.inMilliseconds > 0) {
      _hasStarted = true;
      widget.onVideoStart?.call();
    }

    if (!_hasNotifiedComplete &&
        position >= duration - const Duration(milliseconds: 250)) {
      _hasNotifiedComplete = true;
      widget.onComplete?.call();
    }
  }

  void _sendFinalRetention() {
    // Flag persistente que NO se resetea en _resetTrackingFlags
    if (_isCleaning || _finalRetentionSent) return;

    final controller = _controller;
    if (controller == null) return;

    final VideoPlayerValue v;
    try {
      v = controller.value;
    } catch (_) {
      return;
    }

    if (!v.isInitialized) return;
    if (_currentWatchTime == Duration.zero) return;
    if (_userId.isEmpty) return;

    final totalDuration = v.duration;
    if (totalDuration.inMilliseconds == 0) return;

    _isCleaning = true;
    _finalRetentionSent = true; // Marcar como enviado para siempre

    final percent =
        _currentWatchTime.inMilliseconds / totalDuration.inMilliseconds;
    if (_currentWatchTime.inSeconds >= 1) {
      _engagement.trackRetention(
        widget.reelId, // Usar reelId explícito
        _userId,
        percent.clamp(0.0, 1.0),
        _currentWatchTime.inSeconds,
      );
    }
  }

  // -----------------------------------------------------------------
  // INIT CONTROLLER (CON RETRY LIMITADO + LOGGING)
  // -----------------------------------------------------------------
  Future<void> _initController() async {
    if (widget.url.isEmpty) {
      _updateState(isControllerReady: true, hasError: false);
      _isBufferingNotifier.value = false;
      return;
    }

    _resetTrackingFlags();

    try {
      final controller = await _pool.get(widget.url);

      // ✅ FIX "used after disposed": si el widget murió durante el await,
      // liberar inmediatamente el retain que hizo get() y salir sin tocar nada.
      if (!mounted || _disposed) {
        unawaited(_pool.release(widget.url));
        return;
      }

      // Verificar que el controller sigue siendo válido
      try {
        if (!controller.value.isInitialized) {
          unawaited(_pool.release(widget.url));
          _updateState(hasError: true);
          return;
        }
      } catch (_) {
        unawaited(_pool.release(widget.url));
        _updateState(hasError: true);
        return;
      }

      _controller = controller;
      _updateState(isControllerReady: true, hasError: false);

      _controllerListener = _onControllerChanged;
      try {
        controller.addListener(_controllerListener!);
      } catch (e) {
        if (kDebugMode) {
          Get.log('⚠️ [VIDEO] No se pudo agregar listener: $e');
        }
      }

      _isBufferingNotifier.value = controller.value.isBuffering;
      await controller.setLooping(true);

      // ✅ Check de nuevo después del await de setLooping
      if (!mounted || _disposed) return;

      if (controller.value.isInitialized && !controller.value.isBuffering) {
        _activateFirstFrame();
      }
    } catch (e) {
      if (kDebugMode) Get.log('❌ [VIDEO] Error init: $e');
      if (mounted && !_disposed) {
        _updateState(hasError: true);

        // Retry con límite máximo
        if (_retryCount < _maxRetries) {
          _retryCount++;
          Future.delayed(_Constants.retryDelay, () {
            if (mounted && !_disposed && _videoStateNotifier.value.hasError) {
              _initController();
            }
          });
        }
      }
    }
  }

  void _resetTrackingFlags() {
    _hasTracked3s = false;
    _hasTracked10s = false;
    _hasNotifiedComplete = false;
    // NO resetear _finalRetentionSent aquí
    _hasStarted = false;
    _lastReportedPosition = Duration.zero;
    _currentWatchTime = Duration.zero;
    _isCleaning = false;

    // Resetear retry count solo si no estamos en error permanente
    if (!_videoStateNotifier.value.hasError) {
      _retryCount = 0;
    }

    _isBufferingNotifier.value = true;
    progressNotifier.value = 0.0;

    _videoStateNotifier.value = const _VideoState();
    _fadeController.value = 0.0;
    _showThumbnailNotifier.value = true;
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url || widget.reelId != oldWidget.reelId) {
      if (_controllerListener != null) {
        final c = _controller;
        if (c != null) {
          try {
            c.removeListener(_controllerListener!);
          } catch (_) {}
        }
      }
      _sendFinalRetention();
      _resetTrackingFlags();
      _initController();
    }
  }

  @override
  void deactivate() {
    unawaited(_pool.pause(widget.url));
    _sendFinalRetention();
    super.deactivate();
  }

  // -----------------------------------------------------------------
  // 🆕 DISPOSE REORDENADO PARA MÁXIMA SEGURIDAD
  // -----------------------------------------------------------------
  @override
  void dispose() {
    _disposed = true;

    // 1. Remover listeners externos
    VideoAnalyticsTicker.instance.removeListener(_processAnalytics);

    // 2. Remover listener del controlador de video (si existe)
    final c = _controller;
    if (c != null && _controllerListener != null) {
      try {
        c.removeListener(_controllerListener!);
      } catch (_) {}
    }
    _controllerListener = null; // Limpiar referencia

    // 3. Liberar recursos locales de animación y UI
    _fadeController.dispose();
    _isBufferingNotifier.dispose();
    progressNotifier.dispose();
    _videoStateNotifier.dispose();
    _showThumbnailNotifier.dispose();

    // 4. Enviar analítica final ANTES de perder el controlador
    _sendFinalRetention();

    // 5. Liberar el controlador local
    _controller = null;

    // 6. 🆕 DEVOLVER AL POOL AL FINAL (evita que el pool disponga el controlador mientras aún limpiamos)
    _pool.release(widget.url);

    super.dispose();
  }

  // -----------------------------------------------------------------
  // BUILD OPTIMIZADO (SIN .disposed)
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // CAPA 1: THUMBNAIL
          ValueListenableBuilder<bool>(
            valueListenable: _showThumbnailNotifier,
            builder: (context, showThumbnail, _) {
              if (!showThumbnail) return const SizedBox.shrink();
              return _ThumbnailLayer(thumbnailUrl: _thumbnailUrl);
            },
          ),

          // CAPA 2: VIDEO CON FADE UNIFICADO
          ValueListenableBuilder<_VideoState>(
            valueListenable: _videoStateNotifier,
            builder: (context, state, _) {
              if (!state.isControllerReady || state.hasError) {
                return const SizedBox.shrink();
              }

              final controller = _controller;
              if (controller == null) return const SizedBox.shrink();

              try {
                if (!controller.value.isInitialized) return const SizedBox.shrink();
              } catch (_) {
                return const SizedBox.shrink();
              }

              return FadeTransition(
                opacity: _fadeAnimation,
                child: AspectRatio(
                  aspectRatio: (() {
                    try {
                      return controller.value.aspectRatio;
                    } catch (_) {
                      return 9.0 / 16.0;
                    }
                  })(),
                  child: VideoPlayer(controller),
                ),
              );
            },
          ),

          // CAPA 3: BUFFERING INDICATOR
          ValueListenableBuilder<bool>(
            valueListenable: _isBufferingNotifier,
            builder: (context, isBuffering, _) {
              if (!isBuffering) return const SizedBox.shrink();
              return ValueListenableBuilder<_VideoState>(
                valueListenable: _videoStateNotifier,
                builder: (_, state, __) {
                  if (state.hasError) return const SizedBox.shrink();
                  if (!_isControllerSafe) return const SizedBox.shrink();
                  return const Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(child: _BufferingDots()),
                  );
                },
              );
            },
          ),

          // CAPA 4: PROGRESS BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, progress, _) {
                if (progress <= 0.0) return const SizedBox.shrink();
                return _VideoProgressBar(progress: progress);
              },
            ),
          ),

          // CAPA 5: ERROR CON RETRY LIMITADO
          ValueListenableBuilder<_VideoState>(
            valueListenable: _videoStateNotifier,
            builder: (context, state, _) {
              if (!state.hasError) return const SizedBox.shrink();
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white54, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _retryCount >= _maxRetries
                          ? 'Error de carga'
                          : 'No se pudo cargar',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (_retryCount < _maxRetries)
                      TextButton(
                        onPressed: _initController,
                        child: const Text(
                          'Reintentar',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      )
                    else
                      const Text(
                        'Verificá tu conexión',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// CONSTANTES EXTRAÍDAS
// ===================================================================
class _Constants {
  static const thumbnailFadeDelay = Duration(milliseconds: 300);
  static const retryDelay = Duration(milliseconds: 500);
}

// ===================================================================
// WIDGETS AUXILIARES (SIN CAMBIOS CRÍTICOS)
// ===================================================================
class _VideoProgressBar extends StatelessWidget {
  final double progress;
  const _VideoProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2.0,
      child: Stack(
        children: [
          Container(color: Colors.white.withOpacity(0.25)),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailLayer extends StatelessWidget {
  final String thumbnailUrl;
  const _ThumbnailLayer({required this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl.isEmpty) {
      return Container(color: Colors.grey[900]);
    }
    return CachedNetworkImage(
      imageUrl: thumbnailUrl,
      fit: BoxFit.cover,
      memCacheWidth: 540,
      memCacheHeight: 960,
      fadeInDuration: Duration.zero,
      placeholder: (_, __) => Container(color: Colors.grey[900]),
      errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
    );
  }
}

class _BufferingDots extends StatefulWidget {
  const _BufferingDots({Key? key}) : super(key: key);

  @override
  State<_BufferingDots> createState() => _BufferingDotsState();
}

class _BufferingDotsState extends State<_BufferingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final progress = (_controller.value - delay) % 1.0;
            final opacity = progress < 0.5
                ? progress * 2
                : (1.0 - progress) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Opacity(
                opacity: opacity.clamp(0.2, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}