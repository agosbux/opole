// lib/core/feed/preload_budget_tracker.dart
// ===================================================================
// PRELOAD BUDGET TRACKER v1.0 – REAL-TIME BYTE TRACKING
// ===================================================================
// ✅ Conectado 100% al lifecycle del pool (zero estimación)
// ✅ Thread-safe para callbacks asíncronos
// ✅ Hard cap enforcement + alerts para telemetría
// ✅ Zero dependencias de UI, tracker puro
// ===================================================================

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:get/get.dart';
import '../video/video_controller_pool.dart'; // PoolLifecycleListener

class PreloadBudgetTracker {
  PreloadBudgetTracker._();
  static final PreloadBudgetTracker instance = PreloadBudgetTracker._();
  
  // 🔥 Estado interno
  double _currentBytes = 0;
  double _peakBytes = 0;
  int _hardCapHits = 0;
  
  // 🔥 Configuración
  static const int _hardCapWifi = 50 * 1024 * 1024; // 50MB
  static const int _hardCapMobile = 15 * 1024 * 1024; // 15MB
  static const int _alertThreshold = 80; // % del hard cap para alertar
  
  bool _isWifi = true;
  bool _initialized = false;
  
  // 🔥 Callback opcional para notificar cuando se excede el threshold
  void Function(double current, double max)? onThresholdExceeded;
  
  // ===================================================================
  // 🔥 Inicialización + suscripción al lifecycle del pool
  // ===================================================================
  Future<void> init({required bool isWifi}) async {
    if (_initialized) return;
    
    _isWifi = isWifi;
    
    // 🔥 Suscribirse al lifecycle REAL del pool
    VideoControllerPool.instance.subscribeToLifecycle(_onPoolLifecycle);
    
    _initialized = true;
    if (kDebugMode) {
      Get.log('💰 [BUDGET] Initialized: WiFi=$_isWifi, cap=${_hardCap}');
    }
  }
  
  // 🔥 Actualizar tipo de red en runtime (ej: WiFi → Mobile)
  void updateConnectionType(bool isWifi) {
    _isWifi = isWifi;
    // Si cambiamos a mobile y estamos sobre el nuevo cap, forzar alerta
    if (!_isWifi && _currentBytes > _hardCapMobile) {
      _notifyThresholdExceeded();
    }
  }
  
  int get _hardCap => _isWifi ? _hardCapWifi : _hardCapMobile;
  
  // ===================================================================
  // 🔥 Lifecycle handler REAL (conectado al pool)
  // ===================================================================
  void _onPoolLifecycle({
    required String url,
    required bool created,
    required bool cacheHit,
    required int? sizeBytes,
  }) {
    // 🔥 Solo procesar si tenemos tamaño real (no estimado)
    if (sizeBytes == null) return;
    
    // 🔥 Cache hits no consumen budget adicional (ya estaban descargados)
    if (cacheHit) return;
    
    if (created) {
      // 🔥 Controller creado → sumar al budget
      _currentBytes += sizeBytes;
      if (_currentBytes > _peakBytes) {
        _peakBytes = _currentBytes;
      }
      
      // 🔥 Verificar hard cap y threshold de alerta
      _checkLimits();
      
      if (kDebugMode) {
        Get.log('💰 [BUDGET] +${(sizeBytes/1024/1024).toStringAsFixed(2)}MB → ${currentMB.toStringAsFixed(2)}MB / ${hardCapMB.toStringAsFixed(0)}MB');
      }
    } else {
      // 🔥 Controller disposed/cancelled → restar del budget
      _currentBytes -= sizeBytes;
      if (_currentBytes < 0) _currentBytes = 0; // Safety net
      
      if (kDebugMode) {
        Get.log('💰 [BUDGET] -${(sizeBytes/1024/1024).toStringAsFixed(2)}MB → ${currentMB.toStringAsFixed(2)}MB / ${hardCapMB.toStringAsFixed(0)}MB');
      }
    }
  }
  
  // 🔥 Verificar límites y notificar si es necesario
  void _checkLimits() {
    // 🔥 Hard cap enforcement
    if (_currentBytes > _hardCap) {
      _hardCapHits++;
      _currentBytes = _hardCap.toDouble(); // Clamp al hard cap
      if (kDebugMode) {
        Get.log('🛑 [BUDGET] HARD CAP HIT: ${_hardCapHits} times');
      }
    }
    
    // 🔥 Alert threshold (80% del cap)
    final threshold = _hardCap * (_alertThreshold / 100);
    if (_currentBytes >= threshold && onThresholdExceeded != null) {
      _notifyThresholdExceeded();
    }
  }
  
  void _notifyThresholdExceeded() {
    if (onThresholdExceeded != null) {
      onThresholdExceeded!(_currentBytes, _hardCap.toDouble());
    }
  }
  
  // ===================================================================
  // 🔥 Getters públicos para la policy (zero estimación)
  // ===================================================================
  double get currentBytes => _currentBytes;
  double get currentMB => _currentBytes / 1024 / 1024;
  double get hardCap => _hardCap.toDouble();
  double get hardCapMB => _hardCap / 1024 / 1024;
  double get usagePercent => (_currentBytes / _hardCap) * 100;
  double get peakBytes => _peakBytes;
  int get hardCapHits => _hardCapHits;
  
  // 🔥 Helper para policy: ¿hay budget para X bytes?
  bool hasBudgetFor(int sizeBytes) => (_currentBytes + sizeBytes) <= _hardCap;
  
  // 🔥 Helper para policy: ¿cuánto budget libre queda?
  double get remainingBytes => (_hardCap - _currentBytes).clamp(0, double.infinity);
  
  // ===================================================================
  // 🔥 Métricas para telemetría/debug
  // ===================================================================
  Map<String, dynamic> getStats() => {
    'current_mb': currentMB.toStringAsFixed(2),
    'hard_cap_mb': hardCapMB.toStringAsFixed(0),
    'usage_percent': usagePercent.toStringAsFixed(1),
    'peak_mb': (peakBytes / 1024 / 1024).toStringAsFixed(2),
    'hard_cap_hits': _hardCapHits,
    'is_wifi': _isWifi,
    'initialized': _initialized,
  };
  
  // ===================================================================
  // 🔥 Lifecycle management
  // ===================================================================
  void reset() {
    _currentBytes = 0;
    _peakBytes = 0;
    _hardCapHits = 0;
  }
  
  Future<void> dispose() async {
    VideoControllerPool.instance.unsubscribeFromLifecycle(_onPoolLifecycle);
    reset();
    _initialized = false;
    if (kDebugMode) Get.log('🧹 [BUDGET] Disposed');
  }
}