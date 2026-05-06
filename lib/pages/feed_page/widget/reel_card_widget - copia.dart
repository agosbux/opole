// lib/pages/feed_page/widget/reel_card_widget.dart
// ===================================================================
// REEL CARD WIDGET v3.9 - FIX: RELEASE VIDEO REFERENCES + HEART POOL CLEANUP
// ===================================================================
// CAMBIOS vs v3.8:
//   ✅ Llamada a _pool.release(videoUrl) en dispose() y didUpdateWidget()
//   ✅ Limpieza de _activeHearts antes de disponer _heartPoolController
//   ✅ Prevención de memory leaks por conteo de referencias en VideoControllerPool
//   ✅ _HeartAnimationData movida fuera de la clase State
//   ✅ Fix: referencia a heartData dentro de onComplete
//   ✅ Fix: usar TickerProviderStateMixin en lugar de SingleTickerProviderStateMixin
// ===================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:opole/core/feed/feed_item_model.dart';
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/pages/feed_page/widget/video_player_widget.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:opole/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:opole/core/video/video_controller_pool.dart';
import 'package:opole/core/navigation/video_route_observer.dart';
import 'package:opole/routes/app_routes.dart';

enum ReelViewType { feed, inmersive, single }

// ===================================================================
// REPORT REASONS
// ===================================================================
class ReportReason {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const ReportReason({
    required this.key,
    required this.label,
    required this.icon,
    this.color = Colors.white,
  });

  static const List<ReportReason> reasons = [
    ReportReason(key: 'Spam', label: 'Spam o contenido repetitivo', icon: Icons.report_gmailerrorred, color: Colors.orange),
    ReportReason(key: 'Contenido inapropiado', label: 'Contenido inapropiado', icon: Icons.visibility_off, color: Colors.red),
    ReportReason(key: 'Información falsa', label: 'Información falsa', icon: Icons.info_outline, color: Colors.amber),
    ReportReason(key: 'Estafa o fraude', label: 'Estafa o fraude', icon: Icons.money_off, color: Colors.redAccent),
    ReportReason(key: 'Violencia o contenido peligroso', label: 'Violencia o contenido peligroso', icon: Icons.warning, color: Colors.purple),
    ReportReason(key: 'Otro', label: 'Otro motivo', icon: Icons.help_outline, color: Colors.grey),
  ];

  static ReportReason fromKey(String key) {
    return reasons.firstWhere((r) => r.key == key, orElse: () => reasons.last);
  }
}

// ===================================================================
// REEL CARD WIDGET
// ===================================================================
class ReelCardWidget extends StatefulWidget {
  final FeedItem feedItem;
  final int index;
  final bool isBoosted;
  final ReelViewType viewType;
  final double screenHeight;
  final VoidCallback? onQuestions;
  final VoidCallback? onLoQuiero;
  final VoidCallback? onLike;
  final ValueChanged<String>? onHashtagSelected;
  final VoidCallback? onShare;
  final ValueChanged<int>? onWatchTimeUpdate;
  final VoidCallback? onVideoStart;
  final VoidCallback? onInteraction;
  final VoidCallback? onComplete;
  final int questionsCount;

  ReelModel? get reel => feedItem is ReelFeedItem ? (feedItem as ReelFeedItem).reel : null;

  const ReelCardWidget({
    super.key,
    required this.feedItem,
    required this.index,
    this.isBoosted = false,
    required this.viewType,
    required this.screenHeight,
    this.onQuestions,
    this.onLoQuiero,
    this.onLike,
    this.onHashtagSelected,
    this.onShare,
    this.onWatchTimeUpdate,
    this.onVideoStart,
    this.onInteraction,
    this.onComplete,
    this.questionsCount = 0,
  });

  @override
  State<ReelCardWidget> createState() => _ReelCardWidgetState();
}

class _ReelCardWidgetState extends State<ReelCardWidget>
    with TickerProviderStateMixin, RouteAware {   // ✅ Corregido: permite múltiples AnimationControllers

  late final FeedController _feedController;
  late final VideoControllerPool _pool;

  // Control de reproducción
  String? _lastVideoUrl;
  bool _wasPlaying = false;
  bool _videoStarted = false;

  // UI auxiliar
  late final AnimationController _heartController;
  late final Animation<double> _heartScale, _heartOpacity;
  late List<TextSpan> _descriptionSpans;
  bool _showHeart = false;
  bool _isReporting = false;
  bool _wasReported = false;
  String? _lastDescription;
  Timer? _hashtagDebounce;

  final ValueNotifier<bool> _showPauseIconNotifier = ValueNotifier<bool>(false);
  Timer? _pauseIconTimer;

  // Workers
  late final Worker _currentIndexWorker;
  late final Worker _isPausedWorker;

  // Timers
  Timer? _playbackDebounce;
  bool _isDoubleTapPending = false;
  Timer? _doubleTapWindow;
  bool _isNavigating = false;

  // ===================================================================
  // INSTAGRAM HEART POOL (posición dinámica + performance)
  // ===================================================================
  final List<_HeartAnimationData> _activeHearts = [];
  static const int _maxConcurrentHearts = 3;
  
  late final AnimationController _heartPoolController;
  late final Animation<double> _heartPoolScale;
  late final Animation<double> _heartPoolOpacity;
  late final Animation<double> _heartPoolRotation;
  
  final ValueNotifier<Offset?> _lastTapPosition = ValueNotifier<Offset?>(null);

  @override
  void initState() {
    super.initState();
    _feedController = Get.find<FeedController>();
    _pool = VideoControllerPool.instance;

    _setupHeartAnimation();
    _setupHeartPool();
    _cacheDescriptionSpans();

    _currentIndexWorker = ever<int>(_feedController.currentVisibleIndex, (_) {
      _updatePlaybackForCurrentIndex();
    });

    _isPausedWorker = ever<bool>(_feedController.isUserPaused, (_) {
      _updatePlaybackForCurrentIndex();
    });

    _isNavigating = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updatePlaybackForCurrentIndex();
    });
  }

  void _setupHeartPool() {
    _heartPoolController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _heartPoolScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _heartPoolController,
      curve: Curves.easeOutBack,
    ));
    
    _heartPoolOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_heartPoolController);
    
    _heartPoolRotation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _heartPoolController, curve: Curves.easeInOut),
    );
  }

  void _setupHeartAnimation() {
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _heartScale = Tween<double>(begin: 0.0, end: 1.3).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOutBack),
    );
    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(_heartController);

    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showHeart = false);
        _heartController.reset();
      }
    });
  }

  void _cacheDescriptionSpans() {
    if (!mounted) return;
    final desc = widget.reel?.description;
    if (desc == null || desc.isEmpty) { _descriptionSpans = const []; return; }
    if (desc == _lastDescription) return;
    _lastDescription = desc;
    final spans = <TextSpan>[];
    final parts = desc.split(' ');
    for (int i = 0; i < parts.length; i++) {
      final word = parts[i];
      final isTag = word.startsWith('#') || word.startsWith('@');
      spans.add(TextSpan(
        text: '$word${i < parts.length - 1 ? ' ' : ''}',
        style: TextStyle(
          color: isTag ? Colors.lightBlueAccent : Colors.white,
          fontSize: 13,
          fontWeight: isTag ? FontWeight.w600 : FontWeight.normal,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1))],
        ),
      ));
    }
    _descriptionSpans = spans;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      VideoRouteObserver.instance.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    final videoUrl = _getVideoUrl();
    if (videoUrl != null && _wasPlaying) {
      VideoRouteObserver.onRouteAbove();
    }
  }

  @override
  void didPopNext() {
    VideoRouteObserver.onRouteReturned();
  }

  @override
  void didPush() {}

  @override
  void didPop() {
    if (!mounted) return;
    final videoUrl = _getVideoUrl();
    if (videoUrl != null) {
      unawaited(_pool.pause(videoUrl));
    }
  }

  @override
  void didUpdateWidget(ReelCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final newVideoUrl = widget.reel?.videoUrl;
    final oldVideoUrl = oldWidget.reel?.videoUrl;
    
    // ✅ Liberar referencia del video antiguo cuando cambia la URL
    if (newVideoUrl != oldVideoUrl) {
      if (oldVideoUrl != null) {
        _pool.release(oldVideoUrl);
      }
      _videoStarted = false;
    }
    
    if (widget.reel?.description != oldWidget.reel?.description) {
      _cacheDescriptionSpans();
    }
    if (widget.reel?.isLiked != oldWidget.reel?.isLiked ||
        widget.reel?.likesCount != oldWidget.reel?.likesCount) {
      setState(() {});
    }
    if (widget.index != oldWidget.index) {
      _updatePlaybackForCurrentIndex();
    }
  }

  // ===================================================================
  // PLAYBACK OPTIMIZADO
  // ===================================================================
  void _updatePlaybackForCurrentIndex() {
    final videoUrl = _getVideoUrl();
    if (videoUrl == null) return;

    _playbackDebounce?.cancel();
    _playbackDebounce = Timer(const Duration(milliseconds: 16), () {
      if (!mounted) return;

      final int currentIndex = _feedController.currentVisibleIndex.value;
      final bool isPaused = _feedController.isUserPaused.value;
      
      final bool inActiveWindow = (widget.index - currentIndex).abs() <= 2;
      final bool shouldPlay = inActiveWindow && !isPaused;

      if (_lastVideoUrl == videoUrl && _wasPlaying == shouldPlay) return;
      _lastVideoUrl = videoUrl;
      _wasPlaying = shouldPlay;

      if (shouldPlay) {
        _pool.play(videoUrl);
      } else {
        _pool.pause(videoUrl);
      }
    });
  }

  String? _getVideoUrl() {
    if (widget.feedItem is ReelFeedItem) {
      return (widget.feedItem as ReelFeedItem).reel.videoUrl;
    }
    return null;
  }

  // ===================================================================
  // DOUBLE TAP (LIKE) - POSICIÓN DINÁMICA
  // ===================================================================
  void _triggerHeartAnimation({Offset? tapPosition}) {
    if (widget.feedItem is! ReelFeedItem) return;

    _doubleTapWindow?.cancel();
    _isDoubleTapPending = false;

    widget.onLike?.call();

    if (!mounted) return;
    HapticFeedback.lightImpact();

    final position = tapPosition ?? _getCenterOffset();
    _spawnHeartAtPosition(position);
  }

  Offset _getCenterOffset() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    return Offset(size.width / 2, size.height / 2);
  }

  void _spawnHeartAtPosition(Offset position) {
    _activeHearts.removeWhere((h) => h.completed);
    
    if (_activeHearts.length >= _maxConcurrentHearts) {
      final oldest = _activeHearts.removeAt(0);
      oldest.onComplete();
    }
    
    // ✅ Usar late para poder referenciar heartData dentro del onComplete
    late final _HeartAnimationData heartData;
    heartData = _HeartAnimationData(
      position: position,
      onComplete: () {
        if (mounted) {
          setState(() {
            _activeHearts.removeWhere((h) => h == heartData);
          });
        }
      },
    );
    
    setState(() => _activeHearts.add(heartData));
    
    _heartPoolController.reset();
    _heartPoolController.forward();
  }

  Widget _buildPositionedHeart(_HeartAnimationData heart) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _heartPoolController,
        builder: (context, child) {
          final scale = _heartPoolScale.value;
          final opacity = _heartPoolOpacity.value;
          final rotation = _heartPoolRotation.value;
          
          return Positioned(
            left: heart.position.dx - 40,
            top: heart.position.dy - 40,
            child: Transform.rotate(
              angle: rotation * (heart.position.dx > 200 ? 1 : -1),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 56,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================================================================
  // SINGLE TAP
  // ===================================================================
  void _handleTap() {
    if (_isDoubleTapPending) return;

    _isDoubleTapPending = true;
    _doubleTapWindow?.cancel();
    _doubleTapWindow = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || _isNavigating) return;

      _isNavigating = true;
      _isDoubleTapPending = false;

      widget.onInteraction?.call();

      if (widget.viewType == ReelViewType.inmersive) {
        _showPauseAnimation();
        _isNavigating = false;
      }

      if (widget.viewType == ReelViewType.feed) {
        final reelId = widget.reel?.id;
        if (reelId != null) {
          Get.toNamed(AppRoutes.reelsInmersivePage, arguments: {
            'startReelId': reelId,
            'startIndex': widget.index,
          })?.then((_) {
            if (mounted) _isNavigating = false;
          }).catchError((_) {
            if (mounted) _isNavigating = false;
          });
        } else {
          _isNavigating = false;
        }
      } else {
        _isNavigating = false;
      }
    });
  }

  void _handleHashtagTap(String tag) {
    _hashtagDebounce?.cancel();
    _hashtagDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) widget.onHashtagSelected?.call(tag);
    });
  }

  List<String> get _parsedHashtags => widget.reel?.hashtags ?? [];

  void _showPauseAnimation() {
    _showPauseIconNotifier.value = true;
    _pauseIconTimer?.cancel();
    _pauseIconTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _showPauseIconNotifier.value = false;
    });
  }

  Widget _buildPausePlayIndicator() {
    final isPaused = _feedController.isUserPaused.value;
    final iconData = isPaused ? Icons.play_arrow : Icons.pause;
    return Center(
      child: ValueListenableBuilder<bool>(
        valueListenable: _showPauseIconNotifier,
        builder: (context, show, child) {
          return AnimatedOpacity(
            opacity: show ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: Colors.white, size: 48),
            ),
          );
        },
      ),
    );
  }

  // ===================================================================
  // REPORTE Y LO QUIERO
  // ===================================================================
  void _showReportDialog(String reelId) {
    if (_isReporting) return;
    Get.dialog(AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      title: const Text('Denunciar contenido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Seleccioná el motivo:', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 12),
          ...ReportReason.reasons.map((reason) => ListTile(
            dense: true, contentPadding: EdgeInsets.zero,
            leading: Icon(reason.icon, color: reason.color, size: 22),
            title: Text(reason.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () { Get.back(); _submitReport(reelId, reason.key, reason.label); },
          )),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Get.back(), child: Text('Cancelar', style: TextStyle(color: Colors.grey[400]))),
        ]),
      ),
    ), barrierDismissible: true);
  }

  Future<void> _submitReport(String reelId, String motivo, String motivoLabel) async {
    if (_isReporting || _wasReported) return;

    setState(() => _isReporting = true);

    try {
      await _feedController.reportReel(reelId, motivo, detalles: 'Reportado desde ReelCardWidget - $motivoLabel');
      if (mounted && !_wasReported) {
        setState(() => _wasReported = true);
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error al reportar reel: $e');
    } finally {
      if (mounted) {
        setState(() => _isReporting = false);
      }
    }
  }

  Future<void> _showLoQuieroConfirmation() async {
    final confirm = await Get.dialog<bool>(AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      title: const Text('Confirmar interés', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      content: const Text('Estás a punto de demostrar un interés real. Tené en cuenta que la otra persona deberá seleccionarte, y lo hará (o no) en base a tu perfil público.', style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: Text('Cancelar', style: TextStyle(color: Colors.grey[400]))),
        ElevatedButton(onPressed: () => Get.back(result: true), style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent), child: const Text('Confirmar', style: TextStyle(color: Colors.black))),
      ],
    ), barrierDismissible: true);

    if (confirm == true && mounted) {
      if (widget.onLoQuiero != null) {
        try {
          widget.onLoQuiero!();
        } catch (e) {
          if (kDebugMode) debugPrint('Lo quiero failed: $e');
        }
      }
      if (mounted) {
        await Get.dialog(AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          title: const Text('¡Gracias por confirmar!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          content: const Text('Te recomendamos siempre subir tu Nivel de usuario para ser seleccionado más rápido.', style: TextStyle(color: Colors.white70)),
          actions: [TextButton(onPressed: () => Get.back(), child: const Text('Entendido', style: TextStyle(color: Colors.greenAccent)))],
        ), barrierDismissible: true);
      }
    }
  }

  // ===================================================================
  // BUILD PRINCIPAL
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    if (widget.feedItem is AdFeedItem) return _buildAdCard(widget.feedItem as AdFeedItem);
    final reel = widget.reel;
    if (reel == null) return const SizedBox.shrink();
    if (_wasReported) {
      return const AnimatedOpacity(
        duration: Duration(milliseconds: 200),
        opacity: 0.3,
        child: Center(child: Icon(Icons.flag, color: Colors.grey, size: 40)),
      );
    }

    final videoUrl = _getVideoUrl();

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        if (!_videoStarted && reel.thumbnailUrl != null && reel.thumbnailUrl!.isNotEmpty)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: reel.thumbnailUrl!,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              placeholder: (_, __) => Container(color: Colors.black),
              errorWidget: (_, __, ___) => Container(color: Colors.black),
            ),
          ),

        if (videoUrl != null)
          VideoPlayerWidget(
            url: videoUrl,
            onVideoStart: () {
              if (mounted) setState(() => _videoStarted = true);
              widget.onVideoStart?.call();
            },
            onWatchTimeUpdate: widget.onWatchTimeUpdate,
            onComplete: widget.onComplete,
          )
        else
          Container(color: Colors.grey[900]),

        _buildPausePlayIndicator(),

        ..._activeHearts.map(_buildPositionedHeart),

        _GestureLayer(
          onDoubleTap: _triggerHeartAnimation,
          onTap: _handleTap,
          onTapDown: (details) {
            _lastTapPosition.value = details.localPosition;
          },
        ),

        _OverlayLayer(
          reel: reel,
          screenHeight: widget.screenHeight,
          onLoQuiero: _showLoQuieroConfirmation,
          onLike: () => _triggerHeartAnimation(),
          onShare: widget.onShare,
          onQuestions: widget.onQuestions,
          onHashtagTap: _handleHashtagTap,
          descriptionSpans: _descriptionSpans,
          hashtags: _parsedHashtags,
          questionsCount: widget.questionsCount,
          viewType: widget.viewType,
          onExpandDescription: () => _showDescriptionModal(context),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: _ReportMenuButton(
            onReport: () => _showReportDialog(reel.id),
            isReporting: _isReporting,
          ),
        ),
      ],
    );
  }

  void _showDescriptionModal(BuildContext context) {
    final reel = widget.reel;
    if (reel == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  reel.description ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                ),
                if (_parsedHashtags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _parsedHashtags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdCard(AdFeedItem adItem) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ads_click, color: Colors.grey[600], size: 40),
            const SizedBox(height: 8),
            Text('Anuncio patrocinado', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            if (adItem.isBoosted) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                ),
                child: const Text('Boosted', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // DISPOSE CON RELEASE DE VIDEO Y LIMPIEZA DE CORAZONES
  // ===================================================================
  @override
  void dispose() {
    // 1. Liberar referencia del video en el pool (evita memory leaks)
    final videoUrl = _getVideoUrl();
    if (videoUrl != null) {
      _pool.release(videoUrl);
    }

    // 2. Limpiar corazones activos antes de disponer el controller
    _activeHearts.clear();
    
    // 3. Detener y disponer el controller del pool de corazones
    _heartPoolController.stop();
    _heartPoolController.dispose();
    
    // 4. Disponer el notifier de posición
    _lastTapPosition.dispose();
    
    VideoRouteObserver.instance.unsubscribe(this);
    _currentIndexWorker.dispose();
    _isPausedWorker.dispose();
    _heartController.dispose();
    _hashtagDebounce?.cancel();
    _pauseIconTimer?.cancel();
    _showPauseIconNotifier.dispose();
    _playbackDebounce?.cancel();
    _doubleTapWindow?.cancel();
    
    super.dispose();
  }
}

// ===================================================================
// DATOS DE ANIMACIÓN DE CORAZÓN (fuera de la clase State)
// ===================================================================
class _HeartAnimationData {
  final Offset position;
  final VoidCallback onComplete;
  bool completed = false;
  
  _HeartAnimationData({
    required this.position,
    required this.onComplete,
  });
}

// ===================================================================
// BOTÓN DE MENÚ (REPORTE)
// ===================================================================
class _ReportMenuButton extends StatelessWidget {
  final VoidCallback onReport;
  final bool isReporting;

  const _ReportMenuButton({required this.onReport, required this.isReporting});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: isReporting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.more_vert, color: Colors.white, size: 24),
      color: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      enabled: !isReporting,
      onSelected: (value) {
        if (value == 'report') onReport();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Denunciar', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================================================================
// CAPA DE GESTOS
// ===================================================================
class _GestureLayer extends StatelessWidget {
  final VoidCallback? onTap, onDoubleTap;
  final ValueChanged<TapDownDetails>? onTapDown;
  
  const _GestureLayer({
    this.onTap,
    this.onDoubleTap,
    this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onTapDown: onTapDown,
        child: const SizedBox.shrink(),
      ),
    );
  }
}

// ===================================================================
// OVERLAY LAYER
// ===================================================================
class _OverlayLayer extends StatelessWidget {
  final ReelModel reel;
  final double screenHeight;
  final VoidCallback? onLoQuiero, onLike, onShare, onQuestions;
  final Function(String)? onHashtagTap;
  final List<TextSpan> descriptionSpans;
  final List<String> hashtags;
  final int questionsCount;
  final ReelViewType viewType;
  final VoidCallback onExpandDescription;

  const _OverlayLayer({
    Key? key,
    required this.reel,
    required this.screenHeight,
    this.onLoQuiero,
    this.onLike,
    this.onShare,
    this.onQuestions,
    this.onHashtagTap,
    required this.descriptionSpans,
    this.hashtags = const [],
    this.questionsCount = 0,
    this.viewType = ReelViewType.feed,
    required this.onExpandDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black26,
              Colors.black54,
              Colors.black87,
            ],
            stops: [0.0, 0.4, 0.65, 0.82, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _LeftColumn(
                      reel: reel,
                      descriptionSpans: descriptionSpans,
                      onHashtagTap: onHashtagTap,
                      hashtags: hashtags,
                      onExpandDescription: onExpandDescription,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _RightColumn(
                    reel: reel,
                    onLoQuiero: onLoQuiero,
                    onLike: onLike,
                    onShare: onShare,
                    onQuestions: onQuestions,
                    questionsCount: questionsCount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// COLUMNA IZQUIERDA
// ===================================================================
class _LeftColumn extends StatelessWidget {
  final ReelModel reel;
  final List<TextSpan> descriptionSpans;
  final Function(String)? onHashtagTap;
  final List<String> hashtags;
  final VoidCallback onExpandDescription;

  const _LeftColumn({
    Key? key,
    required this.reel,
    required this.descriptionSpans,
    this.onHashtagTap,
    this.hashtags = const [],
    required this.onExpandDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProfileRow(context),
        _buildMarketplaceInfo(),
        const SizedBox(height: 4),
        if (reel.description?.isNotEmpty == true) _buildDescriptionBlock(),
        if (hashtags.isNotEmpty) ...[const SizedBox(height: 6), _buildHashtagsRow()],
      ],
    );
  }

  Widget _buildProfileRow(BuildContext context) {
    final feedCtrl = Get.find<FeedController>();
    final photo = reel.userPhotoUrl;
    return InkWell(
      onTap: () => feedCtrl.openUserProfile(reel.userId ?? ''),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
            child: ClipOval(
              child: photo?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: photo!,
                      fit: BoxFit.cover,
                      memCacheWidth: 96,
                      memCacheHeight: 96,
                      fadeInDuration: const Duration(milliseconds: 120),
                      placeholder: (_, __) => const _ProfilePlaceholder(),
                      errorWidget: (_, __, ___) => const _ProfilePlaceholder(),
                    )
                  : const Icon(Icons.person, color: Colors.white54, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reel.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                shadows: [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1))],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceInfo() {
    if (reel.title == null && reel.price == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reel.title != null)
            Text(reel.title!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (reel.price != null)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text('\$${reel.price}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          if (reel.condition != null)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(reel.condition!, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBlock() {
    return InkWell(
      onTap: onExpandDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(children: descriptionSpans),
          ),
          if ((reel.description?.length ?? 0) > 90)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'Ver más',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHashtagsRow() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: hashtags.take(3).map((tag) {
        return InkWell(
          onTap: () => onHashtagTap?.call(tag),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Text('#$tag', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        );
      }).toList(),
    );
  }
}

// ===================================================================
// COLUMNA DERECHA
// ===================================================================
class _RightColumn extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback? onLoQuiero, onLike, onShare, onQuestions;
  final int questionsCount;

  const _RightColumn({
    Key? key,
    required this.reel,
    this.onLoQuiero,
    this.onLike,
    this.onShare,
    this.onQuestions,
    this.questionsCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OptimisticLikeButton(isLiked: reel.isLiked == true, likesCount: reel.likesCount ?? 0, onTap: onLike),
                const SizedBox(height: 12),
                _SideActionButton(
                  icon: Icons.shopping_bag_outlined,
                  label: "Lo quiero",
                  isCounter: false,
                  isConfirmed: reel.isLoQuiero == true,
                  onTap: onLoQuiero,
                ),
                const SizedBox(height: 12),
                _SideActionButton(icon: Icons.question_answer_outlined, label: questionsCount > 0 ? "$questionsCount" : "Preguntar", isCounter: questionsCount > 0, onTap: onQuestions),
                const SizedBox(height: 12),
                _SideActionButton(icon: Icons.share_outlined, label: "Compartir", onTap: onShare),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ===================================================================
// BOTÓN DE LIKE OPTIMISTA
// ===================================================================
class _OptimisticLikeButton extends StatefulWidget {
  final bool isLiked;
  final int likesCount;
  final VoidCallback? onTap;
  const _OptimisticLikeButton({Key? key, required this.isLiked, required this.likesCount, this.onTap}) : super(key: key);
  @override
  State<_OptimisticLikeButton> createState() => _OptimisticLikeButtonState();
}

class _OptimisticLikeButtonState extends State<_OptimisticLikeButton> with SingleTickerProviderStateMixin {
  late bool _localLiked;
  late int _localCount;
  bool _isPending = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _localLiked = widget.isLiked;
    _localCount = widget.likesCount;
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.4), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.4, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_OptimisticLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked || widget.likesCount != oldWidget.likesCount) {
      setState(() {
        _localLiked = widget.isLiked;
        _localCount = widget.likesCount;
        _isPending = false;
      });
    }
  }

  Future<void> _handleTap() async {
    if (_isPending) return;

    _isPending = true;
    _pulseController.forward(from: 0.0);
    HapticFeedback.lightImpact();

    final newLiked = !_localLiked;
    setState(() {
      _localLiked = newLiked;
      _localCount = (_localCount + (newLiked ? 1 : -1)).clamp(0, 999999);
    });

    try {
      widget.onTap?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _localLiked = widget.isLiked;
          _localCount = widget.likesCount;
        });
        if (kDebugMode) debugPrint('Like failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isPending = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseScale.value,
          child: _SideActionButton(
            icon: _localLiked ? Icons.favorite : Icons.favorite_border,
            customIcon: Icon(_localLiked ? Icons.favorite : Icons.favorite_border, color: _localLiked ? Colors.greenAccent : Colors.white, size: 24),
            label: _localCount.toString(),
            isCounter: true,
            onTap: _handleTap,
          ),
        );
      },
    );
  }
}

// ===================================================================
// BOTÓN DE ACCIÓN LATERAL
// ===================================================================
class _SideActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isCounter;
  final bool isConfirmed;
  final Widget? customIcon;

  const _SideActionButton({Key? key, required this.icon, required this.label, this.onTap, this.isCounter = false, this.isConfirmed = false, this.customIcon}) : super(key: key);

  @override
  State<_SideActionButton> createState() => _SideActionButtonState();
}

class _SideActionButtonState extends State<_SideActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _confirmController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confirmController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _confirmController, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(_SideActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConfirmed && !oldWidget.isConfirmed) {
      _confirmController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _confirmController.reverse();
        });
      });
    }
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Semantics(
        label: '${widget.label}${widget.isCounter ? ' veces' : ''}. Botón de acción.',
        button: true,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.isConfirmed ? Colors.greenAccent.withOpacity(0.3) : Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: widget.customIcon ?? Icon(widget.isConfirmed ? Icons.check : widget.icon, color: widget.isConfirmed ? Colors.greenAccent : Colors.white, size: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: widget.isConfirmed ? Colors.greenAccent : Colors.white, fontSize: widget.isCounter ? 12 : 10, fontWeight: widget.isCounter ? FontWeight.w600 : FontWeight.normal),
                      ),
                    ],
                  ),
                  if (widget.isConfirmed)
                    const Positioned.fill(child: Center(child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 28))),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===================================================================
// PLACEHOLDER DE AVATAR
// ===================================================================
class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.person, color: Colors.white38, size: 18),
      ),
    );
  }
}