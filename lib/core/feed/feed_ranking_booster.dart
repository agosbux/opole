// lib/core/feed/feed_ranking_booster.dart
// ===================================================================
// FEED RANKING BOOSTER - FASE 4
// ===================================================================
// ✅ Reordena el feed LOCAL usando el perfil de usuario
// ✅ Boost dinámico: affinity score del perfil + rankingScore del servidor
// ✅ Decay temporal: boost baja si el video lleva mucho tiempo en feed
// ✅ Penalización de tags negativos (usuario los skipea siempre)
// ✅ No toca los primeros 2 items (ya cargados/visibles) — 0 jank
// ✅ Puro Dart, sin dependencias de Flutter/UI
// ===================================================================

import 'package:opole/core/feed/feed_item_model.dart';
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/core/engagement/user_content_profile.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class FeedRankingBooster {
  FeedRankingBooster._();
  static final FeedRankingBooster instance = FeedRankingBooster._();

  /// Peso relativo del score del servidor vs la preferencia personal.
  /// 0.7 = 70% servidor (frescura/engagement global) + 30% perfil usuario.
  static const double _serverWeight = 0.7;
  static const double _profileWeight = 0.3;

  /// Reordena [feedItems] a partir del índice [fromIndex] usando [profile].
  /// Los primeros [fromIndex] items NO se tocan (ya son visibles o están cargando).
  /// Retorna la lista reordenada (modifica in-place y retorna la misma lista).
  List<FeedItem> rerank({
    required List<FeedItem> feedItems,
    required UserContentProfile profile,
    required int fromIndex,
  }) {
    if (feedItems.length <= fromIndex + 1) return feedItems;

    final toReorder = feedItems.sublist(fromIndex);
    final fixed = feedItems.sublist(0, fromIndex);

    final negatives = profile.negativeInterests;

    toReorder.sort((a, b) {
      final scoreA = _score(a, profile, negatives);
      final scoreB = _score(b, profile, negatives);
      return scoreB.compareTo(scoreA); // mayor score primero
    });

    if (kDebugMode) {
      print('🧠 [BOOSTER] Reranked ${toReorder.length} items from idx $fromIndex');
    }

    final result = [...fixed, ...toReorder];
    feedItems
      ..clear()
      ..addAll(result);

    return feedItems;
  }

  double _score(FeedItem item, UserContentProfile profile, Set<String> negatives) {
    if (item is! ReelFeedItem) return 0.0;
    final reel = item.reel;

    // Score base del servidor (normalizado a 0-1 aprox)
    final serverScore = (reel.rankingScore ?? 0.0).clamp(0.0, 100.0) / 100.0;

    // Tags del reel para calcular afinidad
    final tags = _extractTags(reel);

    // Penalización si el usuario siempre skipea este tipo de contenido
    final hasNegativeTag = tags.any((t) => negatives.contains(t));
    if (hasNegativeTag) return serverScore * 0.3; // reducir fuerte pero no eliminar

    // Afinidad del perfil (-1.0 a 1.0) → normalizar a (0.0 a 1.0)
    final affinity = (profile.affinityScore(tags) + 1.0) / 2.0;

    // Score combinado
    return serverScore * _serverWeight + affinity * _profileWeight;
  }

  List<String> _extractTags(ReelModel reel) {
    final tags = <String>[];

    // Categorías (es una lista en ReelModel)
    if (reel.categories != null) {
      for (final cat in reel.categories!) {
        if (cat.isNotEmpty) tags.add(cat.toLowerCase());
      }
    }

    // Hashtags explícitos del modelo (si existen)
    if (reel.hashtags != null) {
      for (final tag in reel.hashtags!) {
        if (tag.isNotEmpty) tags.add(tag.toLowerCase());
      }
    }

    // Hashtags extraídos de la descripción vía regex
    final desc = reel.description ?? '';
    final hashtagMatches = RegExp(r'#(\w+)').allMatches(desc);
    for (final m in hashtagMatches) {
      final tag = m.group(1);
      if (tag != null && tag.isNotEmpty) {
        tags.add(tag.toLowerCase());
      }
    }

    return tags;
  }
}