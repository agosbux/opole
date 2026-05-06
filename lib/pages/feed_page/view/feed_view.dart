// lib/pages/feed_page/view/feed_view.dart
// ===================================================================
// FEED VIEW - DETERMINISTIC GETBUILDER + MEMORY SAFE
// ===================================================================
// ✅ FIX: assignId: true para escuchar múltiples tags en GetBuilder
// ✅ FIX: .whenComplete() para cleanup garantizado de Questions Sheet
// ✅ FIX: Logs estratégicos en kDebugMode para diagnóstico
// ✅ Mantiene: UI 100% dumb, cero lógica de negocio, arquitectura desacoplada
// ===================================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:opole/core/feed/feed_item_model.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:opole/pages/reel_questions/controller/reel_questions_controller.dart';
import 'package:opole/pages/reel_questions/view/reel_questions_sheet.dart';
import 'package:opole/pages/feed_page/widget/reel_card_widget.dart';
import 'package:opole/core/scroll/tiktok_scroll_physics.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final FeedController controller = Get.find<FeedController>();

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildFeedContent(controller),
          _buildStateOverlays(controller),
          _buildPaginationIndicator(controller),
        ],
      ),
    );
  }

  Widget _buildFeedContent(FeedController controller) {
    return GetBuilder<FeedController>(
      id: 'feed_state',
      builder: (FeedController ctrl) {
        final String state = ctrl.feedState.value;

        if (kDebugMode) {
          debugPrint('🔍 [FEED_VIEW] state: $state | items: ${ctrl.feedItems.length}');
        }

        if (state == 'waiting' || state == 'session_timeout' || state == 'session_error') {
          return _buildStatefulEmpty(ctrl);
        }

        if (state == 'loading' && ctrl.feedItems.isEmpty) {
          return const _FeedSkeletonLoader();
        }

        if (ctrl.feedItems.isEmpty) {
          return _buildStatefulEmpty(ctrl);
        }

        return const _FeedPageViewContent();
      },
    );
  }

  Widget _buildStatefulEmpty(FeedController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: GetBuilder<FeedController>(
          id: 'feed_state',
          builder: (FeedController ctrl) {
            final String state = ctrl.feedState.value;
            final String errorMsg = ctrl.lastError ?? '';

            if (state == 'waiting') {
              return _stateCard(
                Icons.hourglass_empty,
                'Verificando sesión...',
                'Confirmando identidad de forma segura',
              );
            }
            if (state == 'session_timeout') {
              return _stateCard(
                Icons.timer_off_outlined,
                'Tiempo de espera agotado',
                'La autenticación no respondió a tiempo. Revisá tu red.',
                actionLabel: 'Reintentar',
                onAction: () => ctrl.refreshFeed(),
              );
            }
            if (state == 'session_error' || errorMsg.contains('Perfil no encontrado')) {
              return _stateCard(
                Icons.person_off_outlined,
                'Perfil no disponible',
                errorMsg.isEmpty ? 'No se pudo cargar tu perfil.' : errorMsg,
                actionLabel: 'Ir a Login',
                onAction: () => Get.offAllNamed('/login'),
              );
            }

            return _stateCard(
              Icons.explore_outlined,
              'No hay reels disponibles',
              'Aún no hay contenido para tu ubicación o intereses.',
              actionLabel: 'Actualizar',
              onAction: () => ctrl.refreshFeed(),
            );
          },
        ),
      ),
    );
  }

  Widget _stateCard(
    IconData icon,
    String title,
    String subtitle, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.grey[500]),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onAction,
            child: Text(actionLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )
        ],
      ],
    );
  }

  Widget _buildStateOverlays(FeedController controller) {
    return IgnorePointer(
      child: GetBuilder<FeedController>(
        id: 'feed_state',
        builder: (FeedController ctrl) {
          final String state = ctrl.feedState.value;
          if (state != 'loading' || ctrl.feedItems.isEmpty) return const SizedBox.shrink();

          return Positioned(
            top: 40,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Actualizando...',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationIndicator(FeedController controller) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: GetBuilder<FeedController>(
        id: 'feed_state',
        builder: (FeedController ctrl) {
          if (!ctrl.hasMore.value || !ctrl.isLoading.value) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===================================================================
// 🚀 FEED PAGEVIEW CONTENT
// ===================================================================
class _FeedPageViewContent extends StatelessWidget {
  const _FeedPageViewContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FeedController>(
      id: 'feed_state',
      assignId: true,
      builder: (FeedController controller) {
        if (kDebugMode) {
          final itemCount = controller.feedItems.length + (controller.hasMore.value ? 1 : 0);
          debugPrint('🔍 [PAGEVIEW] itemCount: $itemCount | feedItems: ${controller.feedItems.length}');
        }
        
        final Size screenSize = MediaQuery.sizeOf(context);
        final double screenHeight = screenSize.height;
        final int itemCount = controller.feedItems.length + (controller.hasMore.value ? 1 : 0);

        return _FeedPageView(
          controller: controller,
          screenHeight: screenHeight,
          itemCount: itemCount,
        );
      },
    );
  }
}

// ===================================================================
// PageView separado (CORREGIDO + ARCHITECTURE ALIGNED)
// ===================================================================
class _FeedPageView extends StatefulWidget {
  final FeedController controller;
  final double screenHeight;
  final int itemCount;

  const _FeedPageView({
    required this.controller,
    required this.screenHeight,
    required this.itemCount,
    Key? key,
  }) : super(key: key);

  @override
  State<_FeedPageView> createState() => _FeedPageViewState();
}

class _FeedPageViewState extends State<_FeedPageView> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('🔧 [PAGEVIEW] initState - itemCount: ${widget.itemCount}');
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('🧹 [PAGEVIEW] dispose()');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FeedController controller = widget.controller;
    final double screenHeight = widget.screenHeight;

    if (kDebugMode && widget.itemCount == 1 && controller.feedItems.isEmpty) {
      debugPrint('⚠️ [PAGEVIEW] itemCount=1 con feedItems vacío - verificar fetchFeed()');
    }

    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (OverscrollIndicatorNotification overscroll) {
        overscroll.disallowIndicator();
        return true;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          if (controller.currentVisibleIndex.value == 0) {
            if (kDebugMode) debugPrint('🔄 [PULL] Refresh trigger');
            await controller.refreshFeed();
          }
        },
        displacement: 40,
        color: Colors.blueAccent,
        backgroundColor: Colors.black.withOpacity(0.8),
        child: PageView.builder(
          controller: controller.pageController,
          scrollDirection: Axis.vertical,
          physics: const TikTokScrollPhysics(minFlingVelocity: 300.0),
          allowImplicitScrolling: false,
          padEnds: false,
          pageSnapping: true,
          clipBehavior: Clip.hardEdge,
          itemCount: widget.itemCount,
          onPageChanged: (int index) {
            if (kDebugMode) {
              debugPrint('📄 [PAGE] onPageChanged: $index / ${widget.itemCount - 1}');
            }
            controller.onPageChanged(index);
          },
          itemBuilder: (BuildContext context, int index) {
            final List<FeedItem> feedItems = controller.feedItems;

            if (index == feedItems.length) {
              if (controller.hasMore.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                );
              } else {
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
                          onPressed: () => controller.refreshFeed(),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Actualizar feed'),
                          style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }

            final FeedItem feedItem = feedItems[index];

            if (feedItem is! ReelFeedItem) {
              return Semantics(
                label: 'Anuncio patrocinado',
                enabled: true,
                child: ReelCardWidget(
                  key: ValueKey<String>('ad_${feedItem.id}'),
                  feedItem: feedItem,
                  index: index,
                  isBoosted: feedItem.isBoosted,
                  viewType: ReelViewType.feed,
                  screenHeight: screenHeight,
                  onQuestions: null,
                  onLoQuiero: null,
                  onLike: null,
                  onHashtagSelected: null,
                  onShare: null,
                  onWatchTimeUpdate: null,
                  onVideoStart: null,
                  onInteraction: null,
                  onComplete: null,
                  questionsCount: 0,
                ),
              );
            }

            return Semantics(
              label: 'Reel de ${feedItem.reel.userUsername ?? "usuario"}',
              enabled: true,
              child: ReelCardWidget(
                key: ValueKey<String>('reel_${feedItem.reel.id}_$index'),
                feedItem: feedItem,
                index: index,
                isBoosted: feedItem.isBoosted,
                viewType: ReelViewType.feed,
                screenHeight: screenHeight,
                onQuestions: () => _showQuestionsSheet(feedItem),
                onLoQuiero: null,
                onLike: null,
                onHashtagSelected: (String tag) => controller.onCategorySelected(tag),
                onShare: null,
                onWatchTimeUpdate: null,
                onVideoStart: null,
                onInteraction: null,
                onComplete: null,
                questionsCount: controller.getQuestionsCount(feedItem.reel.id),
              ),
            );
          },
        ),
      ),
    );
  }

  // ✅ UI PURA: Navegación a sheet de preguntas con cleanup garantizado
  void _showQuestionsSheet(FeedItem feedItem) {
    if (feedItem is! ReelFeedItem) return;

    final String questionsTag = 'questions_${feedItem.reel.id}';
    
    if (!Get.isRegistered<ReelQuestionsController>(tag: questionsTag)) {
      Get.put<ReelQuestionsController>(ReelQuestionsController(), tag: questionsTag, permanent: false);
    }
    final ReelQuestionsController qController = Get.find<ReelQuestionsController>(tag: questionsTag);

    qController.setReelOwnerId(feedItem.reel.userId);
    qController.loadQuestions(feedItem.reel.id);

    // 🔥 FIX: Usar .whenComplete() para cleanup garantizado (GetX retorna Future, no Route)
    Get.bottomSheet(
      ReelQuestionsSheet(reelId: feedItem.reel.id),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    )?.whenComplete(() {
      if (kDebugMode) debugPrint('🧹 [QUESTIONS] Sheet closed, limpiando controller: $questionsTag');
      if (Get.isRegistered<ReelQuestionsController>(tag: questionsTag)) {
        Get.delete<ReelQuestionsController>(tag: questionsTag, force: true);
      }
    }).catchError((error) {
      if (kDebugMode) debugPrint('⚠️ [QUESTIONS] Error en cleanup: $error');
    });
  }
}

// ===================================================================
// SKELETON LOADER (ESTÁTICO - SIN CAMBIOS)
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