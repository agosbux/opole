// lib/core/feed/feed_prediction_engine.dart
// ===================================================================
// FEED PREDICTION ENGINE v2.9 – PRODUCTION-DETERMINISTIC + SHARED ENUMS
// ===================================================================
// ✅ FIX #1: Importar UserEngagementMode y UserBrowsingMode desde archivo compartido
// ✅ FIX #2: Eliminar definiciones locales de enums
// ✅ Mantiene: Estado determinista, zero ghosts, validación de input estricta
// ===================================================================

import 'package:flutter/foundation.dart'; // 🔥 Para kDebugMode
import 'feed_preload_coordinator.dart'; // ScrollVelocity
import '../models/user_engagement_mode.dart'; // 🔥 FIX #1: Enums compartidos

class FeedPredictionEngine {
  int _consecutiveSkips = 0;
  int _consecutiveEngagements = 0;
  DateTime? _lastInteractionTime;
  
  int _lastDirection = 1;
  int _directionChanges = 0;
  DateTime? _lastDirectionChange;
  DateTime? _lastDirectionEvent;

  // 🔥 Campo para modo de engagement explícito (override externo)
  UserEngagementMode _currentEngagementMode = UserEngagementMode.engaged;

  static const _decayThreshold = Duration(seconds: 5);
  static const _directionStabilityWindow = Duration(milliseconds: 800);

  void registerSkip({
    required bool fast,
    ScrollVelocity? velocity,
  }) {
    _resetIfStale();
    
    final skipWeight = (velocity == ScrollVelocity.fast) ? 2 : 1;
    
    if (fast) {
      _consecutiveSkips += skipWeight;
      _consecutiveEngagements = 0;
    } else {
      _consecutiveSkips = 0;
      _consecutiveEngagements++;
    }
    _lastInteractionTime = DateTime.now();
  }

  void registerPositiveInteraction() {
    _resetIfStale();
    
    _consecutiveSkips = 0;
    _consecutiveEngagements++;
    _lastInteractionTime = DateTime.now();
  }

  /// 🔥 FIX #3 (v2.6): Validación estricta de input (solo 1 o -1)
  void registerDirection(int direction) {
    if (direction != 1 && direction != -1) return; // 🔥 Guard: input inválido → noop

    _resetIfStale();
    
    final now = DateTime.now();

    if (_lastDirectionEvent != null &&
        now.difference(_lastDirectionEvent!).inMilliseconds < 100) {
      return;
    }

    if (direction != _lastDirection) {
      _directionChanges++;
      _lastDirectionChange = now;
    }

    _lastDirection = direction;
    _lastDirectionEvent = now;
  }

  bool _isStale() {
    if (_lastInteractionTime == null) return true;
    return DateTime.now().difference(_lastInteractionTime!) > _decayThreshold;
  }

  /// 🔥 FIX #1 (v2.6): Limpia TODOS los campos de dirección (incluyendo timestamps)
  void _resetIfStale() {
    if (_isStale()) {
      _consecutiveSkips = 0;
      _consecutiveEngagements = 0;
      _directionChanges = 0;
      _lastDirectionChange = null; // 🔥 FIX: limpia timestamp de último cambio
      _lastDirectionEvent = null;  // 🔥 FIX: limpia timestamp de último evento
    }
  }

  bool shouldReducePreload() => !_isStale() && _consecutiveSkips >= 3;
  bool shouldAggressivePreload() => !_isStale() && _consecutiveEngagements >= 2 && _consecutiveSkips == 0;
  bool isFastBrowsing() => !_isStale() && _consecutiveSkips >= 2;
  bool isDeepReading() => !_isStale() && _consecutiveEngagements >= 3;

  /// 🔥 FIX #2 (v2.6): Cálculo limpio sin doble penalización stale
  double get directionConfidence {
    final isStaleNow = _isStale();
    if (isStaleNow) {
      _resetIfStale(); // 🔥 Limpia estado PRIMERO
    }
    // 🔥 NO aplicamos penalización stale aquí → ya está limpio, zero doble castigo

    double confidence = 1.0;

    if (_directionChanges > 0 && _lastDirectionChange != null) {
      final timeSinceChange = DateTime.now().difference(_lastDirectionChange!);
      if (timeSinceChange < _directionStabilityWindow) {
        confidence *= 0.5 + (timeSinceChange.inMilliseconds / _directionStabilityWindow.inMilliseconds) * 0.5;
      }
    }

    final cappedChanges = _directionChanges.clamp(0, 10);
    confidence *= (1.0 - (cappedChanges * 0.05)).clamp(0.5, 1.0);
    
    if (_directionChanges == 0) {
      confidence *= 1.1;
    }

    // 🔥 FIX: Sin penalización stale duplicada → estado ya está reseteado
    return confidence.clamp(0.0, 1.0);
  }

  bool shouldMaintainVelocityState(ScrollVelocity current, double velocityPx) {
    final absVel = velocityPx.abs();
    switch (current) {
      case ScrollVelocity.fast:
        return absVel >= 1.8;
      case ScrollVelocity.normal:
        return absVel >= 0.5 && absVel < 2.0;
      case ScrollVelocity.slow:
        return absVel <= 0.5;
    }
  }

  double getDynamicHitRateThresholdLow(bool isWifi) => isWifi ? 45.0 : 35.0;
  double getDynamicHitRateThresholdHigh(bool isWifi) => isWifi ? 80.0 : 70.0;

  // 🔥 FIX #1 (v2.7): Método para establecer modo de engagement externamente
  void setEngagementMode(UserEngagementMode mode) {
    _currentEngagementMode = mode;
    if (kDebugMode) print('🧠 [PREDICTION] Engagement mode set to: $mode');
  }

  // 🔥 Getter unificado: prioriza override explícito, fallback a comportamiento
  UserBrowsingMode get currentMode {
    _resetIfStale();
    
    // 🔥 Si hay modo explícito setado (y no es el default), respetarlo
    if (_currentEngagementMode != UserEngagementMode.engaged) {
      switch (_currentEngagementMode) {
        case UserEngagementMode.bored:
          return UserBrowsingMode.bored;
        case UserEngagementMode.exploring:
          return UserBrowsingMode.exploring;
        case UserEngagementMode.engaged:
          break; // Caer al fallback
      }
    }
    
    // Fallback a lógica basada en comportamiento (v2.6)
    if (isDeepReading()) return UserBrowsingMode.focused;
    if (shouldAggressivePreload()) return UserBrowsingMode.engaged;
    if (isFastBrowsing()) return UserBrowsingMode.exploring;
    if (shouldReducePreload()) return UserBrowsingMode.bored;

    return UserBrowsingMode.normal;
  }

  void reset() {
    _consecutiveSkips = 0;
    _consecutiveEngagements = 0;
    _lastInteractionTime = null;
    _lastDirection = 1;
    _directionChanges = 0;
    _lastDirectionChange = null;
    _lastDirectionEvent = null;
    _currentEngagementMode = UserEngagementMode.engaged; // 🔥 Resetear también el modo explícito
  }
  
  void dispose() => reset();
}
// 🔥 UserEngagementMode y UserBrowsingMode ahora están definidos en: lib/core/models/user_engagement_mode.dart