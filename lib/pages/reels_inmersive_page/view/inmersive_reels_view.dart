// lib/pages/reels_inmersive_page/view/inmersive_reels_view.dart
// ===================================================================
// INMERSIVE REELS VIEW v4.1-fix - MEMORY SAFE + ARCHITECTURE ALIGNED
// ===================================================================
// ✅ FIX: assignId: true en GetBuilder para escuchar ['feed_state', 'feed_items']
// ✅ FIX: .whenComplete() para cleanup garantizado (consistente con feed_view.dart)
// ✅ FIX: Logs estratégicos en kDebugMode para diagnóstico de errores
// ✅ FIX: Validación de _isViewMounted + mounted en callbacks asíncronos
// ✅ Mantiene: PageController local, UI dumb, arquitectura desacoplada
// ===================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:opole/core/feed/feed_item_model.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:opole/pages/reel_questions/controller/reel_questions_controller.dart';
import 'package:opole/pages/reel_questions/view/reel_questions_sheet.dart';
import 'package:opole/pages/feed_page/widget/reel_card_widget.dart';
import 'package:opole/core/scroll/tiktok_scroll_physics.dart';

class InmersiveReelsView extends StatefulWidget {
  const InmersiveReelsView({super.key});

  @override
  State<InmersiveReelsView> createState() => _InmersiveReelsViewState();
}

class _InmersiveReelsViewState extends State<InmersiveReelsView> {
  late final FeedController feedController;
  int _currentIndex = 0;
  bool _isViewMounted = false;
  
  // ✅ PageController local para el modo inmersivo
  late final PageController _inmersivePageController;

  // ===================================================================
  // 🛡️ SAFE CALLBACK WRAPPER (CON LOGGING EN DEBUG)
  // ===================================================================
  void _safeAction(VoidCallback action) {
    if (_isViewMounted && mounted) {
      try {
        action();
      } catch (e, stack) {
        if (kDebugMode) {
          Get.log('❌ [INMERSIVE] SafeAction error: $e');
          Get.log('❌ [INMERSIVE] Stack: $stack');
        }
      }
    }
  }

  Future<void> _safeAsyncAction(Future<void> Function() action) async {
    if (!_isViewMounted || !mounted) {
      if (kDebugMode) Get.log('⚠️ [INMERSIVE] _safeAsyncAction ignorado: view no montada');
      return;
    }
    try {
      await action();
    } catch (e, stack) {
      if (kDebugMode) {
        Get.log('❌ [INMERSIVE] SafeAsyncAction error: $e');
        Get.log('❌ [INMERSIVE] Stack: $stack');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _isViewMounted = true;
    
    if (kDebugMode) Get.log('🚀 [INMERSIVE] initState() - View montada');

    // ✅ Inicialización segura del controller
    try {
      feedController = Get.find<FeedController>();
      if (kDebugMode) Get.log('✅ [INMERSIVE] FeedController encontrado');
    } catch (e) {
      if (kDebugMode) Get.log('❌ [INMERSIVE] Error buscando FeedController: $e');
      rethrow;
    }

    final int? startIndexArg = Get.arguments?['startIndex'];
    final int startIndex = startIndexArg ?? 0;
    _currentIndex = startIndex;
    _inmersivePageController = PageController(initialPage: startIndex);
    
    if (kDebugMode) Get.log('📄 [INMERSIVE] PageController creado - startIndex: $startIndex');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isViewMounted || !mounted) {
        if (kDebugMode) Get.log('⚠️ [INMERSIVE] PostFrameCallback ignorado: view no montada');
        return;
      }
      if (kDebugMode) Get.log('🔄 [INMERSIVE] Notificando onPageChanged($startIndex)');
      feedController.onPageChanged(startIndex);
    });
  }

  @override
  void dispose() {
    if (kDebugMode) Get.log('🧹 [INMERSIVE] dispose() - Limpiando recursos');
    _isViewMounted = false;
    
    try {
      _inmersivePageController.dispose();
      if (kDebugMode) Get.log('✅ [INMERSIVE] PageController disposed');
    } catch (e) {
      if (kDebugMode) Get.log('⚠️ [INMERSIVE] Error disposing PageController: $e');
    }
    
    // ✅ Pause asíncrono sin bloquear dispose
    unawaited(() async {
      try {
        await feedController.pauseAllVideos();
        if (kDebugMode) Get.log('⏸️ [INMERSIVE] Videos pausados');
      } catch (e) {
        if (kDebugMode) Get.log('⚠️ [INMERSIVE] Error pausando videos: $e');
      }
    }());
    
    super.dispose();
    if (kDebugMode) Get.log('✅ [INMERSIVE] dispose() completado');
  }

  // ===================================================================
  // 🆕 PAGE CHANGED DELEGADO AL CONTROLLER
  // ===================================================================
  void _onPageChanged(int index) {
    if (!_isViewMounted || !mounted) {
      if (kDebugMode) Get.log('⚠️ [INMERSIVE] _onPageChanged ignorado: view no montada');
      return;
    }
    
    if (kDebugMode && index != _currentIndex) {
      Get.log('📄 [INMERSIVE] PageChanged: $_currentIndex → $index');
    }
    
    _currentIndex = index;
    feedController.onPageChanged(index);
  }

  void _handleTapToggle() {
    if (!_isViewMounted || !mounted) return;
    _safeAction(() {
      if (feedController.isUserPaused.value) {
        if (kDebugMode) Get.log('▶️ [INMERSIVE] Resuming video');
        feedController.resumeActiveVideo();
      } else {
        if (kDebugMode) Get.log('⏸️ [INMERSIVE] Pausing video');
        feedController.pauseAllVideos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            _buildReelsPageView(),
            _buildOverlays(),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // 🆕 PAGEVIEW CON GETBUILDER (DETERMINÍSTICO + MULTI-TAG)
  // ===================================================================
  Widget _buildReelsPageView() {
    return GetBuilder<FeedController>(
      id: 'feed_state',
      // 🔥 FIX: assignId: true permite escuchar múltiples tags ['feed_state', 'feed_items']
      assignId: true,
      builder: (FeedController controller) {
        if (kDebugMode) {
          final itemCount = controller.feedItems.length + (controller.hasMore.value ? 1 : 0);
          Get.log('🔍 [INMERSIVE] build: state=${controller.feedState.value} | items=${controller.feedItems.length} | itemCount=$itemCount');
        }

        final List<FeedItem> items = controller.feedItems;

        if (items.isEmpty && controller.isLoading.value) {
          return const SizedBox.shrink();
        }

        if (items.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final Size screenSize = MediaQuery.sizeOf(context);
        final double screenHeight = screenSize.height;

        return PageView.builder(
          controller: _inmersivePageController,
          scrollDirection: Axis.vertical,
          physics: const TikTokScrollPhysics(minFlingVelocity: 300.0),
          itemCount: items.length + (controller.hasMore.value ? 1 : 0),
          onPageChanged: _onPageChanged,
          itemBuilder: (BuildContext context, int index) {
            final List<FeedItem> feedItems = controller.feedItems;

            // ✅ Caso: índice de paginación (loading o fin de feed)
            if (index == feedItems.length) {
              if (controller.hasMore.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                );
              } else {
                return _buildEndOfFeedWidget(screenHeight);
              }
            }

            final FeedItem feedItem = feedItems[index];

            // ✅ Caso: Anuncio patrocinado
            if (feedItem is! ReelFeedItem) {
              if (feedItem is AdFeedItem) {
                return _buildImmersiveAdPlaceholder(feedItem);
              }
              return const SizedBox.shrink();
            }

            // ✅ Caso: Reel normal con delegación arquitectónica
            return ReelCardWidget(
              key: ValueKey<String>('inmersive_${feedItem.reel.id}'),
              feedItem: feedItem,
              index: index,
              isBoosted: feedItem.isBoosted,
              viewType: ReelViewType.inmersive,
              screenHeight: screenHeight,

              // ✅ ARCHITECTURE: Delegación completa al InteractionController interno
              onQuestions: () => _safeAction(() => _showQuestionsSheet(feedItem)),
              onLoQuiero: null,
              onLike: null,
              onHashtagSelected: (String tag) => _safeAction(() => controller.onCategorySelected(tag)),
              onShare: null,
              onWatchTimeUpdate: null,
              onVideoStart: null,
              onInteraction: _handleTapToggle,
              onComplete: null,
              questionsCount: controller.getQuestionsCount(feedItem.reel.id),
            );
          },
        );
      },
    );
  }

  // ===================================================================
  // OVERLAYS CON GETBUILDER (ID CONSISTENTE + MULTI-TAG)
  // ===================================================================
  Widget _buildOverlays() {
    return GetBuilder<FeedController>(
      id: 'feed_state',
      // 🔥 FIX: assignId: true para consistencia con rebuild de items
      assignId: true,
      builder: (FeedController controller) {
        if (controller.feedItems.isEmpty && controller.isLoading.value) {
          return const _FeedSkeletonLoader();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEndOfFeedWidget(double screenHeight) {
    return Container(
      height: screenHeight,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, color: Colors.grey[600], size: 48),
            const SizedBox(height: 12),
            Text(
              'Llegaste al final',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Volvé más tarde para ver contenido nuevo',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _safeAction(() => feedController.refreshFeed()),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Actualizar feed'),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // ✅ FIX: Cleanup garantizado con .whenComplete() + logs (ALINEADO CON feed_view.dart)
  // ===================================================================
  void _showQuestionsSheet(FeedItem feedItem) {
    if (feedItem is! ReelFeedItem || !_isViewMounted || !mounted) {
      if (kDebugMode) Get.log('⚠️ [INMERSIVE] _showQuestionsSheet ignorado: view no montada o item inválido');
      return;
    }

    final String questionsTag = 'questions_${feedItem.reel.id}';
    
    if (!Get.isRegistered<ReelQuestionsController>(tag: questionsTag)) {
      Get.put<ReelQuestionsController>(ReelQuestionsController(), tag: questionsTag, permanent: false);
      if (kDebugMode) Get.log('📦 [INMERSIVE] ReelQuestionsController creado: $questionsTag');
    }
    final ReelQuestionsController questionsController = Get.find<ReelQuestionsController>(tag: questionsTag);

    questionsController.setReelOwnerId(feedItem.reel.userId);
    questionsController.loadQuestions(feedItem.reel.id);

    // 🔥 FIX: Get.bottomSheet retorna un Future que se completa al cerrar
    // Usamos ?.whenComplete() para cleanup garantizado (consistente con feed_view.dart)
    Get.bottomSheet(
      ReelQuestionsSheet(reelId: feedItem.reel.id),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    )?.whenComplete(() {
      if (kDebugMode) Get.log('🧹 [INMERSIVE] Questions sheet closed, limpiando: $questionsTag');
      if (Get.isRegistered<ReelQuestionsController>(tag: questionsTag)) {
        Get.delete<ReelQuestionsController>(tag: questionsTag, force: true);
        if (kDebugMode) Get.log('✅ [INMERSIVE] Controller eliminado: $questionsTag');
      }
    }).catchError((error) {
      if (kDebugMode) Get.log('⚠️ [INMERSIVE] Error en cleanup de Questions: $error');
    });
  }

  Widget _buildImmersiveAdPlaceholder(AdFeedItem ad) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[900]!, Colors.black],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.ads_click_rounded, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Anuncio patrocinado',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.snackbar('Próximamente', 'Esta funcionalidad estará disponible pronto',
                        backgroundColor: Colors.blueAccent, colorText: Colors.white);
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Ver más'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'Patrocinado',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// SKELETON LOADER (ESTÁTICO - REUTILIZADO + TIPADO)
// ===================================================================
class _FeedSkeletonLoader extends StatelessWidget {
  const _FeedSkeletonLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: 1,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) => Container(
        height: screenHeight,
        color: Colors.black,
        child: Stack(
          children: [
            Container(color: Colors.grey[900]),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: screenHeight * 0.42,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                      Colors.black,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 100,
                          height: 12,
                          color: Colors.grey[800],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 200,
                      height: 14,
                      color: Colors.grey[800],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 12,
                      color: Colors.grey[800],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _SkeletonCircle(size: 24),
                        const SizedBox(width: 12),
                        _SkeletonCircle(size: 24),
                        const SizedBox(width: 12),
                        _SkeletonCircle(size: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double size;
  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
    );
  }
}