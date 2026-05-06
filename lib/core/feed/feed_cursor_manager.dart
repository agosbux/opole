// lib/core/feed/feed_cursor_manager.dart
// ✅ Estado de paginación aislado
// ✅ Seguro ante nulos, reseteable

class FeedCursorManager {
  double? _lastScore;
  String? _lastId;

  bool get isEmpty => _lastId == null;

  void reset() {
    _lastScore = null;
    _lastId = null;
  }

  void updateFrom({required double? score, required String? id}) {
    _lastScore = score;
    _lastId = id;
  }

  ({double? score, String? id}) get cursor => (score: _lastScore, id: _lastId);
}