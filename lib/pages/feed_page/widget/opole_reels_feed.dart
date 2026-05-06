import 'package:flutter/material.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:opole/core/feed/feed_item_model.dart';
import 'package:opole/pages/feed_page/widget/reel_card_widget.dart';
import 'package:opole/core/ads/ad_controller.dart';
import 'package:get/get.dart';

/// Widget principal del feed de reels de Opole.
/// Utiliza un PageView vertical con snaps perfectos y optimizaciÃ³n de memoria.
class OpoleReelsFeedWidget extends StatelessWidget {
  final FeedController controller;

  const OpoleReelsFeedWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Estado de carga inicial
      if (controller.isLoading.value && controller.feedItems.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      // Estado vacÃ­o
      if (controller.feedItems.isEmpty) {
        return _buildEmptyState();
      }

      // PageView con los items del feed (reels + ads)
      return PageView.builder(
        controller: controller.pageController,
        scrollDirection: Axis.vertical,
        itemCount: controller.feedItems.length,
        pageSnapping: true, // âœ… TIP 1: Experiencia tipo Reel, sin scroll intermedio
        physics: const PageScrollPhysics(),
        onPageChanged: (index) => controller.onPageChanged(index),
        itemBuilder: (context, index) {
          final item = controller.feedItems[index];
          // Key Ãºnico para que Flutter no confunda un reel con un ad al reciclar
          return Container(
            key: ValueKey(item.id),
            color: Colors.black, // Fondo negro constante para evitar destellos
            child: Obx(() {
              final isPlaying = controller.currentIndex.value == index;
              return _buildFeedItem(item, index, isPlaying);
            }),
          );
        },
      );
    });
  }

  /// Renderiza condicionalmente el widget segÃºn el tipo de [FeedItem].
  Widget _buildFeedItem(FeedItem item, int index, bool isPlaying) {
    if (item is ReelFeedItem) {
      return ReelCardWidget(
        reel: item.reel,
        index: index,
        isPlaying: isPlaying,
        isBoosted: item.isBoosted,
        // Callbacks para tracking de engagement y watch time
        onProgress: (progress) => controller.onVideoProgress(item.reel.id, progress),
        onInteraction: (type) => controller.onInteraction(item.reel.id, type),
        onComplete: () => controller.onVideoComplete(item.reel.id),
      );
    } else if (item is AdFeedItem) {
      // âœ… TIP 2: Desacoplamiento â€“ la implementaciÃ³n del ad se oculta tras la abstracciÃ³n
      // Registrar impresiÃ³n sin bloquear el frame de renderizado
      if (isPlaying) {
        Future.microtask(() => AdController.instance.trackAdImpression(item.adId));
      }

      return AdController.instance.buildNativeAdWidget(
        adId: item.adId,
        position: item.position,
        metadata: item.adMetadata,
      );
    }

    // Fallback (no deberÃ­a ocurrir)
    return Container(color: Colors.black);
  }

  /// Construye el estado vacÃ­o del feed.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'No hay reels disponibles',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
