// lib/core/feed/ad_inserter.dart
// ===================================================================
// AD INSERTER v2.1 - PRODUCTION SAFE + ANALYTICS HOOKS
// ===================================================================
// ✅ IDs de anuncios con UUID (0 colisiones)
// ✅ Trazabilidad: posición final en feed
// ✅ Hooks para impresión/click inyectables
// ✅ Frecuencia configurable (A/B testing ready)
// ✅ Placeholders locales, inserción estratégica
// ===================================================================

import 'dart:math';
import 'package:opole/core/feed/feed_item_model.dart';

// 🆕 Helper para IDs únicos (sin dependencia externa)
class _AdIdGenerator {
  static int _counter = 0;
  static final _random = Random.secure();
  
  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(0xFFFFFFFF);
    final count = _counter++;
    return 'ad_${timestamp}_${rand.toRadixString(16)}_${count}';
  }
}

/// Tipo para callbacks de analytics
typedef AdImpressionCallback = void Function(String adId, int position);
typedef AdClickCallback = void Function(String adId, int position);

class AdInserter {
  static AdInserter? _instance;
  static AdInserter get instance {
    _instance ??= AdInserter._();
    return _instance!;
  }

  // 🔹 Constructor privado con parámetros opcionales y valores por defecto
  AdInserter._({
    this.adFrequency = 10,
    this.firstAdPosition = 5,
    this.onAdImpression,
    this.onAdClick,
  });

  // 🔹 Configuración de frecuencia de anuncios
  final int adFrequency;
  final int firstAdPosition;
  
  // 🆕 Callbacks de analytics (inyectables)
  final AdImpressionCallback? onAdImpression;
  final AdClickCallback? onAdClick;
  
  // 🔹 Constructor factory para A/B testing y remote config
  factory AdInserter.withConfig({
    int adFrequency = 10,
    int firstAdPosition = 5,
    AdImpressionCallback? onAdImpression,
    AdClickCallback? onAdClick,
  }) {
    return AdInserter._(
      adFrequency: adFrequency,
      firstAdPosition: firstAdPosition,
      onAdImpression: onAdImpression,
      onAdClick: onAdClick,
    );
  }

  // 🔹 Placeholders locales (0 red, carga instantánea)
  static const List<String> _localPlaceholders = [
    'assets/images/ad_placeholder_1.png',
    'assets/images/ad_placeholder_2.png',
  ];

  // 🔹 Insertar anuncios en el feed
  List<FeedItem> insertAds(List<ReelFeedItem> reels, {int offset = 0}) {
    final result = <FeedItem>[];
    int adCount = 0;

    for (int i = 0; i < reels.length; i++) {
      final absoluteIndex = offset + i;

      if (_shouldInsertAd(absoluteIndex)) {
        final finalDisplayIndex = result.length;
        result.add(_createAd(
          adCount,
          finalDisplayIndex: finalDisplayIndex,
        ));
        adCount++;
      }

      result.add(reels[i]);
    }

    return result;
  }

  // 🔹 Decidir si insertar ad en esta posición
  bool _shouldInsertAd(int absoluteIndex) {
    if (absoluteIndex < firstAdPosition) return false;
    final adjustedIndex = absoluteIndex - firstAdPosition;
    return adjustedIndex >= 0 && adjustedIndex % adFrequency == 0;
  }

  // 🔹 Crear item de anuncio usando AdFeedItem.validated
  AdFeedItem _createAd(int adCount, {required int finalDisplayIndex}) {
    final placeholderUrl = _localPlaceholders[adCount % _localPlaceholders.length];
    final adId = _AdIdGenerator.generate();

    return AdFeedItem.validated(
      adId: adId,
      adTitle: 'Anuncio patrocinado',
      adImageUrl: placeholderUrl,
      position: finalDisplayIndex,
      onImpression: () => _trackAdImpression(adId, finalDisplayIndex),
      onClick: () => _trackAdClick(adId, finalDisplayIndex),
    );
  }

  // 🔹 Métodos internos de tracking (delegan en callbacks externos)
  void _trackAdImpression(String adId, int position) {
    // Hook para analytics: se dispara cuando el ad entra en viewport
    onAdImpression?.call(adId, position);
  }

  void _trackAdClick(String adId, int position) {
    // Hook para analytics: se dispara al hacer click en el ad
    onAdClick?.call(adId, position);
  }

  // 🔹 [FUTURO] Integración con AdMob / Meta Audience Network
  // Para migrar a ads reales, solo hay que:
  // 1. Agregar flag: bool get useRemoteAds => true;
  // 2. Modificar _createAd para retornar AdFeedItem con placementId
  // 3. Implementar los callbacks onImpression/onClick con el SDK correspondiente
}