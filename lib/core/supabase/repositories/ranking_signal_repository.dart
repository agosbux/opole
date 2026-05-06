// lib/core/supabase/repositories/ranking_signal_repository.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opole/core/engagement/watch_time_signal.dart';

class RankingSignalRepository {
  final SupabaseClient _client;

  RankingSignalRepository(this._client);

  final List<WatchTimeSignal> _buffer = [];
  Timer? _flushTimer;

  static const int _batchSize = 10;
  static const Duration _flushInterval = Duration(seconds: 30);

  void startAutoFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
  }

  void record(WatchTimeSignal signal) {
    _buffer.add(signal);
    if (signal.skipped || _buffer.length >= _batchSize) {
      unawaited(flush());
    }
  }

  Future<void> flush() async {
    if (_buffer.isEmpty) return;

    final toSend = List<WatchTimeSignal>.from(_buffer);
    _buffer.clear();

    try {
      await _client.rpc('record_watch_signals', params: {
        'signals': toSend.map((s) => s.toJson()).toList(),
      });
    } catch (e) {
      _buffer.insertAll(0, toSend);
      if (kDebugMode) print('❌ [RANKING] Flush failed: $e');
    }
  }

  Future<void> dispose() async {
    _flushTimer?.cancel();
    await flush();
  }
}