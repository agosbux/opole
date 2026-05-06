// lib/core/interactions/interaction_controller.dart
// ===================================================================
// INTERACTION CONTROLLER - v3.0 (ARCHITECTURE CLEAN + SSOT COMPATIBLE)
// ===================================================================
// ✅ Firma toggleLike({required String reelId}) - sin dependencia de VM
// ✅ Optimistic UI delegado al caller (FeedController es SSOT)
// ✅ Rollback opcional vía parámetros expectedLiked/expectedCount
// ✅ Lock system preservado (anti-doble-tap race condition)
// ✅ Cache de resultados con límite (anti-memory-leak)
// ✅ Puro Dart, testeable, sin dependencias de Flutter UI
// ===================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:opole/core/interactions/interaction_models.dart';
import 'package:opole/core/supabase/repositories/interaction_repository.dart';

/// Callback para notificar cambios al feed global (Single Source of Truth)
typedef OnFeedUpdate = void Function(String reelId, bool isLiked, int likesCount);

class InteractionController {
  final InteractionRepository _repository;
  final OnFeedUpdate? _onFeedUpdate;
  
  // Locks internos para prevenir race conditions por reelId
  final Map<String, bool> _pendingLocks = {};
  
  // Cache de últimos resultados con límite para evitar memory leak
  final Map<String, InteractionResult> _lastResult = {};
  static const int _maxCachedResults = 50;

  InteractionController({
    required InteractionRepository repository,
    OnFeedUpdate? onFeedUpdate,
  })  : _repository = repository,
        _onFeedUpdate = onFeedUpdate;

  /// 🔹 Toggle like con llamada a Supabase + sync con feed global
  /// 
  /// ✅ Arquitectura desacoplada:
  /// - El caller (FeedController) hace optimistic update ANTES de llamar
  /// - Este método solo ejecuta la llamada real a API
  /// - Si falla, notifica rollback opcional vía _onFeedUpdate
  /// 
  /// @param reelId ID del reel a togglear
  /// @param expectedLiked Estado anterior para rollback (opcional)
  /// @param expectedCount Conteo anterior para rollback (opcional)
  Future<void> toggleLike({
    required String reelId,
    bool? expectedLiked,   // Para rollback si falla la llamada
    int? expectedCount,    // Para rollback si falla la llamada
  }) async {
    // 🔒 Lock PRIMERO: previene doble-tap race condition
    if (_pendingLocks[reelId] == true) {
      if (kDebugMode) {
        debugPrint('⚠️ Like pending for $reelId, ignoring duplicate tap');
      }
      return;
    }
    _pendingLocks[reelId] = true;

    try {
      // ✅ Llamada REAL a Supabase RPC
      final result = await _repository.toggleLike(reelId);
      
      // ✅ Éxito: sync con feed global (estado final del server)
      _onFeedUpdate?.call(reelId, result.isLiked, result.likesCount);
      
      _lastResult[reelId] = InteractionResult.ok(result);
      _limitCachedResults();
      
      if (kDebugMode) {
        debugPrint('✅ Like synced for $reelId: ${result.isLiked} (${result.likesCount})');
      }
      
    } catch (e, stack) {
      // ❌ Fallo: rollback opcional si el caller proveyó estado anterior
      if (kDebugMode) {
        debugPrint('❌ Like failed for $reelId: $e');
        debugPrintStack(stackTrace: stack);
      }
      
      if (expectedLiked != null && expectedCount != null) {
        _onFeedUpdate?.call(reelId, expectedLiked, expectedCount);
        if (kDebugMode) {
          debugPrint('🔄 Rollback applied for $reelId: $expectedLiked ($expectedCount)');
        }
      }
      
      _lastResult[reelId] = InteractionResult.error(e.toString());
      _limitCachedResults();
    } finally {
      // 🔓 Siempre liberar lock
      _pendingLocks.remove(reelId);
    }
  }

  /// 🔹 "Lo quiero" con RPC real y manejo de errores
  Future<void> loQuiero({
    required String reelId,
    required VoidCallback onSuccess,
    Function(String error)? onError,
  }) async {
    // 🔒 Lock primero
    if (_pendingLocks[reelId] == true) return;
    _pendingLocks[reelId] = true;

    try {
      // Validación temprana de reelId (evita Null Cast Error)
      if (reelId.isEmpty) {
        throw ArgumentError('reelId cannot be empty');
      }
      
      final result = await _repository.sendLoQuiero(reelId);
      if (kDebugMode) debugPrint('✅ LoQuiero sent for $reelId: $result');
      onSuccess();
      _lastResult[reelId] = InteractionResult.ok(result);
      _limitCachedResults();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ LoQuiero failed for $reelId: $e');
      onError?.call(e.toString());
      _lastResult[reelId] = InteractionResult.error(e.toString());
      _limitCachedResults();
    } finally {
      _pendingLocks.remove(reelId);
    }
  }

  /// 🔹 Reportar contenido con RPC real
  Future<void> report({
    required String reelId,
    required String reason,
    String? details,
    String? ip,
  }) async {
    if (_pendingLocks[reelId] == true) return;
    _pendingLocks[reelId] = true;

    try {
      // Validación defensiva adicional
      if (reelId.isEmpty || reason.isEmpty) {
        throw ArgumentError('reelId and reason cannot be empty');
      }
      
      final success = await _repository.reportReel(reelId, reason, details: details, ip: ip);
      if (kDebugMode) {
        debugPrint(success 
            ? '🚩 Report sent for $reelId: $reason' 
            : '⚠️ Report rejected by server for $reelId');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Report failed for $reelId: $e');
      rethrow;
    } finally {
      _pendingLocks.remove(reelId);
    }
  }

  /// 🔹 Compartir (placeholder para share_plus)
  void share({required String reelId, required String url, String? text}) {
    if (kDebugMode) debugPrint('🔗 Share triggered for $reelId: $url');
  }

  void dispose() {
    _pendingLocks.clear();
    _lastResult.clear();
  }

  /// 🔹 Limita el crecimiento del cache de resultados (FIFO)
  void _limitCachedResults() {
    if (_lastResult.length > _maxCachedResults) {
      final keysToRemove = _lastResult.keys
          .take(_lastResult.length - _maxCachedResults)
          .toList();
      for (final key in keysToRemove) {
        _lastResult.remove(key);
      }
    }
  }

  // ===================================================================
  // TESTING HELPERS
  // ===================================================================
  @visibleForTesting
  bool isPending(String reelId) => _pendingLocks[reelId] == true;
  
  @visibleForTesting
  InteractionResult? getLastResult(String reelId) => _lastResult[reelId];
  
  @visibleForTesting
  int get pendingLocksCount => _pendingLocks.length;
  
  @visibleForTesting
  int get cachedResultsCount => _lastResult.length;
}