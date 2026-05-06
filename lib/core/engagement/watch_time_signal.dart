// lib/core/engagement/watch_time_signal.dart
// ===================================================================
// WATCH TIME SIGNAL - FASE 4
// ===================================================================
// ✅ Modelo puro para señales de ranking
// ✅ Skip penalty integrado (watch < 1.5s = skip)
// ✅ Sin dependencias de Flutter/UI
// ✅ Serializable a JSON para Supabase RPC
// ===================================================================

class WatchTimeSignal {
  final String reelId;
  final String userId;
  final int watchMs;
  final int totalDurationMs;
  final bool skipped;
  final DateTime recordedAt;

  static const int skipThresholdMs = 1500;

  WatchTimeSignal({
    required this.reelId,
    required this.userId,
    required this.watchMs,
    required this.totalDurationMs,
  })  : skipped = watchMs < skipThresholdMs,
        recordedAt = DateTime.now();

  double get watchRatio {
    if (totalDurationMs == 0) return 0.0;
    return (watchMs / totalDurationMs).clamp(0.0, 1.0);
  }

  double get engagementScore {
    if (skipped) return -0.3;
    if (watchRatio < 0.25) return 0.0;
    if (watchRatio < 0.5) return 0.3;
    if (watchRatio < 0.75) return 0.6;
    return 1.0;
  }

  Map<String, dynamic> toJson() => {
    'reel_id': reelId,
    'user_id': userId,
    'watch_ms': watchMs,
    'total_duration_ms': totalDurationMs,
    'watch_ratio': watchRatio,
    'skipped': skipped,
    'engagement_score': engagementScore,
    'recorded_at': recordedAt.toIso8601String(),
  };

  @override
  String toString() =>
      'WatchTimeSignal($reelId, ${(watchRatio * 100).toStringAsFixed(0)}%, skipped: $skipped, score: ${engagementScore.toStringAsFixed(2)})';
}