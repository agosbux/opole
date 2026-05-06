// lib/pages/feed_page/widget/reel_card_widget.dart
// ===================================================================
// REEL CARD WIDGET v10.7.1 – FIX: _SideButton.onTap NULLABLE
// ===================================================================
// ✅ Fix compilación: VoidCallback? en _SideButton
// ✅ Mantiene: Lo Quiero robusto, botón reactivo, like centralizado
// ===================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:opole/core/video/video_controller_pool.dart';
import 'package:opole/core/feed/feed_item_model.dart';
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/pages/feed_page/widget/video_player_widget.dart';
import 'package:opole/pages/feed_page/widget/image_reel_widget.dart';
import 'package:opole/core/ui/heart_animation_layer.dart' as core_ui;
import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:opole/routes/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:opole/core/feed/feed_interaction_bridge.dart';

enum ReelViewType { feed, inmersive, single }

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

  static ReportReason fromKey(String key) => reasons.firstWhere(
    (r) => r.key == key,
    orElse: () => reasons.last,
  );
}

class _Styles {
  static const usernameStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]);
  static const conditionStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, shadows: [Shadow(color: Colors.black54, blurRadius: 2)]);
  static const priceStyle = TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]);
  static const verMasStyle = TextStyle(color: Colors.white, fontSize: 12);
  static const sideButtonLabelStyle = TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]);
  static const dialogTitleStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
  static const dialogContentStyle = TextStyle(color: Colors.white70);
  static const motivoLabelStyle = TextStyle(color: Colors.white, fontSize: 14);
  static const cancelButtonStyle = TextStyle(color: Colors.grey);
  static const hashtagStyle = TextStyle(color: Colors.blueAccent, fontSize: 12);
  static final conditionDecoration = BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(4));
  static final verMasDecoration = BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16));
  static final sideButtonDecoration = BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle);
  static final reportButtonDecoration = BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle);
  static final avatarDecoration = BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5));
}

class _Constants {
  static const likeTapCooldown = Duration(milliseconds: 300);
  static const consecutiveTapWindow = Duration(milliseconds: 800);
}

class ReelCardWidget extends StatefulWidget {
  final FeedItem feedItem;
  final int index;
  final ReelViewType viewType;
  final double screenHeight;
  final bool isBoosted;
  final VoidCallback? onQuestions;
  final VoidCallback? onLoQuiero;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final void Function(String hashtag)? onHashtagSelected;
  final VoidCallback? onInteraction;
  final Function(int milliseconds)? onWatchTimeUpdate;
  final VoidCallback? onComplete;
  final VoidCallback? onVideoStart;
  final int questionsCount;

  ReelModel? get reel => feedItem is ReelFeedItem ? (feedItem as ReelFeedItem).reel : null;

  const ReelCardWidget({
    super.key,
    required this.feedItem,
    required this.index,
    required this.viewType,
    required this.screenHeight,
    this.isBoosted = false,
    this.onQuestions,
    this.onLoQuiero,
    this.onLike,
    this.onShare,
    this.onHashtagSelected,
    this.onInteraction,
    this.onWatchTimeUpdate,
    this.onComplete,
    this.onVideoStart,
    this.questionsCount = 0,
  });

  @override
  State<ReelCardWidget> createState() => _ReelCardWidgetState();
}

class _ReelCardWidgetState extends State<ReelCardWidget> with TickerProviderStateMixin {
  late final FeedController _feedController;
  late IInteractionBridge _interactionController;

  final GlobalKey<core_ui.HeartAnimationLayerState> _heartLayerKey = GlobalKey();

  DateTime? _lastLikeTap;
  int _consecutiveTaps = 0;
  DateTime? _consecutiveTapWindowStart;

  bool _isReporting = false;
  bool _wasReported = false;
  bool _disposed = false;
  bool _isMuted = false;
  Size? _widgetSize;

  ReelModel? get _currentReel {
    final reel = widget.reel;
    if (reel == null) return null;
    
    final cached = _feedController.getReelById(reel.id);
    if (cached != null) return cached;
    
    for (final item in _feedController.feedItems) {
      if (item is ReelFeedItem && item.reel.id == reel.id) {
        return item.reel;
      }
    }
    
    return reel;
  }

  @override
  void initState() {
    super.initState();
    _feedController = Get.find<FeedController>();
    _interactionController = _feedController.interactionController;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && mounted) {
        final renderBox = context.findRenderObject() as RenderBox?;
        _widgetSize = renderBox?.hasSize == true ? renderBox!.size : null;
      }
    });
  }

  @override
  void didUpdateWidget(covariant ReelCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reel?.id != oldWidget.reel?.id) {
      _consecutiveTaps = 0;
      _consecutiveTapWindowStart = null;
      _lastLikeTap = null;
      _isReporting = false;
      _wasReported = false;
      _widgetSize = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && mounted) {
          final renderBox = context.findRenderObject() as RenderBox?;
          _widgetSize = renderBox?.hasSize == true ? renderBox!.size : null;
          widget.onVideoStart?.call();
        }
      });
    }
  }

  String? _getVideoUrl() => widget.reel?.videoUrl;

  Offset _getCenterOffset() {
    final size = _widgetSize;
    return size != null ? Offset(size.width / 2, size.height / 2) : const Offset(200, 400);
  }

  void _spawnHeart(Offset position, {core_ui.HeartIntensity intensity = core_ui.HeartIntensity.normal}) {
    if (_disposed) return;
    _heartLayerKey.currentState?.spawnHeart(position, intensity: intensity);
  }

  void _spawnHeartIfVideo(Offset position, {core_ui.HeartIntensity intensity = core_ui.HeartIntensity.normal}) {
    if (_disposed) return;
    final reel = widget.reel;
    if (reel == null) return;
    
    final hasVideo = reel.videoUrl != null && reel.videoUrl!.isNotEmpty;
    final hasImages = reel.imageUrls != null && reel.imageUrls!.isNotEmpty;
    
    if (hasVideo && !hasImages) {
      _heartLayerKey.currentState?.spawnHeart(position, intensity: intensity);
    }
  }

  void _executeLikeAction(String reelId) {
    if (_disposed) return;
    
    final currentReel = _currentReel;
    if (currentReel == null) return;

    final alreadyLiked = currentReel.isLiked ?? false;
    final currentCount = currentReel.likesCount ?? 0;
    
    _feedController.updateReelInteraction(
      reelId: reelId,
      isLiked: !alreadyLiked,
      likesCount: alreadyLiked ? currentCount - 1 : currentCount + 1,
    );

    _feedController.toggleLike(reelId);
  }

  void _triggerLike({Offset? tapPosition}) {
    if (_disposed) return;
    final reel = widget.reel;
    if (reel == null) return;

    final now = DateTime.now();
    if (_consecutiveTapWindowStart == null ||
        now.difference(_consecutiveTapWindowStart!) > _Constants.consecutiveTapWindow) {
      _consecutiveTaps = 1;
      _consecutiveTapWindowStart = now;
    } else {
      _consecutiveTaps++;
    }

    final isWithinDebounce = _lastLikeTap != null &&
        now.difference(_lastLikeTap!) < _Constants.likeTapCooldown;

    if (isWithinDebounce) {
      if (_consecutiveTaps >= 3) {
        _spawnHeartIfVideo(
          tapPosition ?? _getCenterOffset(),
          intensity: core_ui.HeartIntensity.frantic,
        );
        HapticFeedback.mediumImpact();
      }
      return;
    }

    _lastLikeTap = now;
    HapticFeedback.lightImpact();

    _executeLikeAction(reel.id);

    final currentReel = _currentReel;
    final wasAlreadyLiked = currentReel?.isLiked ?? true;
    if (!wasAlreadyLiked) {
      _spawnHeartIfVideo(
        tapPosition ?? _getCenterOffset(),
        intensity: _consecutiveTaps >= 3 ? core_ui.HeartIntensity.frantic : core_ui.HeartIntensity.normal,
      );
    }
    
    widget.onLike?.call();
  }

  void _toggleLikeFromButton() {
    if (_disposed) return;
    final reel = widget.reel;
    if (reel?.id == null) return;

    HapticFeedback.lightImpact();

    _executeLikeAction(reel!.id);

    final currentReel = _currentReel;
    final willLike = !(currentReel?.isLiked ?? false);
    if (willLike) {
      _spawnHeartIfVideo(_getCenterOffset());
    }
  }

  void _navigateToInmersive() {
    if (_disposed || !mounted || widget.viewType != ReelViewType.feed) return;
    final reel = widget.reel;
    if (reel?.id != null) {
      Get.toNamed(
        AppRoutes.reelsInmersivePage,
        arguments: {'startReelId': reel!.id, 'startIndex': widget.index},
      );
    }
  }

  void _toggleMute() {
    if (_disposed) return;
    setState(() => _isMuted = !_isMuted);
    final videoUrl = _getVideoUrl();
    if (videoUrl != null) {
      final controller = VideoControllerPool.instance.getSync(videoUrl);
      if (controller?.value.isInitialized == true) {
        controller!.setVolume(_isMuted ? 0.0 : 1.0);
      }
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _showLoQuieroConfirmation() async {
    if (_disposed || !mounted) return;
    final reel = widget.reel;
    if (reel?.id == null) return;

    try {
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          title: const Text('Confirmar interés', style: _Styles.dialogTitleStyle),
          content: const Text(
            'Estás a punto de demostrar un interés real. Tené en cuenta que la otra persona deberá seleccionarte, y lo hará (o no) en base a tu perfil público.',
            style: _Styles.dialogContentStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false), 
              child: const Text('Cancelar', style: _Styles.cancelButtonStyle),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              child: const Text('Confirmar', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 200),
      );

      if (!mounted || _disposed) return;

      if (confirm == true) {
        _feedController.updateReelInteraction(
          reelId: reel!.id,
          isLoQuiero: true,
        );
        
        await _interactionController.registerInterest(reel!.id);
        
        if (mounted && !_disposed) {
          Get.snackbar(
            '✅ Interés enviado',
            'Te notificaremos si hay novedades',
            backgroundColor: Colors.greenAccent.withOpacity(0.9),
            colorText: Colors.black,
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [LO_QUIERO] Error: $e');
      if (mounted && !_disposed) {
        Get.snackbar(
          '⚠️ Ups',
          'No se pudo registrar tu interés. Intentá de nuevo.',
          backgroundColor: Colors.orangeAccent.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  void _showReportDialog(String reelId) {
    if (_isReporting || _disposed) return;
    _isReporting = true;

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        title: const Text('Denunciar contenido', style: _Styles.dialogTitleStyle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seleccioná el motivo:', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              const SizedBox(height: 12),
              ...ReportReason.reasons.map((reason) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(reason.icon, color: reason.color, size: 22),
                title: Text(reason.label, style: _Styles.motivoLabelStyle),
                onTap: () {
                  Get.back();
                  _interactionController.reportReel(
                    reelId,
                    reason.key,
                    detalles: 'Reportado desde ReelCardWidget - ${reason.label}',
                  );
                },
              )),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Get.back(), child: const Text('Cancelar', style: _Styles.cancelButtonStyle)),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    ).whenComplete(() {
      if (mounted) _isReporting = false;
    });
  }

  void _showFullDescription() {
    final reel = widget.reel;
    if (reel == null || _disposed) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              if (reel.title?.isNotEmpty == true) ...[
                Text(reel.title!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
              ],
              Text(reel.description ?? '', style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    if (reel == null) return const SizedBox.shrink();
    if (_wasReported) {
      return Container(color: Colors.black, child: const Center(child: Icon(Icons.flag, color: Colors.grey, size: 40)));
    }

    final topPadding = MediaQuery.of(context).padding.top;

    final videoUrl = _getVideoUrl();
    final imageUrls = reel.imageUrls;
    final hasImages = imageUrls != null && imageUrls.isNotEmpty;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    final Widget mediaLayer = hasImages
        ? ImageReelWidget(
            images: imageUrls!,
            onDoubleTap: (pos) => _triggerLike(tapPosition: pos),
            onInteraction: () {
              widget.viewType == ReelViewType.feed
                  ? _navigateToInmersive()
                  : widget.onInteraction?.call();
            },
          )
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (_) {},
            onTap: () {
              widget.viewType == ReelViewType.feed
                  ? _navigateToInmersive()
                  : widget.onInteraction?.call();
            },
            onDoubleTapDown: (details) => _triggerLike(tapPosition: details.localPosition),
            child: hasVideo
                ? VideoPlayerWidget(
                    url: videoUrl!,
                    reelId: reel.id,
                    onVideoProgress: (p) => widget.onWatchTimeUpdate?.call(p.inMilliseconds),
                    onComplete: () => widget.onComplete?.call(),
                    onVideoStart: () => widget.onVideoStart?.call(),
                  )
                : Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 40),
                  ),
          );

    final Widget mediaWithHearts = hasImages 
        ? mediaLayer
        : core_ui.HeartAnimationLayer(key: _heartLayerKey, child: mediaLayer);

    return Stack(fit: StackFit.expand, children: [
      mediaWithHearts,
      
      Positioned(
        key: const ValueKey('bottom_info'),
        bottom: 20,
        left: 16,
        right: 90,
        child: _BottomInfo(
          reel: reel,
          onVerMas: _showFullDescription,
          onHashtagSelected: widget.onHashtagSelected,
        ),
      ),
      
      Positioned(
        key: const ValueKey('side_buttons'),
        right: 8,
        bottom: 100,
        child: Obx(() {
          final currentReel = _currentReel;
          if (currentReel == null) return const SizedBox.shrink();
          return _SideButtons(
            isLiked: currentReel.isLiked ?? false,
            likesCount: currentReel.likesCount ?? 0,
            isLoQuiero: currentReel.isLoQuiero ?? false,
            questionsCount: widget.questionsCount,
            isMuted: _isMuted,
            onLike: _toggleLikeFromButton,
            onLoQuiero: _showLoQuieroConfirmation,
            onQuestions: widget.onQuestions,
            onShare: widget.onShare,
            onMute: _toggleMute,
          );
        }),
      ),
      
      Positioned(
        key: const ValueKey('report_button'),
        top: topPadding + 8,
        right: 16,
        child: _ReportButton(
          onTap: () => _showReportDialog(reel.id),
          isReporting: _isReporting,
        ),
      ),
      
      if (widget.viewType == ReelViewType.inmersive)
        Positioned(
          key: const ValueKey('back_button'),
          top: topPadding + 8,
          left: 12,
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      
      if (reel.isBoosted)
        Positioned(
          key: const ValueKey('boost_badge'),
          top: topPadding + 8,
          left: widget.viewType == ReelViewType.inmersive ? 56 : 12,
          child: _BoostBadge(isPriority: reel.isPriorityBoosted),
        ),
    ]);
  }
}

// ===================================================================
// WIDGETS AUXILIARES
// ===================================================================

class _BoostBadge extends StatefulWidget {
  final bool isPriority;
  const _BoostBadge({required this.isPriority});

  @override
  State<_BoostBadge> createState() => _BoostBadgeState();
}

class _BoostBadgeState extends State<_BoostBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ScaleTransition(
      scale: _pulse,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isPriority ? Colors.amber.withOpacity(0.18) : Colors.greenAccent.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (widget.isPriority ? Colors.amber : Colors.greenAccent).withOpacity(0.7),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.isPriority ? Icons.rocket_launch_rounded : Icons.bolt_rounded,
              color: widget.isPriority ? Colors.amber : Colors.greenAccent,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              widget.isPriority ? 'TOP' : 'BOOST',
              style: TextStyle(
                color: widget.isPriority ? Colors.amber : Colors.greenAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BottomInfo extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onVerMas;
  final void Function(String hashtag)? onHashtagSelected;

  const _BottomInfo({required this.reel, required this.onVerMas, this.onHashtagSelected});

  String? _getBestAvatarUrl() => (reel.userPhotoUrl?.isNotEmpty ?? false) ? reel.userPhotoUrl : null;
  String _translateCondition(String c) => switch (c.toUpperCase()) { 'NEW' => 'NUEVO', 'USED' => 'USADO', _ => c };
  Color _getConditionColor(String c) => switch (c.toUpperCase()) { 'NEW' => Colors.lightGreenAccent, 'USED' => Colors.orangeAccent, _ => Colors.white70 };

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _getBestAvatarUrl();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: _Styles.avatarDecoration,
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: avatarUrl ?? '',
                fit: BoxFit.cover,
                memCacheWidth: 200,
                memCacheHeight: 200,
                useOldImageOnUrlChange: false,
                placeholder: (context, url) => const CircleAvatar(backgroundColor: Colors.grey),
                errorWidget: (context, url, error) => const CircleAvatar(backgroundColor: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reel.title?.isNotEmpty == true)
                    Text(
                      reel.title!,
                      style: _Styles.usernameStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (reel.condition?.isNotEmpty == true || reel.userUsername?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (reel.condition?.isNotEmpty == true) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: _Styles.conditionDecoration,
                            child: Text(
                              _translateCondition(reel.condition!),
                              style: _Styles.conditionStyle.copyWith(
                                color: _getConditionColor(reel.condition!),
                              ),
                            ),
                          ),
                        ],
                        if (reel.condition?.isNotEmpty == true && reel.userUsername?.isNotEmpty == true)
                          const SizedBox(width: 8),
                        if (reel.userUsername?.isNotEmpty == true)
                          Text(
                            'by @${reel.userUsername}',
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (reel.price != null) ...[
          const SizedBox(height: 4),
          Text('\$${reel.price}', style: _Styles.priceStyle),
        ],
        if (reel.hashtags?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: reel.hashtags!.map((tag) => GestureDetector(
              onTap: () => onHashtagSelected?.call(tag),
              child: Text('#$tag', style: _Styles.hashtagStyle),
            )).toList(),
          ),
        ],
        if ((reel.description?.isNotEmpty == true) || (reel.title?.isNotEmpty == true)) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onVerMas,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: _Styles.verMasDecoration,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ver más', style: _Styles.verMasStyle),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_up, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SideButtons extends StatelessWidget {
  final bool isLiked;
  final int likesCount;
  final bool isLoQuiero;
  final int questionsCount;
  final bool isMuted;
  final VoidCallback onLike;
  final VoidCallback onLoQuiero;
  final VoidCallback? onQuestions;
  final VoidCallback? onShare;
  final VoidCallback? onMute;

  const _SideButtons({
    required this.isLiked,
    required this.likesCount,
    required this.isLoQuiero,
    required this.questionsCount,
    required this.isMuted,
    required this.onLike,
    required this.onLoQuiero,
    this.onQuestions,
    this.onShare,
    this.onMute,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _SideButton(
        icon: isLiked ? Icons.favorite : Icons.favorite_border,
        label: likesCount > 0 ? likesCount.toString() : 'Like',
        color: isLiked ? Colors.greenAccent : Colors.white,
        onTap: onLike,
      ),
      const SizedBox(height: 20),
      
      _SideButton(
        icon: isLoQuiero ? Icons.check_circle : Icons.shopping_bag_outlined,
        label: isLoQuiero ? 'Enviado' : 'Lo quiero',
        color: isLoQuiero ? Colors.greenAccent : Colors.white,
        onTap: isLoQuiero ? null : onLoQuiero,
      ),
      
      const SizedBox(height: 20),
      _SideButton(
        icon: Icons.question_answer_outlined,
        label: questionsCount > 0 ? questionsCount.toString() : 'Preguntar',
        onTap: onQuestions ?? () {},
      ),
      const SizedBox(height: 20),
      _SideButton(icon: Icons.share_outlined, label: 'Compartir', onTap: onShare ?? () {}),
      const SizedBox(height: 20),
      _SideButton(
        icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        label: isMuted ? 'Sin audio' : 'Audio',
        color: isMuted ? Colors.white60 : Colors.white,
        onTap: onMute ?? () {},
      ),
    ],
  );
}

// 🔥 FIX: _SideButton con onTap nullable para permitir deshabilitar botones
class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;  // ✅ Nullable

  const _SideButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    this.onTap,  // ✅ Optional (sin required)
  });

  @override
  Widget build(BuildContext context) {
    final hasAction = onTap != null;
    return GestureDetector(
      onTap: hasAction
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,  // ✅ Si es null, GestureDetector ignora taps
      behavior: hasAction ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: _Styles.sideButtonDecoration,
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: _Styles.sideButtonLabelStyle.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isReporting;

  const _ReportButton({required this.onTap, this.isReporting = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: _Styles.reportButtonDecoration,
      child: isReporting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.more_vert, color: Colors.white, size: 24),
    ),
  );
}