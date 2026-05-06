// lib/core/video/video_preload_manager.dart
// ===================================================================
// VIDEO PRELOAD MANAGER v4.15 – DIRECTIONAL CANCEL + SHARED ENUM
// ===================================================================
// ✅ FIX #1: Importar UserEngagementMode desde archivo compartido
// ✅ FIX #2: Eliminar definición local del enum
// ✅ FIX #3: Tipado explícito en _trimQueue para toKeep (List<_PreloadTask>)
// ✅ Mantiene: micro-pipeline 32ms, skip intent, burst freeze, memory adaptation, 
//    aging incremental, shuffle priority-aware, O(1) lookup, directional cancel
// ===================================================================
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:collection/collection.dart';
import 'package:opole/core/video/video_controller_pool.dart';
import '../models/user_engagement_mode.dart'; // 🔥 FIX #1: Enum compartido

// ===================================================================
// ✅ TASK CON SCORE SEMI-ESTÁTICO + AGING INCREMENTAL
// ===================================================================
class _PreloadTask {
  final String url;
  final int priority;
  final int relativeDistance;
  final bool isForward;
  final bool isClusterHead;
  final int _createdAtMs;
  final int baseScore;
  bool cancelled = false;
  
  _PreloadTask(this.url, this.priority, {
    this.relativeDistance = 99, 
    this.isForward = true,
    this.isClusterHead = false,
    int? createdAtMs,
    int? baseScore,
  }) : _createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch,
       baseScore = baseScore ?? _computeBaseScore(priority, relativeDistance, isClusterHead, createdAtMs ?? DateTime.now().millisecondsSinceEpoch);
  
  static int _computeBaseScore(int priority, int distance, bool isClusterHead, int createdAtMs) {
    int base = priority * 10 + distance.abs() - (isClusterHead ? 5 : 0);
    final ageMs = DateTime.now().millisecondsSinceEpoch - createdAtMs;
    return base + (ageMs ~/ 500);
  }
  
  int getEffectiveScore(int nowMs) {
    final additionalAgeSec = (nowMs - _createdAtMs) ~/ 1000;
    return baseScore - additionalAgeSec;
  }
}

class VideoPreloadManager {
  VideoPreloadManager._();
  static final VideoPreloadManager instance = VideoPreloadManager._();
  
  static const int _maxQueueSize = 20;
  static const int _maxPreloadedVideos = 5;
  static const int _criticalPriorityThreshold = 3;
  static const Duration _baseCancelCooldown = Duration(milliseconds: 800);
  
  double _scrollVelocity = 0.0;
  int _lastIndex = 0;
  DateTime _lastUpdate = DateTime.now();
  
  static const double _velocitySmoothFactor = 0.8;
  static const double _velocityMin = -0.1;
  static const double _velocityMax = 0.1;
  
  static final math.Random _rng = math.Random();
  
  double _directionConfidence = 0.0;
  int _consistentDirectionCount = 0;
  static const double _confidenceDecay = 0.95;
  static const double _confidenceBoost = 0.1;
  static const double _confidenceThreshold = 0.3;
  
  static const int _basePredictionHorizonMs = 300;
  
  UserEngagementMode _engagementMode = UserEngagementMode.engaged;
  
  static const int _minPriority = 1;
  static const int _maxPriority = 15;
  
  final VideoControllerPool _pool = VideoControllerPool.instance;
  final Connectivity _connectivity = Connectivity();
  
  Timer? _preloadTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  ConnectivityResult _currentConnection = ConnectivityResult.none;
  
  final LinkedHashMap<String, bool> _preloadedUrls = LinkedHashMap();
  final Set<String> _activePreloads = {};
  
  final Map<String, _PreloadTask> _taskIndex = {};
  
  int _nowMs = DateTime.now().millisecondsSinceEpoch;
  
  final PriorityQueue<_PreloadTask> _queue = PriorityQueue<_PreloadTask>(
    (a, b) => b.baseScore.compareTo(a.baseScore),
  );
  
  int _runningPreloads = 0;
  void _incRunning() => _runningPreloads++;
  void _decRunning() { if (_runningPreloads > 0) _runningPreloads--; }
  
  bool _disposed = false;
  
  final Map<String, DateTime> _cancelledUrls = {};
  static const Duration _cancelTTL = Duration(seconds: 30);

  final List<int> _sessionDepths = [];
  int _currentSessionDepth = 0;
  double _averageSessionDepth = 3.0;
  Duration _totalWatchTime = Duration.zero;
  int _totalVideosWatched = 0;
  double _averageWatchTimeSec = 15.0;
  
  static const int _frameBudgetBaseMs = 4;
  
  double? _externalEngagementScore;
  String? _currentVideoUrl;
  
  // 🔥 OPT #5: Cache para evitar recálculo frecuente de ventana
  int _lastWindow = 4;
  int _lastWindowCalcMs = 0;
  
  // 🔥 OPT #1: Flag para loop proactivo
  bool _preloadLoopActive = false;

  Future<void> init() async {
    await _updateConnectionType();
    WidgetsBinding.instance.addObserver(_LifecycleObserver(_pool));
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result.isNotEmpty) {
        _currentConnection = result.first;
        if (kDebugMode) Get.log('📡 [PRELOAD] Conexión: $_currentConnection');
      }
    });
    
    // 🔥 OPT #1: Iniciar micro-pipeline continuo (32ms ≈ 30fps de decisión)
    _startPreloadLoop();
  }
  
  // 🔥 OPT #1: Loop proactivo para ejecución constante sin micro-latencias
  void _startPreloadLoop() {
    if (_preloadLoopActive) return;
    _preloadLoopActive = true;
    
    _preloadTimer?.cancel();
    _preloadTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (_disposed) return;
      if (_queue.isEmpty) return;
      if (_runningPreloads >= _dynamicMaxConcurrent) return;
      
      _drainQueue();
    });
    
    if (kDebugMode) Get.log('⚡ [PRELOAD] Micro-pipeline iniciado (32ms tick)');
  }

  Future<void> _updateConnectionType() async {
    final result = await _connectivity.checkConnectivity();
    if (result.isNotEmpty) _currentConnection = result.first;
  }

  // ===================================================================
  // 🔥 Helpers + OPTIMIZACIONES
  // ===================================================================
  
  void _refreshNow() {
    _nowMs = DateTime.now().millisecondsSinceEpoch;
  }
  
  bool get _isModerateScroll => _scrollSpeed > 0.015 && _scrollSpeed <= 0.03;
  
  // 🔥 OPT #2: Detección de intención de salto (skip intent)
  bool get _isUserSkipping {
    return _scrollSpeed > 0.04 && _averageWatchTimeSec < 4;
  }
  
  // 🔥 OPT #4: Nivel de presión de memoria basado en estado del pool
  int get _memoryPressureLevel {
    final active = _pool.activeCount;
    final total = _pool.totalCount;
    
    if (total > 15 || active > 8) return 2;  // Alta presión
    if (total > 10 || active > 5) return 1;  // Media presión
    return 0;  // Normal
  }
  
  void _reheapIfNeeded() {
    if (_queue.isEmpty) return;
    
    final hasOldTasks = _queue.toList().any((t) => (_nowMs - t._createdAtMs) > 3000);
    if (!hasOldTasks) return;
    
    final tasks = _queue.toList().where((t) => !t.cancelled).toList()
      ..sort((a, b) => b.getEffectiveScore(_nowMs).compareTo(a.getEffectiveScore(_nowMs)));
    
    _queue..clear()..addAll(tasks);
    
    if (kDebugMode) Get.log('🔄 [PRELOAD] Selective reheap: ${tasks.length} tasks');
  }

  // ===================================================================
  // 🔥 SCROLL METRICS + PREDICTION + FREEZE LOGIC
  // ===================================================================
  
  void updateScrollMetrics(int currentIndex) {
    _refreshNow();
    
    final now = DateTime.now();
    final dt = now.difference(_lastUpdate).inMilliseconds;
    
    final rawVelocity = (dt > 0 && _lastIndex != 0) 
        ? (currentIndex - _lastIndex) / dt 
        : 0.0;
    
    final clampedVelocity = rawVelocity.clamp(_velocityMin, _velocityMax);
    _scrollVelocity = _velocitySmoothFactor * _scrollVelocity + (1 - _velocitySmoothFactor) * clampedVelocity;
    
    final prevDirection = _lastIndex != currentIndex ? (_lastIndex - currentIndex).sign : 0;
    final currDirection = (currentIndex - _lastIndex).sign;
    
    if (prevDirection != 0 && currDirection != 0 && prevDirection != currDirection) {
      _directionConfidence = (_directionConfidence * 0.5).clamp(0.0, 1.0);
      _consistentDirectionCount = 0;
    } else if (currDirection != 0) {
      _consistentDirectionCount++;
      _directionConfidence = (_directionConfidence + _confidenceBoost).clamp(0.0, 1.0);
    } else {
      _directionConfidence *= _confidenceDecay;
    }
    
    final prevIndex = _lastIndex;
    _lastIndex = currentIndex;
    _lastUpdate = now;
    
    if (currentIndex > prevIndex) _currentSessionDepth++;
    
    _updateEngagementMode();
    _cleanupCancelledUrls();
    
    // 🔥 OPT #3: Freeze agresivo en scroll burst (cancela activos lejanos)
    _handleScrollBurstFreeze();
    
    if (kDebugMode && _scrollVelocity.abs() > 0.01) {
      Get.log('📊 [PRELOAD] V:${_scrollVelocity.toStringAsFixed(4)} | DC:${_directionConfidence.toStringAsFixed(2)} | M:$_engagementMode | P:${_predictedIndex} | Skip:${_isUserSkipping}');
    }
  }
  
  // 🔥 OPT #3: Cancela preloads activos lejanos durante scroll extremo
  void _handleScrollBurstFreeze() {
    if (!_isScrollBurst) return;
    
    final toCancel = <String>[];
    
    for (final url in _activePreloads.toList()) {
      final dist = _pool.getUrlDistance(url);
      if (dist != null && dist.abs() > 1) {
        toCancel.add(url);
      }
    }
    
    for (final url in toCancel) {
      _cancelPreload(url);
      _pool.cancel(url);
      _cancelledUrls[url] = DateTime.now();
    }
    
    if (toCancel.isNotEmpty && kDebugMode) {
      Get.log('🛑 [PRELOAD] Burst freeze: ${toCancel.length} activos cancelados (dist > 1)');
    }
  }
  
  int get _dynamicPredictionHorizon {
    final watchComponent = _averageWatchTimeSec * _averageWatchTimeSec * 2;
    final watchBasedHorizon = (200 + watchComponent).clamp(200, 600).toInt();
    
    if (_isScrollBurst) return 150;
    if (_isFastScroll) return (250 * 0.8).round();
    if (_engagementMode == UserEngagementMode.exploring) return (400 * 1.2).round();
    
    return watchBasedHorizon;
  }
  
  int get _predictedIndex {
    final predictedOffset = (_scrollVelocity * _dynamicPredictionHorizon).round();
    final speedFactor = (_scrollSpeed * 20).clamp(0.0, 2.0);
    final forwardBias = (_scrollDirection > 0) ? speedFactor.round() : 0;
    
    return (_lastIndex + predictedOffset + forwardBias).clamp(0, _lastIndex + 10);
  }
  
  void _updateEngagementMode() {
    final speed = _scrollSpeed;
    if (speed > 0.03) {
      _engagementMode = UserEngagementMode.bored;
    } else if (speed < 0.01) {
      _engagementMode = UserEngagementMode.exploring;
    } else {
      _engagementMode = UserEngagementMode.engaged;
    }
  }
  
  void _cleanupCancelledUrls() {
    final now = DateTime.now();
    _cancelledUrls.removeWhere((_, timestamp) => now.difference(timestamp) > _cancelTTL);
  }
  
  void setEngagementMode(UserEngagementMode mode) { _engagementMode = mode; }
  
  void setEngagementScore(double score) {
    _externalEngagementScore = score.clamp(0.0, 1.0);
    if (kDebugMode) Get.log('🧠 [PRELOAD] Engagement score: ${_externalEngagementScore!.toStringAsFixed(2)}');
  }
  
  void setCurrentVideoUrl(String? url) {
    _currentVideoUrl = url;
    if (kDebugMode) Get.log('🎯 [PRELOAD] Current video: ${url ?? "none"}');
  }
  
  void recordVideoWatched(String url, Duration watchTime) {
    _totalVideosWatched++;
    _totalWatchTime += watchTime;
    _averageWatchTimeSec = _totalWatchTime.inSeconds / _totalVideosWatched;
    
    if (_currentSessionDepth > 0) {
      _sessionDepths.add(_currentSessionDepth);
      if (_sessionDepths.length > 20) _sessionDepths.removeAt(0);
      _averageSessionDepth = _sessionDepths.reduce((a, b) => a + b) / _sessionDepths.length;
      
      _pool.setAverageSessionDepth(_averageSessionDepth);
      _currentSessionDepth = 0;
    }
    
    if (kDebugMode) {
      Get.log('🧠 [PRELOAD] Session: avgDepth=${_averageSessionDepth.toStringAsFixed(1)}, avgWatch=${_averageWatchTimeSec.toStringAsFixed(1)}s');
    }
  }
  
  int get _scrollDirection => _scrollVelocity == 0 ? 0 : _scrollVelocity.sign.toInt();
  double get _scrollSpeed => _scrollVelocity.abs();
  bool get _isFastScroll => _scrollSpeed > 0.03;
  bool get _isScrollBurst => _scrollSpeed > 0.05;
  double get directionConfidence => _directionConfidence;

  // ===================================================================
  // 🔥 CONFIG DINÁMICA + OPTIMIZACIONES
  // ===================================================================
  
  int get _dynamicFrameBudget {
    if (_isScrollBurst) return 2;
    if (_isFastScroll) return 3;
    return _frameBudgetBaseMs;
  }
  
  int get _dynamicMaxConcurrent {
    // 🔥 OPT #4: Adaptación por presión de memoria
    if (_memoryPressureLevel == 2) return 1;
    
    switch (_engagementMode) {
      case UserEngagementMode.bored: return 1;
      case UserEngagementMode.exploring:
        return _currentConnection == ConnectivityResult.wifi ? 4 : 2;
      case UserEngagementMode.engaged:
      default:
        switch (_currentConnection) {
          case ConnectivityResult.wifi: return 3;
          case ConnectivityResult.mobile:
          case ConnectivityResult.ethernet: return 2;
          default: return 1;
        }
    }
  }
  
  Duration get _dynamicCooldown {
    switch (_engagementMode) {
      case UserEngagementMode.bored: return const Duration(milliseconds: 200);
      case UserEngagementMode.exploring: return const Duration(milliseconds: 600);
      case UserEngagementMode.engaged:
      default:
        if (_isFastScroll) return const Duration(milliseconds: 300);
        if (_isModerateScroll) return const Duration(milliseconds: 500);
        return _baseCancelCooldown;
    }
  }
  
  // 🔥 OPT #5: Cache de cálculo para evitar CPU churn
  int get _dynamicPreloadWindow {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 🔥 OPT #5: Evitar recálculo si no pasaron 100ms
    if (now - _lastWindowCalcMs < 100) return _lastWindow;
    _lastWindowCalcMs = now;
    
    int baseWindow;
    
    if (_totalVideosWatched < 3) {
      baseWindow = 6;
    } else {
      switch (_engagementMode) {
        case UserEngagementMode.bored: baseWindow = 2; break;
        case UserEngagementMode.exploring: baseWindow = 8; break;
        case UserEngagementMode.engaged:
        default:
          baseWindow = _isFastScroll ? 2 : (_isModerateScroll ? 4 : 6);
      }
    }
    
    if (_averageWatchTimeSec < 5) {
      baseWindow = (baseWindow - 2).clamp(2, 8);
    }
    
    final poolHitRate = _pool.preloadHitRate;
    final totalChecks = _pool.preloadHits + _pool.preloadMisses;
    
    if (totalChecks >= 10) {
      if (poolHitRate < 60 && baseWindow < 10) {
        baseWindow += 2;
      } else if (poolHitRate > 85 && baseWindow > 3) {
        baseWindow -= 1;
      }
    }
    
    if (_averageSessionDepth < 3) {
      baseWindow = baseWindow.clamp(2, 4);
    }
    
    if (_directionConfidence < _confidenceThreshold) {
      baseWindow = (baseWindow - 1).clamp(2, 8);
    }
    
    if (_externalEngagementScore != null) {
      if (_externalEngagementScore! < 0.3) {
        baseWindow = (baseWindow - 1).clamp(2, 8);
      } else if (_externalEngagementScore! > 0.8) {
        baseWindow = (baseWindow + 1).clamp(2, 8);
      }
    }
    
    // 🔥 OPT #4: Reducir ventana bajo presión de memoria
    if (_memoryPressureLevel > 0) {
      baseWindow = (baseWindow - 1).clamp(2, 6);
    }
    
    // Smoothing para evitar jitter
    final newWindow = baseWindow.clamp(2, 8);
    _lastWindow = (_lastWindow * 0.7 + newWindow * 0.3).round();
    return _lastWindow;
  }
  
  int get _dynamicMaxReleasedCache {
    // 🔥 OPT #4: Más agresivo bajo presión de memoria
    if (_memoryPressureLevel >= 2) return 0;
    return _engagementMode == UserEngagementMode.exploring ? 1 : 2;
  }
  
  bool _shouldPreloadDirection(bool isForward) {
    if (_directionConfidence < _confidenceThreshold && isForward && _scrollDirection > 0) {
      return _rng.nextDouble() < 0.3;
    }
    
    switch (_engagementMode) {
      case UserEngagementMode.bored:
        return isForward == (_scrollDirection > 0);
      case UserEngagementMode.exploring:
        return true;
      case UserEngagementMode.engaged:
      default:
        return isForward || (isForward == false && _scrollDirection <= 0);
    }
  }

  // ===================================================================
  // ✅ API PÚBLICA + OPTIMIZACIONES
  // ===================================================================
  
  void enqueue(String url, {int priority = 10, int? currentIndex, int? targetIndex}) {
    if (_disposed || url.isEmpty) return;
    if (_isScrollBurst) {
      if (kDebugMode) Get.log('🚫 [PRELOAD] Burst skip: $url');
      return;
    }
    
    _refreshNow();
    
    final predicted = _predictedIndex;
    final futureDistance = (targetIndex != null) ? (targetIndex - predicted) : 99;
    final distance = futureDistance.abs();
    final isForward = futureDistance >= 0;
    
    if (!_shouldPreloadDirection(isForward)) return;
    if (distance > _dynamicPreloadWindow) return;
    
    int effectivePriority = (distance == 1) ? _minPriority : priority.clamp(_minPriority, _maxPriority);
    
    if (_externalEngagementScore != null) {
      effectivePriority = (effectivePriority - (_externalEngagementScore! * 3).round()).clamp(_minPriority, _maxPriority);
    }
    
    if (url == _currentVideoUrl) {
      effectivePriority = (effectivePriority - 2).clamp(_minPriority, _maxPriority);
    }
    
    if (_directionConfidence < _confidenceThreshold && isForward && _scrollDirection > 0) {
      effectivePriority = (effectivePriority + 2).clamp(_minPriority, _maxPriority);
    }
    
    if (isForward && _scrollDirection > 0 && _directionConfidence > 0.5) {
      effectivePriority = (effectivePriority - 2).clamp(_minPriority, _maxPriority);
    }
    
    // 🔥 OPT #2: Bajar prioridad si detectamos skip intent
    if (_isUserSkipping) {
      effectivePriority = (effectivePriority + 3).clamp(_minPriority, _maxPriority);
      if (kDebugMode) Get.log('⏭️ [PRELOAD] Skip intent: $url (priority +3)');
    }
    
    _enqueuePreload(url, effectivePriority, relativeDistance: futureDistance, isForward: isForward);
  }

  void enqueueCluster(List<String> urls, {int startIndex = 0, int? currentIndex}) {
    if (_disposed || urls.isEmpty) return;
    if (_isScrollBurst) return;
    
    _refreshNow();
    
    const basePriority = 10;
    final predicted = _predictedIndex;
    
    for (int i = 0; i < urls.length && i < 3; i++) {
      final url = urls[i];
      final targetIndex = startIndex + i;
      final futureDistance = targetIndex - predicted;
      final distance = futureDistance.abs();
      
      if (distance > _dynamicPreloadWindow) break;
      
      final isForward = futureDistance >= 0;
      final isClusterHead = (i == 0);
      
      int effectivePriority = isClusterHead 
          ? _minPriority 
          : (distance == 1 ? _minPriority + 1 : basePriority.clamp(_minPriority, _maxPriority));
      
      if (_externalEngagementScore != null) {
        effectivePriority = (effectivePriority - (_externalEngagementScore! * 3).round()).clamp(_minPriority, _maxPriority);
      }
      
      if (url == _currentVideoUrl) {
        effectivePriority = (effectivePriority - 2).clamp(_minPriority, _maxPriority);
      }
      
      if (_directionConfidence < _confidenceThreshold && isForward && _scrollDirection > 0) {
        effectivePriority = (effectivePriority + 2).clamp(_minPriority, _maxPriority);
      }
      
      if (isForward && _scrollDirection > 0 && _directionConfidence > 0.5) {
        effectivePriority = (effectivePriority - 2).clamp(_minPriority, _maxPriority);
      }
      
      // 🔥 OPT #2: Skip intent en clusters
      if (_isUserSkipping) {
        effectivePriority = (effectivePriority + 3).clamp(_minPriority, _maxPriority);
      }
      
      _enqueuePreload(url, effectivePriority, relativeDistance: futureDistance, isForward: isForward, isClusterHead: isClusterHead);
    }
    
    if (kDebugMode) Get.log('🔗 [PRELOAD] Cluster: ${urls.length} items (pred: $predicted, skip: $_isUserSkipping)');
  }

  void cancel(String url) {
    if (_disposed) return;
    _cancelPreload(url);
    _pool.cancel(url);
    _cancelledUrls[url] = DateTime.now();
  }
  
  void updateDistances(int currentIndex, List<String> urls) {
    if (_disposed) return;
    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      final relativeDistance = i - currentIndex;
      _pool.setUrlDistance(url, relativeDistance);
    }
  }
  
  void cancelFarPreloads({required int currentIndex, int maxDistance = 2}) {
    if (_disposed) return;
    
    _refreshNow();
    
    final toCancel = <String>[];
    
    for (final url in _activePreloads) {
      final dist = _pool.getUrlDistance(url);
      if (dist != null && dist.abs() > maxDistance) toCancel.add(url);
    }
    
    final queueToCancel = <_PreloadTask>[];
    for (final task in _queue.toList()) {
      if (task.relativeDistance.abs() > maxDistance) queueToCancel.add(task);
    }
    for (final task in queueToCancel) {
      task.cancelled = true;
      _taskIndex.remove(task.url);
      toCancel.add(task.url);
    }
    
    for (final url in toCancel) {
      _cancelPreload(url);
      _pool.cancel(url);
      _cancelledUrls[url] = DateTime.now();
    }
    
    if (toCancel.isNotEmpty && kDebugMode) {
      Get.log('🚨 [PRELOAD] Abandonment cancel: ${toCancel.length} items');
    }
  }

  // ===================================================================
  // 🔥 FIX #3: Cancelación REALMENTE direccional (forward ≠ backward)
  // ===================================================================
  List<String> cancelDirectional({
    required int currentIndex,
    required int forwardDistance,
    required int backwardDistance,
  }) {
    if (_disposed) return [];
    _refreshNow();
    final cancelled = <String>[];
    
    // ✅ Cancelar activos con distancias direccionales
    for (final url in _activePreloads.toList()) {
      final dist = _pool.getUrlDistance(url);
      if (dist == null) continue;
      if ((dist > 0 && dist > forwardDistance) || (dist < 0 && dist.abs() > backwardDistance)) {
        cancelled.add(url);
      }
    }
    
    // ✅ Cancelar en cola con distancias direccionales
    final queueToCancel = <_PreloadTask>[];
    for (final task in _queue.toList()) {
      if ((task.relativeDistance > 0 && task.relativeDistance > forwardDistance) ||
          (task.relativeDistance < 0 && task.relativeDistance.abs() > backwardDistance)) {
        queueToCancel.add(task);
      }
    }
    for (final task in queueToCancel) {
      task.cancelled = true;
      _taskIndex.remove(task.url);
      cancelled.add(task.url);
    }
    
    // ✅ Ejecutar cancelación
    for (final url in cancelled) {
      _cancelPreload(url);
      _pool.cancel(url);
      _cancelledUrls[url] = DateTime.now();
    }
    
    if (cancelled.isNotEmpty && kDebugMode) {
      Get.log('🛑 [PRELOAD] Directional cancel: fwd>$forwardDistance, bwd>$backwardDistance → ${cancelled.length} items');
    }
    return cancelled; // 🔥 Retornar URLs para budget inmediato
  }

  // ===================================================================
  // ✅ LÓGICA INTERNA + OPTIMIZACIONES
  // ===================================================================
  
  void _enqueuePreload(String url, int priority, {int relativeDistance = 99, bool isForward = true, bool isClusterHead = false}) {
    if (_disposed) return;
    if (_activePreloads.contains(url) || _pool.isActive(url)) return;
    
    final lastCancel = _cancelledUrls[url];
    if (lastCancel != null && DateTime.now().difference(lastCancel) < _dynamicCooldown) return;
    
    final existing = _taskIndex[url];
    if (existing != null) {
      if (existing.cancelled) {
        _taskIndex.remove(url);
      } else if (priority < existing.priority) {
        existing.cancelled = true;
        _taskIndex.remove(url);
      } else {
        return;
      }
    }
    
    if (_queue.length >= _maxQueueSize) {
      _compactQueueIfNeeded();
    }
    
    _refreshNow();
    
    final baseScore = _PreloadTask._computeBaseScore(priority, relativeDistance, isClusterHead, _nowMs);
    final task = _PreloadTask(url, priority, relativeDistance: relativeDistance, isForward: isForward, isClusterHead: isClusterHead, createdAtMs: _nowMs, baseScore: baseScore);
    
    _queue.add(task);
    _taskIndex[url] = task;
    
    // 🔥 OPT #1: El loop proactivo se encarga de drenar, pero forzamos un ciclo si está vacío
    if (_runningPreloads < _dynamicMaxConcurrent) {
      _drainQueue();
    }
  }

  void _compactQueueIfNeeded() {
    final cancelledCount = _queue.toList().where((t) => t.cancelled).length;
    if (cancelledCount < 5) return;
    
    final nowMs = _nowMs;
    final cleaned = _queue.toList().where((t) => !t.cancelled).toList()
      ..sort((a, b) => b.getEffectiveScore(nowMs).compareTo(a.getEffectiveScore(nowMs)));
    
    _queue..clear()..addAll(cleaned.take(_maxQueueSize));
    
    _taskIndex
      ..clear()
      ..addEntries(cleaned.take(_maxQueueSize).map((t) => MapEntry(t.url, t)));
    
    if (kDebugMode) {
      Get.log('🧹 [PRELOAD] Queue compacted: removed $cancelledCount cancelled tasks');
    }
  }

  void _trimQueue() {
    if (_queue.isEmpty) return;
    
    _refreshNow();
    _reheapIfNeeded();
    
    final nowMs = _nowMs;
    final validTasks = _queue.toList().where((t) => !t.cancelled).toList()
      ..sort((a, b) => b.getEffectiveScore(nowMs).compareTo(a.getEffectiveScore(nowMs)));
    
    final protected = validTasks.where((t) => 
      t.priority <= _criticalPriorityThreshold || 
      t.relativeDistance.abs() <= 2 ||
      (t.isForward == (_scrollDirection > 0) && _engagementMode != UserEngagementMode.exploring)
    ).toList();
    
    final rest = validTasks.where((t) => !protected.contains(t)).toList();
    final window = _dynamicPreloadWindow;
    final remainingSlots = (window ~/ 2).clamp(3, window) - protected.length;
    
    // 🔥 FIX #3: Tipado explícito para evitar error de inferencia de tipos
    final List<_PreloadTask> toKeep = remainingSlots > 0 
        ? rest.take(remainingSlots).toList() 
        : <_PreloadTask>[];
    
    _queue..clear()..addAll(protected)..addAll(toKeep);
    
    _taskIndex
      ..clear()
      ..addEntries(_queue.toList().where((t) => !t.cancelled).map((t) => MapEntry(t.url, t)));
  }

  void _drainQueue() {
    if (_disposed) return;
    if (_runningPreloads >= _dynamicMaxConcurrent) return;
    
    // 🔥 OPT #1: El loop proactivo ya maneja el timing, solo procesamos si hay capacidad
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
        Future.microtask(_drainQueueInternal);
        return;
      }
      _drainQueueInternal();
    });
  }
  
  void _drainQueueInternal() {
    final frameStart = DateTime.now();
    final frameBudget = _dynamicFrameBudget;
    
    _refreshNow();
    _reheapIfNeeded();
    
    int nowMs = _nowMs;
    
    // 🔥 FIX #2: Shuffle priority-aware para fairness
    if (_queue.length > 5 && _rng.nextDouble() < 0.2) {
      final tasks = _queue.toList();
      final highPriority = tasks.where((t) => t.priority <= _criticalPriorityThreshold).toList();
      final lowPriority = tasks.where((t) => t.priority > _criticalPriorityThreshold).toList()..shuffle(_rng);
      
      _queue
        ..clear()
        ..addAll(highPriority)
        ..addAll(lowPriority);
      
      if (kDebugMode) Get.log('🔀 [PRELOAD] Priority-aware shuffle: high=${highPriority.length}, low=${lowPriority.length}');
    }
    
    int processed = 0;
    const maxPerCycle = 3;
    
    while (
      _runningPreloads < _dynamicMaxConcurrent && 
      _queue.isNotEmpty && 
      processed < maxPerCycle
    ) {
      processed++;
      
      final elapsed = DateTime.now().difference(frameStart).inMilliseconds;
      if (elapsed >= frameBudget) {
        Future.delayed(const Duration(milliseconds: 16), _drainQueue);
        break;
      }
      
      final task = _queue.removeFirst();
      
      if (task.cancelled) {
        _taskIndex.remove(task.url);
        continue;
      }
      
      _taskIndex.remove(task.url);
      
      if (_activePreloads.contains(task.url) || _pool.isActive(task.url)) continue;
      
      _activePreloads.add(task.url);
      _incRunning();

      final absDist = task.relativeDistance.abs();
      final schedulerPriority = absDist <= 2 ? Priority.animation : (absDist <= 5 ? Priority.touch : Priority.idle);

      SchedulerBinding.instance.scheduleTask(() async {
        try {
          if (_disposed) return;
          
          if (_runningPreloads > 2) {
            await Future.delayed(const Duration(milliseconds: 16));
          }
          
          await _safePreload(task);
          if (!_disposed) _updateLruCache(task.url);
        } catch (e) {
          if (kDebugMode) Get.log('⚠️ [PRELOAD] Error: $e');
          if (!_disposed) _preloadedUrls.remove(task.url);
        } finally {
          if (!_disposed) {
            _decRunning();
            _activePreloads.remove(task.url);
            
            if (_queue.isNotEmpty && _runningPreloads < _dynamicMaxConcurrent) {
              _drainQueue();
            }
          }
        }
      }, schedulerPriority);
      
      if (_queue.length % 5 == 0) {
        _refreshNow();
        nowMs = _nowMs;
      }
    }
  }

  Future<void> _safePreload(_PreloadTask task) async {
    try {
      final lowBandwidth = _currentConnection != ConnectivityResult.wifi;
      
      await _pool.preloadCritical(
        task.url, 
        priority: task.priority, 
        relativeDistance: task.relativeDistance,
        maxReleasedCache: _dynamicMaxReleasedCache,
        lowBandwidth: lowBandwidth,
        isClusterHead: task.isClusterHead,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        Get.log('❌ [PRELOAD] Failed: ${task.url} | Error: $e');
        Get.log('📋 Stack: $stack');
      }
    }
  }

  void _cancelPreload(String url) {
    _taskIndex.remove(url);
    
    for (final task in _queue.toList()) { 
      if (task.url == url) {
        task.cancelled = true;
        break;
      }
    }
    
    if (_activePreloads.remove(url)) _preloadedUrls.remove(url);
  }

  void _updateLruCache(String url) {
    if (_preloadedUrls.containsKey(url)) {
      _preloadedUrls.remove(url);
    } else {
      if (_preloadedUrls.length >= _maxPreloadedVideos) {
        final oldest = _preloadedUrls.keys.first;
        _preloadedUrls.remove(oldest);
      }
    }
    _preloadedUrls[url] = true;
  }

  String _shortenUrl(String url) => url.length > 40 ? '${url.substring(0, 40)}...' : url;

  // ===================================================================
  // ✅ MÉTODOS DE CONSULTA + MÉTRICAS
  // ===================================================================
  
  bool isPreloaded(String videoUrl) => _preloadedUrls.containsKey(videoUrl);
  bool isActive(String url) => _activePreloads.contains(url);
  bool isQueued(String url) => _taskIndex.containsKey(url);
  bool isVideoActiveInPool(String url) => _pool.isActive(url);
  
  double get scrollVelocity => _scrollVelocity;
  int get scrollDirection => _scrollDirection;
  double get scrollSpeed => _scrollSpeed;
  bool get isFastScroll => _isFastScroll;
  bool get isScrollBurst => _isScrollBurst;
  bool get isUserSkipping => _isUserSkipping;  // 🔥 OPT #2 expuesto
  int get predictedIndex => _predictedIndex;
  int get dynamicPredictionHorizon => _dynamicPredictionHorizon;
  UserEngagementMode get engagementMode => _engagementMode;
  int get dynamicPreloadWindow => _dynamicPreloadWindow;
  Duration get dynamicCooldown => _dynamicCooldown;
  int get dynamicMaxReleasedCache => _dynamicMaxReleasedCache;
  int get dynamicFrameBudget => _dynamicFrameBudget;
  int get memoryPressureLevel => _memoryPressureLevel;  // 🔥 OPT #4 expuesto
  double get averageSessionDepth => _averageSessionDepth;
  double get averageWatchTimeSec => _averageWatchTimeSec;
  double? get externalEngagementScore => _externalEngagementScore;
  String? get currentVideoUrl => _currentVideoUrl;
  
  int get activeCount => _activePreloads.length;
  int get runningCount => _runningPreloads;
  int get queuedCount => _queue.length;
  
  int get poolPreloadHits => _pool.preloadHits;
  int get poolPreloadMisses => _pool.preloadMisses;
  double get poolPreloadHitRate => _pool.preloadHitRate;

  Map<String, dynamic> getStats() => {
        'preloaded_count': _preloadedUrls.length,
        'active_preloads': _activePreloads.length,
        'queued_preloads': _queue.length,
        'running_preloads': _runningPreloads,
        'max_concurrent': _dynamicMaxConcurrent,
        'max_queue_size': _maxQueueSize,
        'critical_threshold': _criticalPriorityThreshold,
        'scroll_velocity': _scrollVelocity.toStringAsFixed(4),
        'scroll_direction': _scrollDirection,
        'scroll_speed': _scrollSpeed.toStringAsFixed(4),
        'predicted_index': _predictedIndex,
        'dynamic_prediction_horizon_ms': _dynamicPredictionHorizon,
        'direction_confidence': _directionConfidence.toStringAsFixed(2),
        'is_scroll_burst': _isScrollBurst,
        'is_user_skipping': _isUserSkipping,  // 🔥 OPT #2
        'engagement_mode': _engagementMode.toString(),
        'dynamic_window': _dynamicPreloadWindow,
        'dynamic_window_smoothed': _lastWindow,
        'dynamic_window_cached': _lastWindowCalcMs,  // 🔥 OPT #5
        'dynamic_cooldown_ms': _dynamicCooldown.inMilliseconds,
        'dynamic_max_released_cache': _dynamicMaxReleasedCache,
        'dynamic_frame_budget_ms': _dynamicFrameBudget,
        'memory_pressure_level': _memoryPressureLevel,  // 🔥 OPT #4
        'pool_preload_hits': _pool.preloadHits,
        'pool_preload_misses': _pool.preloadMisses,
        'pool_preload_hit_rate': _pool.preloadHitRate.toStringAsFixed(1),
        'average_session_depth': _averageSessionDepth.toStringAsFixed(1),
        'average_watch_time_sec': _averageWatchTimeSec.toStringAsFixed(1),
        'external_engagement_score': _externalEngagementScore?.toStringAsFixed(2),
        'current_video_url': _currentVideoUrl,
        'cancelled_urls_ttl_count': _cancelledUrls.length,
        'connection': _currentConnection.toString(),
        'pool_active': _pool.activeCount,
        'pool_total': _pool.totalCount,
        'task_index_size': _taskIndex.length,
        'queue_compacted': _queue.length < _maxQueueSize,
        'preload_loop_active': _preloadLoopActive,  // 🔥 OPT #1
        'base_score_enabled': true,
        'effective_score_aging': true,
        'priority_aware_shuffle': true,
        'predicted_index_clamped': true,
        'window_smoothing_enabled': true,
        'content_stickiness_enabled': true,
        'skip_intent_detection_enabled': true,  // 🔥 OPT #2
        'burst_freeze_enabled': true,  // 🔥 OPT #3
        'memory_adaptation_enabled': true,  // 🔥 OPT #4
        'window_cache_enabled': true,  // 🔥 OPT #5
        'directional_cancel_enabled': true,  // 🔥 FIX #3
      };

  Future<void> reset() async {
    _preloadTimer?.cancel();
    _preloadLoopActive = false;
    _queue.clear();
    _taskIndex.clear();
    _cancelledUrls.clear();
    _scrollVelocity = 0.0;
    _lastIndex = 0;
    _lastWindow = 4;
    _lastWindowCalcMs = 0;
    for (final url in _activePreloads.toList()) _cancelPreload(url);
    _preloadedUrls.clear();
  }

  Future<void> dispose() async {
    _disposed = true;
    _preloadLoopActive = false;
    WidgetsBinding.instance.removeObserver(_LifecycleObserver(_pool));
    _preloadTimer?.cancel();
    await _connectivitySubscription?.cancel();
    _queue.clear();
    _taskIndex.clear();
    _cancelledUrls.clear();
    for (final url in _activePreloads.toList()) _cancelPreload(url);
    _preloadedUrls.clear();
  }
}

// ===================================================================
// 🔥 Lifecycle observer para memory-aware cleanup
// ===================================================================
class _LifecycleObserver extends WidgetsBindingObserver {
  final VideoControllerPool _pool;
  _LifecycleObserver(this._pool);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        unawaited(_pool.cleanupMemory());
        if (kDebugMode) print('🧹 [POOL] Memory cleanup on lifecycle: $state');
        break;
      default: break;
    }
  }
}