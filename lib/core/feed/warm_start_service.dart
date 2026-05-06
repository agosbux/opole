// lib/core/feed/warm_start_service.dart
// ===================================================================
// WARM START SERVICE - FASE 3.4
// ===================================================================
// ✅ Precarga los primeros N reels ANTES de que el usuario llegue al feed
// ✅ Integra VideoCacheManager (disco) + VideoControllerPool (memoria)
// ✅ Prioridad máxima: primer reel listo instantáneo
// ✅ Llamar desde splash/auth screen para instant-load
// ===================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:opole/core/video/video_cache_manager.dart';
import 'package:opole/core/video/video_controller_pool.dart';
import 'package:opole/core/supabase/models/reel_model.dart';

class WarmStartService {
  WarmStartService._();
  static final WarmStartService instance = WarmStartService._();

  bool _isWarming = false;

  /// Precargar primeros reels al disco + inicializar primer controller en memoria.
  /// [reels]: lista ordenada por ranking (primero = más probable de ver primero).
  /// [warmCount]: cuántos descargar al disco en background.
  /// [hotCount]: cuántos inicializar en el pool (memoria, listos para play).
  Future<void> warmUp({
    required List<ReelModel> reels,
    int warmCount = 4,
    int hotCount = 1,
  }) async {
    if (_isWarming || reels.isEmpty) return;
    _isWarming = true;

    if (kDebugMode) {
      print('🔥 [WARM] Starting warm-up for ${reels.length.clamp(0, warmCount)} reels');
    }

    try {
      final urls = reels.take(warmCount).map((r) => r.videoUrl).toList();

      // Paso 1: disco en paralelo para todos (sin await → background)
      final cacheOps = urls.map((url) => VideoCacheManager.instance.downloadAndCache(url));
      unawaited(Future.wait(cacheOps, eagerError: false));

      // Paso 2: pool en memoria para los primeros `hotCount` (prioridad máxima)
      // ⚠️ prewarmList retorna void → NO hacer await
      final hotUrls = urls.take(hotCount).toList();
      if (hotUrls.isNotEmpty) {
        VideoControllerPool.instance.prewarmList(hotUrls);
      }

      if (kDebugMode) {
        print('✅ [WARM] Warm-up complete: ${hotUrls.length} hot, ${urls.length} cached');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [WARM] Warm-up error: $e');
      }
    } finally {
      _isWarming = false;
    }
  }

  /// Llamar en FeedController después del primer fetch exitoso.
  /// Precarga en disco los siguientes reels sin bloquear UI.
  void backgroundCacheUrls(List<String> urls) {
    if (urls.isEmpty) return;
    for (final url in urls) {
      unawaited(VideoCacheManager.instance.downloadAndCache(url));
    }
    if (kDebugMode) {
      print('🗄️ [WARM] Background caching ${urls.length} URLs');
    }
  }
}