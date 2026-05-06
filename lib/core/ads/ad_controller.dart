// ===================================================================
// AD CONTROLLER - VersiÃ³n corregida (sin errores de sintaxis)
// ===================================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/core/services/supabase_client.dart';
import 'package:opole/core/supabase/supabase_api.dart';

class AdController extends GetxController {
  static AdController get instance {
    if (!Get.isRegistered<AdController>()) {
      return Get.put(AdController());
    }
    return Get.find<AdController>();
  }

  final SupabaseApi _supabase = SupabaseApi.instance;
  final Set<String> _trackedImpressions = {};

  // ===================================================================
  // ðŸ”¹ MÃ‰TODO PRINCIPAL: Construye el widget del anuncio nativo
  // ===================================================================
  Widget buildNativeAdWidget({
    required String adId,
    required int position,
    Map<String, dynamic>? metadata,
  }) {
    final String title = metadata?['title'] ?? 'OFERTA EXCLUSIVA';
    final String ctaText = metadata?['cta_text'] ?? 'VER MÃS';
    final String? imageUrl = metadata?['image_url'];

    return Container(
      key: ValueKey(adId),
      color: Colors.black,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.blueGrey.withValues(alpha: 0.2), // âœ… Fix: conValues en lugar de withOpacity
                  Colors.black,
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge(),
                const SizedBox(height: 30),
                _buildAdContent(title, imageUrl),
                const SizedBox(height: 30),
                _buildActionButton(adId, ctaText),
              ],
            ),
          ),
        ],
      ),
    ); // âœ… Cierre explÃ­cito del return
  }

  // ===================================================================
  // ðŸ”¹ Contenido del anuncio (tÃ­tulo + imagen)
  // ===================================================================
  Widget _buildAdContent(String title, String? imageUrl) {
    return Column(
      children: [
        if (imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              imageUrl,
              height: 300,
              width: 250,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
            ),
          )
        else
          _buildPlaceholderIcon(), // âœ… Return explÃ­cito en ambos caminos del if
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    ); // âœ… Cierre explÃ­cito del return
  }

  // ===================================================================
  // ðŸ”¹ Placeholder cuando no hay imagen
  // ===================================================================
  Widget _buildPlaceholderIcon() {
    return Container(
      height: 250,
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // âœ… Fix: conValues
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Colors.blueAccent,
        size: 80,
      ),
    ); // âœ… Cierre explÃ­cito del return
  }

  // ===================================================================
  // ðŸ”¹ Badge "AD"
  // ===================================================================
  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2), // âœ… Fix: conValues
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'AD',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ); // âœ… Cierre explÃ­cito del return
  }

  // ===================================================================
  // ðŸ”¹ BotÃ³n de acciÃ³n del anuncio
  // ===================================================================
  Widget _buildActionButton(String adId, String text) {
    return ElevatedButton(
      onPressed: () => _handleAdClick(adId),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ); // âœ… Cierre explÃ­cito del return
  }

  // ===================================================================
  // ðŸ”¹ Trackear impresiÃ³n del anuncio
  // ===================================================================
  void trackAdImpression(String adId) {
    final userId = SupabaseClient.currentUserId;
    if (userId == null || _trackedImpressions.contains(adId)) {
      return; // âœ… Return explÃ­cito
    }

    _trackedImpressions.add(adId);
    _supabase.trackReelEngagement(
      reelId: adId,
      userId: userId,
      eventType: 'view_ad',
    );
    Get.log('ðŸ“Š ImpresiÃ³n de Ad $adId trackeada para user $userId');
  }

  // ===================================================================
  // ðŸ”¹ Manejar clic en el anuncio
  // ===================================================================
  void _handleAdClick(String adId) {
    final userId = SupabaseClient.currentUserId;
    if (userId == null) {
      return; // âœ… Return explÃ­cito
    }

    _supabase.trackReelEngagement(
      reelId: adId,
      userId: userId,
      eventType: 'click_ad',
    );
    Get.log('ðŸ–±ï¸ Clic en Ad $adId trackeado');
  }
}
