// lib/core/ui/image_preload_manager.dart
// ===================================================================
// IMAGE PRELOAD MANAGER - Production Safe + Coordinator Compatible
// ===================================================================
// ✅ FIX #1: Agregar init/reset/dispose/getStats para compatibilidad con Coordinator
// ✅ FIX #2: Usar consolidateHttpClientResponseBytes (no toBytes)
// ✅ FIX #3: Import dart:ui para instantiateImageCodec
// ✅ Mantiene: Cache deduplicado, batches, silent fail
// ===================================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'dart:ui' as ui; // 🔥 FIX #3: Import para instantiateImageCodec

class ImagePreloadManager {
  static final ImagePreloadManager instance = ImagePreloadManager._();
  ImagePreloadManager._();

  final Set<String> _cache = {};
  final List<String> _order = [];
  static const int _maxCacheSize = 50;
  static const int _maxConcurrent = 3;

  // 🔥 FIX #1: Métodos stub para compatibilidad con Coordinator
  Future<void> init() async {} // No-op
  Future<void> reset() async => clear();
  Future<void> dispose() async {} // No-op
  
  Map<String, dynamic> getStats() => {
    'cached_count': _cache.length,
    'cache_limit': _maxCacheSize,
    'max_concurrent': _maxConcurrent,
  };

  Future<void> preload(BuildContext context, List<String> urls) async {
    final uniqueUrls = urls.toSet().where((url) => url.isNotEmpty).toList();
    final pendingUrls = uniqueUrls.where((url) => !_cache.contains(url)).toList();
    if (pendingUrls.isEmpty) return;

    for (int i = 0; i < pendingUrls.length; i += _maxConcurrent) {
      if (!context.mounted) return;
      final batch = pendingUrls.skip(i).take(_maxConcurrent);
      final futures = batch.map((url) async {
        if (!context.mounted) return;
        if (kDebugMode) debugPrint('[ImagePreload] Preloading: $url');
        try {
          await precacheImage(NetworkImage(url), context);
          if (context.mounted) _addToCache(url);
        } catch (_) {}
      });
      await Future.wait(futures);
    }
  }

  void _addToCache(String url) {
    if (_cache.length >= _maxCacheSize) {
      final removeCount = (_maxCacheSize * 0.3).ceil();
      for (int i = 0; i < removeCount && _order.isNotEmpty; i++) {
        final oldest = _order.removeAt(0);
        _cache.remove(oldest);
      }
    }
    if (!_cache.contains(url)) { _cache.add(url); _order.add(url); }
  }

  // ===================================================================
  // 🔥 API para FeedPreloadCoordinator (sin BuildContext)
  // ===================================================================
  Future<void> preloadImage(String url, {int priority = 5, int? memCacheWidth}) async {
    if (url.isEmpty || _cache.contains(url)) return;
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        // 🔥 FIX #2: Usar consolidateHttpClientResponseBytes (no toBytes)
        final bytes = await consolidateHttpClientResponseBytes(response);
        
        // 🔥 FIX #3: Usar ui.instantiateImageCodec con signature correcta
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: memCacheWidth,
        );
        await codec.getNextFrame(); // Fuerza decodificación para entrar al cache
        _addToCache(url);
        if (kDebugMode) debugPrint('[ImagePreload] Cached: $url');
      }
      httpClient.close(force: true);
    } catch (e) {
      if (kDebugMode) debugPrint('[ImagePreload] Failed: $url - $e');
    }
  }

  void clear() { _cache.clear(); _order.clear(); }
  @visibleForTesting Set<String> get cachedUrls => Set.unmodifiable(_cache);
}