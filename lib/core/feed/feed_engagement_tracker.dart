// lib/core/feed/feed_engagement_tracker.dart
// ===================================================================
// FEED ENGAGEMENT TRACKER v2.6 – AUTO-HEALING LRU + SINGLETON + POSITIVE INTERACTION
// ===================================================================
// ✅ FIX #1: Singleton pattern para compatibilidad con FeedController
// ✅ FIX #2: Método registerPositiveInteraction para engagement tracking
// ✅ Mantiene: LRU real, replay detection, ratio clamp, skip-safe, zero UI deps

class FeedEngagementTracker {
  // 🔥 FIX #1: Singleton pattern
  FeedEngagementTracker._();
  static final FeedEngagementTracker instance = FeedEngagementTracker._();
  
  static const int _maxTracked = 200;
  static const Duration _maxWatchTimeCap = Duration(seconds: 30);
  
  final Map<String, DateTime> _startTimes = {};
  final Map<String, Duration> _accumulatedWatchTime = {};
  final Map<String, int> _viewCounts = {};
  final List<String> _lruOrder = [];

  void onVisible(String reelId) {
    _startTimes.putIfAbsent(reelId, () => DateTime.now());
    _viewCounts[reelId] = (_viewCounts[reelId] ?? 0) + 1;
    _touchLRU(reelId);
  }

  void onHidden(String reelId) {
    final start = _startTimes.remove(reelId);
    if (start == null) return;

    final duration = DateTime.now().difference(start);
    final newDuration = (_accumulatedWatchTime[reelId] ?? Duration.zero) + duration;
    
    // 🔥 Cap en acumulado para evitar engagement falso por suma infinita
    _accumulatedWatchTime[reelId] = 
        newDuration > _maxWatchTimeCap ? _maxWatchTimeCap : newDuration;
    
    _touchLRU(reelId);
    _enforceLRU();
  }

  // 🔥 FIX #2: Método para registrar interacción positiva (like/loquiero)
  void registerPositiveInteraction(String reelId) {
    // Incrementa view count y toca LRU para indicar engagement significativo
    _viewCounts[reelId] = (_viewCounts[reelId] ?? 0) + 1;
    _touchLRU(reelId);
  }

  Duration getWatchTime(String reelId) {
    // 🔥 Solo tocar LRU si el reel existe en algún mapa (evita "ghost IDs")
    if (_startTimes.containsKey(reelId) || _accumulatedWatchTime.containsKey(reelId)) {
      _touchLRU(reelId);
    }

    final start = _startTimes[reelId];
    final base = _accumulatedWatchTime[reelId] ?? Duration.zero;

    if (start != null) {
      final delta = DateTime.now().difference(start);
      // 🔥 FIX: Ternario en lugar de .clamp() para Duration (100% safe cross-SDK)
      final safeDelta = delta > _maxWatchTimeCap ? _maxWatchTimeCap : delta;
      return base + safeDelta;
    }
    return base;
  }

  double getCompletionRatio(String reelId, Duration videoDuration) {
    if (videoDuration.inMilliseconds == 0) return 0.0;
    final watchTime = getWatchTime(reelId);
    final ratio = watchTime.inMilliseconds / videoDuration.inMilliseconds;
    return ratio.clamp(0.0, 1.0);
  }

  bool isHighEngagement(String reelId, Duration videoDuration) {
    final ratio = getCompletionRatio(reelId, videoDuration);
    final views = getViewCount(reelId);
    return ratio > 0.6 || views > 1;
  }

  bool isSkippedFast(String reelId) {
    if (_startTimes.containsKey(reelId)) return false;
    return getWatchTime(reelId).inMilliseconds < 400;
  }

  int getViewCount(String reelId) => _viewCounts[reelId] ?? 0;
  
  void clear(String reelId) {
    _startTimes.remove(reelId);
    _accumulatedWatchTime.remove(reelId);
    _viewCounts.remove(reelId);
    _lruOrder.remove(reelId);
  }

  void _touchLRU(String reelId) {
    // ✅ Fast path: si ya es el más reciente, no hacer nada
    if (_lruOrder.isNotEmpty && _lruOrder.last == reelId) return;
    
    // ✅ Remover cualquier instancia previa (defensivo contra edge-cases)
    _lruOrder.remove(reelId);
    _lruOrder.add(reelId);
  }

  // 🔥 FIX #1: Auto-healing LRU – ignora IDs "fantasma" desincronizados
  void _enforceLRU() {
    while (_lruOrder.length > _maxTracked) {
      final oldest = _lruOrder.first;

      // 🔥 Protección contra desincronización: si el ID no existe en ningún mapa,
      // lo removemos del LRU y continuamos (auto-healing)
      if (!_startTimes.containsKey(oldest) &&
          !_accumulatedWatchTime.containsKey(oldest) &&
          !_viewCounts.containsKey(oldest)) {
        _lruOrder.removeAt(0);
        continue;
      }

      clear(oldest);
    }
  }

  void dispose() {
    _startTimes.clear();
    _accumulatedWatchTime.clear();
    _viewCounts.clear();
    _lruOrder.clear();
  }
}