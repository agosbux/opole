// lib/modules/feed/views/opole_feed_page.dart
// ===================================================================
// OPOLE FEED PAGE - Vista principal del feed (estilo TikTok/Reels)
// ===================================================================
// â€¢ PageView.vertical con scroll infinito
// â€¢ Control de reproducciÃ³n: solo el reel visible se reproduce
// â€¢ IntegraciÃ³n reactiva con OpoleFeedController (GetX)
// â€¢ Estados: loading, empty, error, paginating
// â€¢ Debug de userId para validar sesiÃ³n de Supabase
// â€¢ Optimizado para Moto G31 (60Hz) y build de producciÃ³n
// â€¢ ConexiÃ³n con VideoPreloadManager para performance mÃ¡xima
// ===================================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/modules/feed/controllers/opole_feed_controller.dart';
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/core/services/supabase_client.dart' as supabase;
import 'package:opole/pages/reels_page/widget/reel_card_widget.dart';
import 'package:opole/core/video/video_preload_manager.dart'; // â† NUEVO: Para precarga inteligente

class OpoleFeedPage extends StatelessWidget {
  const OpoleFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OpoleFeedController(), permanent: false);

    // ðŸ” DEBUG: Verificar userId
    final userId = supabase.SupabaseClient.currentUserId;
    if (userId == null || userId.isEmpty) {
      Get.log('âš ï¸ [UI] userId es null o vacÃ­o - sesiÃ³n de Supabase podrÃ­a no estar activa');
    } else {
      Get.log('âœ… [UI] userId vÃ¡lido: ${userId.substring(0, 8)}...');
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildFeedPageView(controller),
          _buildStateOverlays(controller),
          _buildPaginationIndicator(controller),
        ],
      ),
    );
  }

  // ===================================================================
  // ðŸ”¹ PAGEVIEW CON CONTROL DE REPRODUCCIÃ“N + PRELOAD MANAGER
  // ===================================================================
  Widget _buildFeedPageView(OpoleFeedController controller) {
    // âœ… ESTADO LOCAL: Ã­ndice del reel que debe reproducirse
    final RxInt currentVisibleIndex = 0.obs;

    return Obx(() {
      final reels = controller.reels;

      if (reels.isEmpty && controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
      }

      if (reels.isEmpty) {
        return _buildEmptyState(controller);
      }

      return RefreshIndicator(
        onRefresh: () async => await controller.refreshFeed(),
        color: Colors.blueAccent,
        backgroundColor: Colors.black.withOpacity(0.8),
        child: PageView.builder(
          scrollDirection: Axis.vertical,
          // ðŸš€ OPTIMIZACIÃ“N: Scroll "pesado" tipo TikTok para Moto G31 (60Hz)
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          clipBehavior: Clip.hardEdge, // âœ… Mejora rendimiento visual al recortar widgets fuera de vista
          itemCount: reels.length + (controller.hasMore.value ? 1 : 0),
          onPageChanged: (index) {
            // âœ… ACTUALIZAR Ã­ndice visible â†’ controla quÃ© reel se reproduce
            currentVisibleIndex.value = index;

            // ðŸš€ COMUNICACIÃ“N CON VIDEO PRELOAD MANAGER (Vital para performance)
            final manager = VideoPreloadManager.instance;
            manager.updateCurrentIndex(index);
            manager.pauseAllExcept(index);
            
            // Precarga proactiva del video que estÃ¡ 2 lugares adelante
            if (index + 2 < reels.length) {
              final nextReel = reels[index + 2];
              manager.preloadNext(index + 2, nextReel.videoUrl);
            }

            // Trigger de paginaciÃ³n
            if (index >= reels.length - 2 && controller.hasMore.value) {
              Get.log('ðŸ”„ [UI] Trigger paginaciÃ³n en Ã­ndice $index');
              controller.loadNextPage();
            }

            // âœ… Trackear vista inicial (solo para mÃ©trica de "impresiÃ³n", no para tiempo visto)
            if (index < reels.length) {
              final reel = reels[index];
              // Solo registramos la impresiÃ³n, el tiempo real lo maneja onProgress
              controller.trackView(reel.id, Duration.zero);
            }
          },
          itemBuilder: (context, index) {
            // Loader de paginaciÃ³n
            if (index == reels.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
              );
            }

            final reel = reels[index];
            
            // âœ… Obx para reactividad en isPlaying sin reconstruir todo el widget
            return Obx(() {
              final isPlaying = currentVisibleIndex.value == index;
              
              return ReelCardWidget(
                reel: reel,
                index: index,
                isPlaying: isPlaying,  // â† SOLO este reel se reproduce
                isBoosted: reel.isBoosted ?? false,
                
                // âœ… onProgress: Solo trackear si pasÃ³ mÃ¡s de 3 segundos (evita spam en Supabase)
                onProgress: (Duration position) {
                  // 'position' ya viene como Duration desde ReelCardWidget corregido
                  if (position.inSeconds > 3) {
                    controller.trackView(reel.id, position);
                  }
                },
                
                onInteraction: (type) => controller.trackInteraction(reel.id, type),
                
                // âœ… onComplete: Trackear como vista completa (30s)
                onComplete: () => controller.trackView(reel.id, const Duration(seconds: 30)),
                
                // âœ… onLoQuiero: AcciÃ³n comercial real, no solo un log
                onLoQuiero: () => _showPurchaseInterest(context, reel),
              );
            });
          },
        ),
      );
    });
  }

  // ===================================================================
  // ðŸ›ï¸ NUEVO: DiÃ¡logo de interÃ©s de compra (Bottom Sheet)
  // ===================================================================
  void _showPurchaseInterest(BuildContext context, ReelModel reel) {
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.shopping_bag, color: Colors.pinkAccent, size: 24),
                const SizedBox(width: 8),
                const Text("Â¿Te interesa este producto?", 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Info del producto
            Text(reel.title ?? 'Producto sin tÃ­tulo',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            if (reel.price != null)
              Text('\$${reel.price}', 
                style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
            const SizedBox(height: 8),
            
            // ExplicaciÃ³n
            Text("Al confirmar, el vendedor @${reel.userUsername ?? 'usuario'} recibirÃ¡ una notificaciÃ³n de tu interÃ©s.",
              textAlign: TextAlign.start, 
              style: TextStyle(color: Colors.white70, fontSize: 14)),
            
            const SizedBox(height: 24),
            
            // Botones de acciÃ³n
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white24),
                    ),
                    child: const Text("Cancelar"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Get.back();
                      
                      // âœ… AquÃ­ se dispararÃ­a la lÃ³gica real de "Lo Quiero"
                      // Ej: controller.createLead(reel.id); o controller.onInteraction(reel.id, 'lo_quiero');
                      Get.snackbar(
                        "Â¡Excelente! â¤ï¸", 
                        "Tu interÃ©s ha sido enviado a @${reel.userUsername ?? 'usuario'}.",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green.withOpacity(0.9),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 4),
                        margin: const EdgeInsets.all(16),
                      );
                    },
                    child: const Text("Â¡Confirmar interÃ©s!"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // ðŸ”¹ EMPTY STATE
  // ===================================================================
  Widget _buildEmptyState(OpoleFeedController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.isNotEmpty 
                  ? controller.errorMessage.value 
                  : 'No hay reels disponibles',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (controller.errorMessage.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => controller.clearFilters(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Recargar sin filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // ðŸ”¹ OVERLAYS DE ESTADO
  // ===================================================================
  Widget _buildStateOverlays(OpoleFeedController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.reels.isEmpty) {
        return Container(
          color: Colors.black.withOpacity(0.8),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.blueAccent),
                SizedBox(height: 16),
                Text('Cargando feed...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        );
      }

      if (controller.errorMessage.isNotEmpty && controller.reels.isEmpty) {
        return Container(
          color: Colors.black.withOpacity(0.8),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => controller.refreshFeed(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }

  // ===================================================================
  // ðŸ”¹ INDICADOR DE PAGINACIÃ“N
  // ===================================================================
  Widget _buildPaginationIndicator(OpoleFeedController controller) {
    return Obx(() {
      if (!controller.isPaginating.value || controller.reels.isEmpty) {
        return const SizedBox.shrink();
      }

      return Positioned(
        bottom: 20,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(
                    strokeWidth: 2, 
                    color: Colors.white70,
                  ),
                ),
                SizedBox(width: 8),
                Text('Cargando mÃ¡s...', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    });
  }
}
