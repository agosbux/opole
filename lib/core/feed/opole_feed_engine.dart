// lib/core/feed/opole_feed_engine.dart
// ===================================================================
// OPOLE_FEED_ENGINE v2.0 - PRODUCTION SAFE
// ===================================================================
// ✅ Cache key incluye limit para evitar colisiones
// ✅ Prune cache con conciencia de cursor chains (LRU simple)
// ✅ refreshFeed invalida cache antes de fetch
// ✅ getFeed retorna nullable + excepción tipada para errores
// ✅ Mantiene: cursor pagination, métricas, pesos configurables
// ===================================================================

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:opole/core/feed/feed_item_model.dart';
import 'package:opole/core/feed/ad_inserter.dart';
import 'package:opole/core/supabase/supabase_api.dart';
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/core/engagement/reel_engagement_service.dart';

// 🆕 Excepción tipada para errores del engine
class FeedEngineException implements Exception {
  final String message;
  final dynamic cause;
  const FeedEngineException(this.message, [this.cause]);
  @override
  String toString() => 'FeedEngineException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

class OpoleFeedEngine extends GetxService {
  // ===================================================================
  // 🔹 SINGLETON
  // ===================================================================
  static OpoleFeedEngine? _instance;
  static OpoleFeedEngine get instance {
    _instance ??= Get.put(OpoleFeedEngine());
    return _instance!;
  }

  // ===================================================================
  // 🔹 DEPENDENCIAS
  // ===================================================================
  final SupabaseApi _api = SupabaseApi.instance;
  final AdInserter _adInserter = AdInserter.instance;
  final ReelEngagementService _engagement = ReelEngagementService.instance;

  // ===================================================================
  // 🔹 PESOS DEL ALGORITMO
  // ===================================================================
  double boostWeight = 2.0;
  double geoWeight = 1.5;
  double interestWeight = 1.3;
  double engagementWeight = 1.2;
  double recencyWeight = 1.0;

  // ===================================================================
  // 🔹 MÉTRICAS DE CACHE
  // ===================================================================
  int _cacheHits = 0;
  int _cacheMisses = 0;

  // ===================================================================
  // 🔹 MÉTODO PRINCIPAL: Obtener Feed (RETORNO NULLABLE)
  // ===================================================================
  Future<List<FeedItem>?> getFeed({
    required String userId,
    int limit = 20,
    double? lastScore,
    String? lastId,
    int offset = 0,
    String? userLocation,
    List<String>? userInterests,
  }) async {
    if (kDebugMode) {
      Get.log('🔷 [ENGINE] getFeed - userId: ${userId.substring(0, 8)}..., limit: $limit, cursor: ($lastScore, $lastId)');
    }
    
    try {
      final rawReels = await _fetchFromSupabase(
        userId: userId,
        limit: limit,
        lastScore: lastScore,
        lastId: lastId,
        userLocation: userLocation,
        userInterests: userInterests,
      );

      final reelItems = rawReels.map((reel) {
        final scores = _calculateScores(
          reel,
          userInterests: userInterests,
          userLocation: userLocation,
        );
        return ReelFeedItem(
          reel: reel,
          calculatedRankingScore: scores['ranking'] ?? 0.0,
          calculatedBoostScore: scores['boost'] ?? 0.0,
        );
      }).toList();

      final sortedReels = _applyRanking(reelItems);
      final feedWithAds = _adInserter.insertAds(sortedReels, offset: offset);

      return feedWithAds;
      
    } on FeedEngineException {
      // Re-lanzar excepciones tipadas para que el controller las maneje
      rethrow;
    } catch (e, stack) {
      if (kDebugMode) {
        Get.log('❌ [ENGINE] ERROR en getFeed: $e');
        Get.log('❌ [ENGINE] Stack: $stack');
      }
      // 🆕 Retornar null para que el controller distinga error de "vacío"
      return null;
    }
  }

  // ===================================================================
  // 🔹 FETCH DESDE SUPABASE
  // ===================================================================
  Future<List<ReelModel>> _fetchFromSupabase({
    required String userId,
    required int limit,
    double? lastScore,
    String? lastId,
    String? userLocation,
    List<String>? userInterests,
  }) async {
    try {
      String? province;
      String? locality;
      
      if (userLocation != null && userLocation.isNotEmpty) {
        if (userLocation.contains('|')) {
          final parts = userLocation.split('|');
          province = parts[0].trim();
          locality = parts.length > 1 ? parts[1].trim() : null;
        } else {
          province = userLocation.trim();
        }
      }

      final reels = await _api.getOpoleFeed(
        userId: userId,
        limit: limit,
        lastScore: lastScore,
        lastId: lastId,
        province: province,
        locality: locality,
        userInterests: userInterests,
      );
      
      return reels;
      
    } catch (e) {
      if (kDebugMode) Get.log('❌ [ENGINE] ERROR en _fetchFromSupabase: $e');
      // 🆕 Lanzar excepción tipada para propagación controlada
      throw FeedEngineException('Failed to fetch from Supabase', e);
    }
  }

  // ===================================================================
  // 🔹 CALCULAR SCORES
  // ===================================================================  
  Map<String, double> _calculateScores(
    ReelModel reel, {
    List<String>? userInterests,
    String? userLocation,
  }) {
    final baseRanking = reel.rankingScore ?? 0.0;
    final baseBoost = reel.boostScore ?? 0.0;
    final geoPriority = reel.geoPriority ?? 0.0;
    final interestPriority = reel.interestPriority ?? 0.0;

    return {
      'ranking': baseRanking + 
                 (baseBoost * boostWeight) + 
                 (geoPriority * geoWeight) + 
                 (interestPriority * interestWeight),
      'boost': baseBoost,
      'geo': geoPriority,
      'interest': interestPriority,
      'base_ranking': baseRanking,
    };
  }

  // ===================================================================
  // 🔹 MÉTODOS DEPRECATED
  // ===================================================================
  @Deprecated('Supabase calcula ranking. Reservado para futura lógica cliente.')
  double _calculateEngagementScore(ReelModel reel) {
    final likes = (reel.likesCount ?? 0).toDouble();
    final comments = (reel.commentsCount ?? 0).toDouble();
    final loQuiero = (reel.loQuieroCount ?? 0).toDouble();
    final ageInHours = DateTime.now().difference(reel.createdAt ?? DateTime.now()).inHours;
    final timeDecay = 1 / (1 + (ageInHours / 24));
    return ((likes * 2) + (comments * 3) + (loQuiero * 5)) * timeDecay;
  }

  @Deprecated('Supabase calcula ranking. Reservado para futura lógica cliente.')
  double _recencyScore(DateTime? createdAt) {
    if (createdAt == null) return 0.2;
    final hoursAgo = DateTime.now().difference(createdAt).inHours;
    if (hoursAgo < 1) return 1.0;
    if (hoursAgo < 6) return 0.8;
    if (hoursAgo < 24) return 0.6;
    if (hoursAgo < 72) return 0.4;
    return 0.2;
  }

  // ===================================================================
  // 🔹 APLICAR RANKING
  // ===================================================================
  List<ReelFeedItem> _applyRanking(List<ReelFeedItem> reels) {
    return reels..sort((a, b) {
      final rankingDiff = b.calculatedRankingScore.compareTo(a.calculatedRankingScore);
      if (rankingDiff != 0) return rankingDiff;
      
      final boostDiff = b.calculatedBoostScore.compareTo(a.calculatedBoostScore);
      if (boostDiff != 0) return boostDiff;
      
      return (b.reel.createdAt ?? DateTime(0)).compareTo(a.reel.createdAt ?? DateTime(0));
    });
  }

  // ===================================================================
  // 🔹 REFRESH FEED (INVALIDA CACHE PRIMERO)
  // ===================================================================
  Future<List<FeedItem>?> refreshFeed({
    required String userId,
    List<String>? excludeIds,
    String? userLocation,
    List<String>? userInterests,
  }) async {
    if (kDebugMode) Get.log('🔄 [ENGINE] refreshFeed llamado');
    
    // 🆕 INVALIDAR CACHE ESPECÍFICO ANTES DE FETCH
    final cacheKey = _generateCacheKey(userId, userLocation, userInterests, null, null);
    _cachedFeeds.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
    
    final freshFeed = await getFeed(
      userId: userId,
      limit: 20,
      lastScore: null,
      lastId: null,
      userLocation: userLocation,
      userInterests: userInterests,
    );

    if (freshFeed == null) return null;

    if (excludeIds != null && excludeIds.isNotEmpty) {
      return freshFeed.where((item) {
        if (item is ReelFeedItem) {
          return !excludeIds.contains(item.id);
        }
        return true;
      }).toList();
    }
    return freshFeed;
  }

  // ===================================================================
  // 🔹 TRACKING DE IMPRESSIONS
  // ===================================================================
  void trackImpression(FeedItem item, int position, Duration viewTime, {required String userId}) {
    if (kDebugMode) {
      Get.log('📊 Impression: ${item.id} @ pos $position durante ${viewTime.inSeconds}s');
    }
    if (item is ReelFeedItem) {
      _engagement.trackView(item.reel.id, userId);
    }
  }

  // ===================================================================
  // 🔹 ACTUALIZAR PESOS DEL ALGORITMO
  // ===================================================================
  void updateAlgorithmWeights({
    double? boostWeight,
    double? geoWeight,
    double? interestWeight,
    double? engagementWeight,
    double? recencyWeight,
  }) {
    this.boostWeight = boostWeight ?? this.boostWeight;
    this.geoWeight = geoWeight ?? this.geoWeight;
    this.interestWeight = interestWeight ?? this.interestWeight;
    this.engagementWeight = engagementWeight ?? this.engagementWeight;
    this.recencyWeight = recencyWeight ?? this.recencyWeight;
    
    if (kDebugMode) {
      Get.log('⚙️ [ENGINE] Pesos actualizados: boost=$boostWeight, geo=$geoWeight, interest=$interestWeight');
    }
  }

  // ===================================================================
  // 🔹 MÉTRICAS DEL ENGINE
  // ===================================================================
  Map<String, dynamic> getEngineMetrics() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 
        ? (_cacheHits / totalRequests).clamp(0.0, 1.0) 
        : 0.0;
    
    return {
      'boost_weight': boostWeight,
      'geo_weight': geoWeight,
      'interest_weight': interestWeight,
      'engagement_weight': engagementWeight,
      'recency_weight': recencyWeight,
      'ad_frequency': _adInserter.adFrequency,
      'ranking_source': 'supabase_sql',
      'cache_enabled': true,
      'cache_duration_minutes': _cacheDuration.inMinutes,
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'cache_hit_rate': hitRate.toStringAsFixed(2),
      'cache_entries_count': _cachedFeeds.length,
    };
  }

  // ===================================================================
  // 🔹 CACHE DE FEEDS (OPTIMIZADO)
  // ===================================================================
  final Map<String, List<FeedItem>> _cachedFeeds = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  // 🆕 CACHE KEY INCLUYE LIMIT PARA EVITAR COLISIONES
  String _generateCacheKey(String userId, String? location, List<String>? interests, double? lastScore, String? lastId, {int limit = 20}) {
    final interestsHash = interests?.sorted().join(',').hashCode ?? 0;
    return '$userId|${location ?? ''}|$interestsHash|limit:$limit|score:${lastScore ?? 0}|id:${lastId ?? ''}';
  }

  Future<List<FeedItem>?> getCachedFeed({
    required String userId,
    int limit = 20,
    double? lastScore,
    String? lastId,
    String? userLocation,
    List<String>? userInterests,
    int offset = 0,
  }) async {
    // 🆕 Pasar limit al cache key
    final cacheKey = _generateCacheKey(userId, userLocation, userInterests, lastScore, lastId, limit: limit);
    
    if (_cachedFeeds.containsKey(cacheKey) &&
        _cacheTimestamps.containsKey(cacheKey) &&
        DateTime.now().difference(_cacheTimestamps[cacheKey]!) < _cacheDuration) {
      if (kDebugMode) Get.log('🗃️ CACHE HIT: $cacheKey');
      _cacheHits++;
      return _cachedFeeds[cacheKey]!;
    }

    if (kDebugMode) Get.log('🔄 CACHE MISS: $cacheKey');
    _cacheMisses++;
    
    final freshFeed = await getFeed(
      userId: userId,
      limit: limit,
      lastScore: lastScore,
      lastId: lastId,
      userLocation: userLocation,
      userInterests: userInterests,
    );
    
    // 🆕 Solo cachear si no es null (error)
    if (freshFeed != null) {
      _cachedFeeds[cacheKey] = freshFeed;
      _cacheTimestamps[cacheKey] = DateTime.now();
      _pruneCacheLRU(userId);
    }
    
    return freshFeed;
  }

  // 🆕 PRUNE CON LRU SIMPLE (respeta cadenas de cursor)
  void _pruneCacheLRU(String userId) {
    final userEntries = _cacheTimestamps.entries
        .where((e) => e.key.startsWith('$userId|'))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Más reciente primero
    
    // 🆕 Mantener máximo 5 entradas por usuario (LRU) para permitir cadenas de cursor
    const maxCachePerUser = 5;
    if (userEntries.length > maxCachePerUser) {
      for (var i = maxCachePerUser; i < userEntries.length; i++) {
        final keyToRemove = userEntries[i].key;
        _cachedFeeds.remove(keyToRemove);
        _cacheTimestamps.remove(keyToRemove);
        if (kDebugMode) Get.log('🧹 Cache LRU prune: $keyToRemove');
      }
    }
  }

  void invalidateCache([String? userId, String? userLocation, List<String>? userInterests]) {
    if (userId == null) {
      _cachedFeeds.clear();
      _cacheTimestamps.clear();
      if (kDebugMode) Get.log('🗑️ Caché de feed invalidada (global)');
    } else {
      final keysToRemove = _cachedFeeds.keys.where((key) => key.startsWith('$userId|')).toList();
      for (final key in keysToRemove) {
        _cachedFeeds.remove(key);
        _cacheTimestamps.remove(key);
      }
      if (kDebugMode) Get.log('🗑️ Caché invalidada para usuario: $userId (${keysToRemove.length} páginas)');
    }
  }

  void invalidateCacheOnUserAction(String userId) {
    invalidateCache(userId);
    if (kDebugMode) Get.log('♻️ Cache invalidado por acción de usuario: $userId');
  }

  // ===================================================================
  // 🔹 UTILS
  // ===================================================================
  void resetCacheMetrics() {
    _cacheHits = 0;
    _cacheMisses = 0;
    if (kDebugMode) Get.log('📊 Métricas de cache reseteadas');
  }
}

// ===================================================================
// 🔹 EXTENSIONES UTILITARIAS
// ===================================================================
extension SortedExtension<T extends Comparable<T>> on List<T> {
  List<T> sorted() => this..sort();
}