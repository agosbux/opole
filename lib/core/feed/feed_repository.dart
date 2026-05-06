// lib/core/feed/feed_repository.dart
// ✅ Encapsula engine + cursor + dedup
// ✅ Zero estado reactivo
// ✅ Retorna datos puros
// ✅ FIX #1: Cursor seguro sin dependencias de extensions

import 'package:opole/core/feed/feed_item_model.dart';
import 'package:opole/core/feed/opole_feed_engine.dart';

import 'feed_cursor_manager.dart';
import 'feed_deduplicator.dart';

class FeedRepository {
  FeedRepository({
    required this.engine,
    required this.cursorManager,
    required this.deduplicator,
  });

  final OpoleFeedEngine engine;
  final FeedCursorManager cursorManager;
  final FeedDeduplicator deduplicator;

  Future<List<FeedItem>> fetchNextPage({
    required String? userId,
    required int limit,
    required bool refresh,
    List<String>? interests,
  }) async {
    if (refresh) cursorManager.reset();

    final cursor = cursorManager.cursor;
    final rawItems = await engine.getCachedFeed(
      userId: userId ?? '',
      limit: limit,
      lastScore: cursor.score,
      lastId: cursor.id,
      userLocation: null,
      userInterests: interests,
    );

    if (rawItems == null || rawItems.isEmpty) return [];

    final newItems = deduplicator.deduplicate(rawItems);
    if (newItems.isEmpty) return [];

    // 🔍 FIX #1: Safe standard Dart (no lastOrNull dependency)
    final reels = newItems.whereType<ReelFeedItem>();
    if (reels.isNotEmpty) {
      final lastReel = reels.last;
      cursorManager.updateFrom(
        score: lastReel.reel.rankingScore,
        id: lastReel.reel.id,
      );
    }

    return newItems;
  }

  void clearState() {
    cursorManager.reset();
    deduplicator.clear();
  }
}