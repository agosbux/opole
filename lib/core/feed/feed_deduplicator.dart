// lib/core/feed/feed_deduplicator.dart
// ✅ Tipado concreto para FeedItem
// ✅ Zero genéricos innecesarios, zero casts
// ✅ Preserva items no-reel (ads, loaders, etc.)

import 'package:opole/core/feed/feed_item_model.dart';

class FeedDeduplicator {
  final Set<String> _loadedIds = {};

  List<FeedItem> deduplicate(List<FeedItem> items) {
    final result = <FeedItem>[];
    for (final item in items) {
      if (item is ReelFeedItem) {
        if (!_loadedIds.contains(item.reel.id)) {
          _loadedIds.add(item.reel.id);
          result.add(item);
        }
      } else {
        result.add(item);
      }
    }
    return result;
  }

  void clear() => _loadedIds.clear();
}