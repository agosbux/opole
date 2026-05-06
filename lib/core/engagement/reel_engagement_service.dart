// lib/core/engagement/reel_engagement_service.dart
// ===================================================================
// REEL ENGAGEMENT SERVICE - Buffer + tracking inteligente de interacciones
// ===================================================================
// • ✅ FUENTE DE VERDAD: SupabaseApi (métodos, validación, retry)
// • ✅ Buffer de eventos para minimizar llamadas a Supabase
// • ✅ Flush periódico + manual para garantizar entrega
// • ✅ Validación de IDs centralizada vía SupabaseApi._isTemp
// • ✅ Datos sin prefijo 'p_': la API layer hace el mapeo al RPC
// • ✅ Error handling simplificado: confía en _rpcWithRetry de la API
// ===================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:opole/core/supabase/supabase_api.dart';

enum EngagementEvent {
  view,
  watch_3s,
  watch_10s,
  complete_watch,
  like,
  lo_quiero,
  share,
  comment,
  replay,
  retention,
  impression,
}

class _EngagementEvent {
  final String reelId;
  final String userId;
  final EngagementEvent event;
  final Duration? watchTime;
  final double? retentionPercent;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  _EngagementEvent({
    required this.reelId,
    required this.userId,
    required this.event,
    this.watchTime,
    this.retentionPercent,
    this.metadata,
    required this.timestamp,
  });
}

class ReelEngagementService extends GetxService {
  static ReelEngagementService get instance => Get.find<ReelEngagementService>();

  // ✅ FUENTE DE VERDAD: Usamos la instancia de SupabaseApi
  final SupabaseApi _api = SupabaseApi.instance;
  final List<_EngagementEvent> _eventBuffer = [];
  
  // ⚙️ Configuración del Buffer
  static const int _bufferThreshold = 8;
  static const Duration _flushInterval = Duration(seconds: 30);
  static const int _maxBufferRetry = 20;
  
  bool _isFlushing = false;
  Timer? _flushTimer;

  @override
  void onInit() {
    super.onInit();
    _flushTimer = Timer.periodic(_flushInterval, (_) => flushNow());
  }

  // ===================================================================
  // 🔹 TRACKING PRINCIPAL - Validación centralizada vía SupabaseApi
  // ===================================================================
  void track({
    required String reelId,
    required String userId,
    required EngagementEvent event,
    Duration? watchTime,
    double? retentionPercent,
    Map<String, dynamic>? metadata,
  }) {
    // ✅ VALIDACIÓN CENTRALIZADA: Usamos el helper de SupabaseApi
    if (SupabaseApi.isTemp(reelId) || SupabaseApi.isTemp(userId)) {
      if (kDebugMode) Get.log('⚠️ [ENGAGEMENT] ID temporal ignorado: reel=$reelId, user=$userId');
      return;
    }

    // ✅ Clamp de retención a rango válido 0.0 - 1.0
    final safeRetention = retentionPercent != null 
        ? math.max(0.0, math.min(1.0, retentionPercent)) 
        : null;

    // ✅ FIX: Límite de buffer - si está lleno, descartar evento más antiguo (FIFO)
    if (_eventBuffer.length >= _maxBufferRetry) {
      if (kDebugMode) Get.log('⚠️ [ENGAGEMENT] Buffer lleno ($_maxBufferRetry), descartando evento más antiguo');
      _eventBuffer.removeAt(0);
    }

    _eventBuffer.add(_EngagementEvent(
      reelId: reelId,
      userId: userId,
      event: event,
      watchTime: watchTime,
      retentionPercent: safeRetention,
      metadata: metadata,
      timestamp: DateTime.now(),
    ));
    
    // Flush inmediato si llegamos al límite
    if (_eventBuffer.length >= _bufferThreshold && !_isFlushing) {
      unawaited(_flushEvents());
    }
  }

  // ===================================================================
  // 🔹 FLUSH DE EVENTOS - Sincronizado con SupabaseApi
  // ===================================================================
  Future<void> _flushEvents() async {
    if (_isFlushing || _eventBuffer.isEmpty) return;
    
    _isFlushing = true;
    final eventsToSend = List<_EngagementEvent>.from(_eventBuffer);
    _eventBuffer.clear();
    
    try {
      for (final event in eventsToSend) {
        // ✅ DATOS SIN PREFIJO 'p_': SupabaseApi.trackEngagement hace el mapeo interno
        final Map<String, dynamic> data = {
          'user_id': event.userId,
          'reel_id': event.reelId,
          'action': event.event.name,
          'watch_time_seconds': event.watchTime?.inSeconds ?? 0,
          'retention_percent': event.retentionPercent ?? 0.0,
        };

        // ✅ Metadata aplanada para campos extra del trigger SQL
        if (event.metadata != null && event.metadata!.isNotEmpty) {
          data.addAll(event.metadata!);
        }

        // ✅ CORRECCIÓN PRINCIPAL: método que SÍ existe en SupabaseApi
        // _rpcWithRetry se encarga de: timeout, retry, y manejo de PostgrestException
        await _api.trackEngagement(data);
      }
      
      if (kDebugMode) {
        Get.log('🚀 [ENGAGEMENT] Flushed ${eventsToSend.length} events OK');
      }
      
    } catch (e, stack) {
      // ✅ Simplificado: _rpcWithRetry ya maneja retries de red
      // Solo logueamos errores inesperados para diagnóstico
      if (kDebugMode) {
        Get.log('❌ [ENGAGEMENT] Error inesperado: $e');
        Get.log('🔍 Stack: $stack');
      }
      // No reintentamos manualmente: la API layer ya lo hizo si era transitorio
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> flushNow() async {
    if (_eventBuffer.isNotEmpty && !_isFlushing) {
      await _flushEvents();
    }
  }

  // ===================================================================
  // 🔹 MÉTODOS PÚBLICOS DE TRACKING (API amigable)
  // ===================================================================

  void trackView(String reelId, String userId) => 
      track(reelId: reelId, userId: userId, event: EngagementEvent.view);

  void trackWatchProgress(String reelId, String userId, Duration progress) {
    if (progress.inSeconds >= 10) {
      track(reelId: reelId, userId: userId, event: EngagementEvent.watch_10s, watchTime: progress);
    } else if (progress.inSeconds >= 3) {
      track(reelId: reelId, userId: userId, event: EngagementEvent.watch_3s, watchTime: progress);
    }
  }

  void trackCompleteWatch(String reelId, String userId, Duration totalWatchTime) => 
      track(reelId: reelId, userId: userId, event: EngagementEvent.complete_watch, watchTime: totalWatchTime);

  void trackLoQuiero(String reelId, String userId) => 
      track(reelId: reelId, userId: userId, event: EngagementEvent.lo_quiero);

  void trackLike(String reelId, String userId) => 
      track(reelId: reelId, userId: userId, event: EngagementEvent.like);

  void trackShare(String reelId, String userId) => 
      track(reelId: reelId, userId: userId, event: EngagementEvent.share);

  void trackComment(String reelId, String userId) => 
      track(reelId: reelId, userId: userId, event: EngagementEvent.comment);

  void trackReplay(String reelId, String userId) => 
      track(reelId: reelId, userId: userId, event: EngagementEvent.replay);

  void trackRetention(String reelId, String userId, double percent, int watchSeconds) {
    track(
      reelId: reelId, 
      userId: userId, 
      event: EngagementEvent.retention,
      watchTime: Duration(seconds: watchSeconds),
      retentionPercent: percent,
    );
    if (kDebugMode) {
      Get.log('📊 [RETENTION] Reel: $reelId | User: $userId | ${(percent * 100).toStringAsFixed(1)}% | ${watchSeconds}s');
    }
  }

  void trackImpression(String reelId, String userId, {Duration? watchTime, int? position}) {
    track(
      reelId: reelId, 
      userId: userId, 
      event: EngagementEvent.impression,
      watchTime: watchTime,
      metadata: position != null ? {'position': position} : null,
    );
  }

  // ===================================================================
  // 🔹 LIFECYCLE & CLEANUP
  // ===================================================================

  @override
  void onClose() {
    _flushTimer?.cancel();
    flushNow(); // ✅ Garantiza envío de eventos pendientes
    super.onClose();
  }
}