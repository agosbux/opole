// lib/core/feed/feed_state_updater.dart
// ✅ Responsable exclusivo de mutaciones
// ✅ O(1) lookup + cache sync
// ✅ Anti-race PERMISIVO en mutaciones (fix like intermitente)
// ✅ Trim seguro (anti-salto visual)
// ✅ FIX #1: ELIMINADOS TODOS los feedItems.refresh() redundantes
// ✅ FIX #2: Anti-race permite diferencias de generación ≤ 2 (acciones de usuario)

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:opole/core/feed/feed_config.dart';
import 'package:opole/core/feed/feed_item_model.dart';
import 'package:opole/core/supabase/models/reel_model.dart';

import 'feed_execution_context.dart';

class FeedStateUpdater {
  FeedStateUpdater({
    required this.feedItems,
    required this.contextProvider,
  });

  final RxList<FeedItem> feedItems;
  final FeedExecutionContext Function() contextProvider;
  final Map<String, int> _reelIndexCache = {};

  int get _generation => contextProvider().generation;

  void rebuildIndex() {
    _reelIndexCache.clear();
    for (int i = 0; i < feedItems.length; i++) {
      final item = feedItems[i];
      if (item is ReelFeedItem) _reelIndexCache[item.reel.id] = i;
    }
  }

  ReelModel? getReelById(String reelId) {
    final idx = _reelIndexCache[reelId];
    if (idx == null || idx < 0 || idx >= feedItems.length) return null;
    final item = feedItems[idx];
    return item is ReelFeedItem ? item.reel : null;
  }

  void applyBatch(List<FeedItem> newItems, {required bool isRefresh}) {
    if (isRefresh) {
      feedItems.assignAll(newItems);
    } else {
      feedItems.addAll(newItems);
    }
    rebuildIndex();
  }

  void trimIfNeeded(int currentIndex) {
    if (feedItems.length > FeedConfig.maxMemoryItems) {
      if (currentIndex > FeedConfig.trimCount * 2) {
        feedItems.removeRange(0, FeedConfig.trimCount);
        rebuildIndex();
      }
    }
  }

  // 🔥 FIX #2: Anti-race permisivo para acciones del usuario
  void updateItem({
    required String reelId,
    required ReelModel Function(ReelModel current) transformer,
    required int expectedGeneration,
  }) {
    // Permitir actualizaciones si la diferencia de generación es ≤ 2
    // Esto asegura que likes, shares, etc. se procesen incluso si hubo
    // un scroll mínimo o refresh reciente.
    if (_generation - expectedGeneration > 2) return;
    
    final idx = _reelIndexCache[reelId];
    if (idx == null || idx < 0 || idx >= feedItems.length) return;

    final item = feedItems[idx];
    if (item is! ReelFeedItem) return;

    feedItems[idx] = item.copyWith(reel: transformer(item.reel));
  }

  void removeItem(String reelId, {required int expectedGeneration}) {
    if (_generation - expectedGeneration > 2) return;
    final idx = _reelIndexCache[reelId];
    if (idx == null) return;

    feedItems.removeAt(idx);
    rebuildIndex();
  }

  void clear() {
    feedItems.clear();
    _reelIndexCache.clear();
  }
}