// lib/core/feed/feed_playback_coordinator.dart
// ✅ Controla reproducción, prioridad, anti-spam y retry
// ✅ Generación-aware: cancela ops asíncronas obsoletas
// ✅ Zero acoplamiento: callbacks inyectados + contexto dinámico
// ✅ Interface abstracta para testing crítico

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:opole/core/video/video_controller_pool.dart';

import 'feed_execution_context.dart';

abstract class IPlaybackCoordinator {
  Future<void> onPageChanged(FeedExecutionContext ctx);
  Future<void> pauseAll();
  void resumeActive();
  void dispose();
}

class FeedPlaybackCoordinator implements IPlaybackCoordinator {
  FeedPlaybackCoordinator({
    required this.contextProvider,
    required this.pool,
    required this.getVideoUrl,
  });

  final FeedExecutionContext Function() contextProvider;
  final VideoControllerPool pool;
  final String? Function(int index) getVideoUrl;

  String? _lastPlayingUrl;
  Timer? _retryTimer;
  int _lastProcessedGen = 0;

  @override
  Future<void> onPageChanged(FeedExecutionContext ctx) async {
    // 🛡️ Guard de generación: si cambió durante el async, abortar
    if (ctx.generation != contextProvider().generation) return;
    _lastProcessedGen = ctx.generation;

    if (ctx.isUserPaused) {
      await pauseAll();
      return;
    }

    final url = getVideoUrl(ctx.currentIndex);
    if (url == null || url.isEmpty) return;

    await _enforcePlayback(url, ctx);
  }

  Future<void> _enforcePlayback(String url, FeedExecutionContext ctx) async {
    if (ctx.generation != _lastProcessedGen) return;

    // 🔍 Anti-spam: verificar estado real antes de disparar play
    final ctrl = pool.getSync(url);
    if (ctrl?.value.isPlaying == true) {
      _lastPlayingUrl = url;
      return;
    }

    // ▶️ Play inmediato
    unawaited(pool.play(url).catchError(_logPlaybackError));
    _lastPlayingUrl = url;

    // 🔁 Retry conservador si no está bufferizado/inicializado
    if (!pool.isBuffered(url) && ctrl?.value.isInitialized != true) {
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(milliseconds: 180), () async {
        final currentCtx = contextProvider();
        if (currentCtx.generation != _lastProcessedGen) return;
        if (currentCtx.isUserPaused) return;
        if (pool.getSync(url)?.value.isPlaying == true) return;
        
        unawaited(pool.play(url).catchError(_logPlaybackError));
      });
    }

    // ⏸️ Pausar ventanas no prioritarias (anti-flicker)
    _pauseNonPrioritized(url, ctx.currentIndex);
  }

  void _pauseNonPrioritized(String activeUrl, int activeIndex) {
    // Ventana de prioridad: ±2 items alrededor del activo
    final priorityUrls = <String>{};
    for (int i = -2; i <= 2; i++) {
      final url = getVideoUrl(activeIndex + i);
      if (url != null) priorityUrls.add(url);
    }

    // Pausar activos fuera de ventana (evita consumo de CPU/batería)
    final activeKeys = pool.activeControllerKeys.toSet();
    for (final url in activeKeys) {
      if (!priorityUrls.contains(url) && url != activeUrl) {
        unawaited(pool.pause(url).catchError(_logPlaybackError));
      }
    }
  }

  @override
  Future<void> pauseAll() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    _lastPlayingUrl = null;
    unawaited(pool.pauseAll().catchError(_logPlaybackError));
  }

  @override
  void resumeActive() {
    final ctx = contextProvider();
    if (ctx.isUserPaused) return;
    
    final url = getVideoUrl(ctx.currentIndex);
    if (url != null && url != _lastPlayingUrl) {
      unawaited(pool.play(url).catchError(_logPlaybackError));
      _lastPlayingUrl = url;
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _logPlaybackError(dynamic e, StackTrace st) {
    if (kDebugMode) debugPrint('❌ [PLAYBACK] $e\n$st');
  }
}