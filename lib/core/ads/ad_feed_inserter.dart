import 'package:opole/core/feed/feed_item_model.dart';

class AdFeedInserter {
  static AdFeedInserter? _instance;
  
  /// ConfiguraciÃ³n actual (dinÃ¡mica)
  int adsEveryNReels;
  int firstAdPosition;
  int maxAdsPerBatch;

  /// Constructor privado con valores por defecto y validaciÃ³n
  AdFeedInserter._internal({
    int? adsEveryNReels,
    int? firstAdPosition,
    int? maxAdsPerBatch,
  }) : adsEveryNReels = (adsEveryNReels ?? 10) > 0 ? adsEveryNReels! : 10,
       firstAdPosition = firstAdPosition ?? 5,
       maxAdsPerBatch = maxAdsPerBatch ?? 3;

  /// Obtiene la instancia singleton. Si se necesita una configuraciÃ³n diferente,
  /// se puede llamar a `updateConfig` despuÃ©s.
  static AdFeedInserter get instance {
    _instance ??= AdFeedInserter._internal();
    return _instance!;
  }

  /// Actualiza la configuraciÃ³n en caliente (Ãºtil para A/B testing)
  void updateConfig({
    int? adsEveryNReels,
    int? firstAdPosition,
    int? maxAdsPerBatch,
  }) {
    if (adsEveryNReels != null) {
      // Evitar valores invÃ¡lidos
      this.adsEveryNReels = adsEveryNReels > 0 ? adsEveryNReels : 10;
    }
    this.firstAdPosition = firstAdPosition ?? this.firstAdPosition;
    this.maxAdsPerBatch = maxAdsPerBatch ?? this.maxAdsPerBatch;

    // (Opcional) Loguear o notificar el cambio para analytics
  }

  /// Inserta anuncios en una lista existente de FeedItems.
  /// [offset] indica cuÃ¡ntos reels ya se han mostrado antes de esta lista.
  List<FeedItem> insertAdsInFeed(List<FeedItem> feed, {int offset = 0}) {
    if (feed.isEmpty) return feed;

    final result = <FeedItem>[];
    int adCount = 0;
    int reelCount = 0; // reels procesados en este batch

    // Valor seguro para evitar divisiÃ³n por cero
    final safeFrequency = adsEveryNReels > 0 ? adsEveryNReels : 10;

    for (var i = 0; i < feed.length; i++) {
      final item = feed[i];
      result.add(item);

      if (item is ReelFeedItem) {
        reelCount++;
        final globalReelIndex = offset + reelCount; // Ã­ndice global del reel actual

        // Decidir si insertar anuncio despuÃ©s de este reel
        final shouldInsertAd = globalReelIndex >= firstAdPosition &&
            (globalReelIndex - firstAdPosition) % safeFrequency == 0 &&
            adCount < maxAdsPerBatch;

        if (shouldInsertAd) {
          // batchIndex: identificador del lote para construir IDs estables
          final batchIndex = offset ~/ safeFrequency;
          result.add(_createAdItem(globalReelIndex, batchIndex: batchIndex));
          adCount++;
        }
      }
    }

    return result;
  }

  /// Crea un feed desde cero con los anuncios ya intercalados.
  List<FeedItem> createFeedWithAds(
    List<ReelFeedItem> reels, {
    int offset = 0,
  }) {
    if (reels.isEmpty) return [];

    final result = <FeedItem>[];
    int adCount = 0;
    final safeFrequency = adsEveryNReels > 0 ? adsEveryNReels : 10;

    for (var i = 0; i < reels.length; i++) {
      result.add(reels[i]);

      final globalIndex = offset + i + 1; // posiciÃ³n global del reel
      final shouldInsertAd = globalIndex >= firstAdPosition &&
          (globalIndex - firstAdPosition) % safeFrequency == 0 &&
          adCount < maxAdsPerBatch;

      if (shouldInsertAd) {
        final batchIndex = offset ~/ safeFrequency;
        result.add(_createAdItem(globalIndex, batchIndex: batchIndex));
        adCount++;
      }
    }

    return result;
  }

  /// Crea un item de anuncio con metadatos y un ID determinÃ­stico.
  AdFeedItem _createAdItem(int globalPosition, {int? batchIndex}) {
    // ID estable: usa batchIndex y posiciÃ³n global para evitar reconstrucciones innecesarias
    final adId = batchIndex != null
        ? 'ad_batch_${batchIndex}_pos_$globalPosition'
        : 'ad_initial_$globalPosition';

    return AdFeedItem(
      adId: adId,
      position: globalPosition,
      adMetadata: {
        'type': 'native',
        'placement': 'feed_scroll',
        'frequency': adsEveryNReels,
        'first_position': firstAdPosition,
        'batch_index': batchIndex,
      },
    );
  }

  /// MÃ©tricas para analytics (Ãºtil para depuraciÃ³n)
  Map<String, dynamic> getAdMetrics(List<FeedItem> feed) {
    final total = feed.length;
    final ads = feed.whereType<AdFeedItem>().length;
    final reels = feed.whereType<ReelFeedItem>().length;

    return {
      'total_items': total,
      'ad_count': ads,
      'reel_count': reels,
      'ad_ratio': total > 0 ? ads / total : 0,
      'expected_frequency': adsEveryNReels,
    };
  }
}
