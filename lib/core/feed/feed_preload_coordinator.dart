// lib/core/feed/feed_preload_coordinator.dart
// ===================================================================
// FEED PRELOAD COORDINATOR v3.6-fix4 – MEMORY SAFE + DEBUG LOGS
// ===================================================================
// ✅ FIX #1: Import path corregido a ../supabase/models/reel_model.dart
// ✅ FIX #2: estimatedSize como int (toInt() o literales enteros)
// ✅ FIX #3: catch blocks con sintaxis válida (no arrow syntax)
// ✅ FIX #4: Safe calls para métodos opcionales de ImagePreloadManager
// ✅ FIX #5: Logs estratégicos en kDebugMode para diagnóstico de preload
// ✅ FIX #6: Validación de mounted/context antes de enqueue para evitar work post-dispose
// ✅ FIX #7: Budget check más permisivo para evitar bloqueo prematuro de preload legítimo
// ✅ Mantiene: Budget REAL, Content-aware, UserType strategy, Zero UI deps
// ===================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'feed_prediction_engine.dart';
import 'feed_smart_preload_policy.dart';
import 'feed_engagement_tracker.dart';
import 'preload_budget_tracker.dart';
import '../video/video_preload_manager.dart';
import '../video/video_controller_pool.dart';
import '../ui/image_preload_manager.dart';
import '../supabase/models/reel_model.dart';
import '../models/user_engagement_mode.dart';

enum ScrollDirection { forward, backward }
enum ScrollVelocity { slow, normal, fast }
enum UserType { scanner, watcher, mixed, unknown }

typedef PoolLifecycleListener = void Function({
  required String url,
  required bool created,
  required bool cacheHit,
  required int? sizeBytes,
});

class FeedPreloadCoordinator {
  FeedPreloadCoordinator._();
  static final FeedPreloadCoordinator instance = FeedPreloadCoordinator._();
  
  ScrollDirection _direction = ScrollDirection.forward;
  ScrollVelocity _velocity = ScrollVelocity.normal;
  int _currentIndex = 0;
  bool _isWifi = false;
  bool _disposed = false;
  
  final PreloadBudgetTracker _budgetTracker = PreloadBudgetTracker.instance;
  final List<double> _velocitySamples = [];
  final List<int> _dwellTimeSamples = [];
  int _totalSkips = 0;
  int _totalViews = 0;
  DateTime? _lastEnqueueTime;
  
  final FeedPredictionEngine _predictionEngine = FeedPredictionEngine();
  final FeedSmartPreloadPolicy _preloadPolicy = FeedSmartPreloadPolicy();
  final FeedEngagementTracker _engagementTracker = FeedEngagementTracker.instance;
  final VideoPreloadManager _preloadManager = VideoPreloadManager.instance;
  final ImagePreloadManager _imagePreloadManager = ImagePreloadManager.instance;
  final VideoControllerPool _pool = VideoControllerPool.instance;
  final Connectivity _connectivity = Connectivity();
  
  final Map<String, ReelModel> _reelsByUrl = {};
  final Map<String, ReelModel> _reelsById = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Future<void> init() async {
    if (kDebugMode) Get.log('🧠 [COORD] init() - Inicializando v3.6-fix4');
    
    await _preloadManager.init();
    try {
      await (_imagePreloadManager as dynamic).init();
    } catch (_) {}
    await _pool.init();
    await _updateConnectionType();
    _pool.subscribeToLifecycle(_onPoolLifecycleEvent);
    await _budgetTracker.init(isWifi: _isWifi);
    _budgetTracker.onThresholdExceeded = _onBudgetThresholdExceeded;
    _preloadPolicy.setIsWifi(_isWifi);
    _pool.setIsWifi(_isWifi);
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result.isNotEmpty) {
        final newIsWifi = result.first == ConnectivityResult.wifi;
        if (newIsWifi != _isWifi) {
          if (kDebugMode) Get.log('📶 [COORD] Conexión cambiada: ${newIsWifi ? 'WiFi' : 'Mobile'}');
          updateConnectionType(newIsWifi);
        }
      }
    });
    
    _initializeSessionLearning();
    if (kDebugMode) Get.log('✅ [COORD] Inicializado correctamente');
  }
  
  void _onPoolLifecycleEvent({
    required String url,
    required bool created,
    required bool cacheHit,
    required int? sizeBytes,
  }) {
    if (kDebugMode && sizeBytes != null) {
      final mb = sizeBytes / 1024 / 1024;
      final action = created ? '+' : '-';
      Get.log('💰 [COORD] Budget ${action}${mb.toStringAsFixed(2)}MB: ${_shortenUrl(url)}');
    }
  }
  
  void _onBudgetThresholdExceeded(double current, double max) {
    if (current > max * 0.95) {
      if (kDebugMode) Get.log('⚠️ [COORD] Budget crítico: ${current.toStringAsFixed(1)}/${max.toStringAsFixed(1)}MB - Cancelando preloads lejanos');
      _preloadManager.cancelFarPreloads(currentIndex: _currentIndex, maxDistance: 1);
    }
  }
  
  void _initializeSessionLearning() {
    if (_totalViews >= 10) {
      final fastRatio = _totalSkips / _totalViews;
      if (fastRatio > 0.7) {
        _predictionEngine.setEngagementMode(UserEngagementMode.exploring);
        if (kDebugMode) Get.log('🎯 [COORD] Modo explorador detectado (skip ratio: ${fastRatio.toStringAsFixed(2)})');
      }
    }
  }
  
  void _recordScrollPattern() {
    _totalViews++;
    if (_velocity == ScrollVelocity.fast) _totalSkips++;
    if (_totalViews > 100) {
      _totalViews ~/= 2;
      _totalSkips ~/= 2;
    }
  }

  Future<void> _updateConnectionType() async {
    final result = await _connectivity.checkConnectivity();
    if (result.isNotEmpty) {
      updateConnectionType(result.first == ConnectivityResult.wifi);
    }
  }

  void updateConnectionType(bool isWifi) {
    if (_isWifi == isWifi) return;
    _isWifi = isWifi;
    _budgetTracker.updateConnectionType(_isWifi);
    _preloadPolicy.setIsWifi(_isWifi);
    _pool.setIsWifi(_isWifi);
    if (kDebugMode) Get.log('📶 [COORD] updateConnectionType: ${_isWifi ? 'WiFi' : 'Mobile'}');
  }

  PoolLifecycleListener get onPoolLifecycle => _onPoolLifecycleEvent;
  void setEngagementMode(UserEngagementMode mode) => _predictionEngine.setEngagementMode(mode);

  void onScrollUpdate({
    required int currentIndex,
    required int previousIndex,
    required double velocityPx,
    required List<String> feedItems,
    required List<String> visibleItemIds,
    required Duration? currentVideoDuration,
    required Map<String, ReelModel>? contentMetadata,
  }) {
    if (_disposed || feedItems.isEmpty) {
      if (kDebugMode && _disposed) Get.log('⚠️ [COORD] onScrollUpdate ignorado: coordinator disposed');
      return;
    }
    
    if (kDebugMode && currentIndex != _currentIndex) {
      Get.log('📄 [COORD] Scroll: $_currentIndex → $currentIndex | velocity: ${velocityPx.toStringAsFixed(2)}');
    }
    
    _currentIndex = currentIndex;
    final delta = currentIndex - previousIndex;
    if (delta != 0) {
      _direction = delta > 0 ? ScrollDirection.forward : ScrollDirection.backward;
      _predictionEngine.registerDirection(delta.sign);
    }
    _velocity = _mapToScrollVelocityWithHysteresis(velocityPx);
    _preloadManager.updateScrollMetrics(currentIndex);
    _recordScrollPattern();
    
    if (contentMetadata != null) {
      for (final reel in contentMetadata.values) _registerReelLookup(reel);
      _updateAvgResourceSize(contentMetadata.values);
    }
    
    final hitRate = _pool.getGlobalHitRate();
    final p95StartupMs = _pool.p95StartupMs;
    
    _executePreloadDecision(
      currentIndex: currentIndex,
      feedItems: feedItems,
      visibleItemIds: visibleItemIds,
      videoDuration: currentVideoDuration,
      hitRate: hitRate,
      p95StartupMs: p95StartupMs,
    );
    _executeSmartCancel(
      currentIndex: currentIndex,
      feedItems: feedItems,
      hitRate: hitRate,
    );
  }
  
  void _registerReelLookup(ReelModel reel) {
    if (reel.isVideo && reel.videoUrl != null && reel.videoUrl!.isNotEmpty) {
      _reelsByUrl[reel.videoUrl!] = reel;
    }
    if (reel.isImagePost && reel.imageUrls.isNotEmpty) {
      for (final url in reel.imageUrls) {
        if (url.isNotEmpty) _reelsByUrl[url] = reel;
      }
    }
    if (reel.thumbnailUrl != null && reel.thumbnailUrl!.isNotEmpty) {
      _reelsByUrl[reel.thumbnailUrl!] = reel;
    }
    _reelsById[reel.id] = reel;
  }
  
  void _updateAvgResourceSize(Iterable<ReelModel> reels) {
    final sizes = reels.map((r) => r.isVideo ? (4 * 1024 * 1024) : (1200 * 1024));
    if (sizes.isNotEmpty) {
      final avg = sizes.reduce((a, b) => a + b) / sizes.length;
      _avgResourceSizeBytes = _avgResourceSizeBytes * 0.8 + avg * 0.2;
    }
  }

  void onReelVisible({
    required String reelId,
    required String videoUrl,
    required Duration? videoDuration,
  }) {
    if (_disposed) return;
    _engagementTracker.onVisible(reelId);
    _preloadManager.setCurrentVideoUrl(videoUrl);
    if (kDebugMode) Get.log('👁️ [COORD] Reel visible: $reelId');
  }

  void onReelHidden({
    required String reelId,
    required String videoUrl,
    required Duration? videoDuration,
  }) {
    if (_disposed) return;
    _engagementTracker.onHidden(reelId);
    if (videoDuration != null) {
      final isHigh = _engagementTracker.isHighEngagement(reelId, videoDuration);
      final isSkipped = _engagementTracker.isSkippedFast(reelId);
      if (isSkipped) {
        _predictionEngine.registerSkip(fast: true, velocity: _velocity);
        if (kDebugMode) Get.log('⏭️ [COORD] Skip registrado: $reelId');
      } else if (isHigh) {
        _predictionEngine.registerPositiveInteraction();
        if (kDebugMode) Get.log('❤️ [COORD] High engagement: $reelId');
      }
    }
    if (_preloadManager.currentVideoUrl == videoUrl) {
      _preloadManager.setCurrentVideoUrl(null);
    }
  }
  
  void registerReel(ReelModel reel) {
    _registerReelLookup(reel);
    _updateAvgResourceSize([reel]);
    if (kDebugMode) Get.log('📦 [COORD] Reel registrado: ${reel.id}');
  }
  
  ReelModel? _getReelByUrl(String url) => _reelsByUrl[url];
  ReelModel? _getReelById(String id) => _reelsById[id];
  ReelModel? _getReel(String identifier) => _getReelByUrl(identifier) ?? _getReelById(identifier);
  
  UserType _classifyUserType() {
    if (_velocitySamples.length < 5) return UserType.unknown;
    final avgVelocity = _velocitySamples.reduce((a, b) => a + b) / _velocitySamples.length;
    final avgDwell = _dwellTimeSamples.isNotEmpty 
        ? _dwellTimeSamples.reduce((a, b) => a + b) / _dwellTimeSamples.length 
        : 0;
    final skipRatio = _totalViews > 0 ? _totalSkips / _totalViews : 0;
    if (avgVelocity > 1.5 && skipRatio > 0.6) return UserType.scanner;
    if (avgDwell > 15000 && skipRatio < 0.3) return UserType.watcher;
    return UserType.mixed;
  }
  
  void recordReelMetrics({
    required String reelId,
    required double velocity,
    required int dwellTimeMs,
    required bool wasSkipped,
  }) {
    if (_disposed) return;
    _velocitySamples.add(velocity);
    if (_velocitySamples.length > 20) _velocitySamples.removeAt(0);
    _dwellTimeSamples.add(dwellTimeMs);
    if (_dwellTimeSamples.length > 20) _dwellTimeSamples.removeAt(0);
    _totalViews++;
    if (wasSkipped) _totalSkips++;
    if (_totalViews % 5 == 0) {
      final type = _classifyUserType();
      switch (type) {
        case UserType.scanner: 
          _preloadPolicy.setScannerMode(true); 
          _preloadPolicy.setWatcherMode(false);
          if (kDebugMode) Get.log('🎯 [COORD] User type: scanner');
          break;
        case UserType.watcher: 
          _preloadPolicy.setWatcherMode(true);
          _preloadPolicy.setScannerMode(false);
          if (kDebugMode) Get.log('🎯 [COORD] User type: watcher');
          break;
        default: 
          _preloadPolicy.setScannerMode(false); 
          _preloadPolicy.setWatcherMode(false);
      }
    }
  }

  ScrollVelocity _mapToScrollVelocityWithHysteresis(double velocityPx) {
    if (_predictionEngine.shouldMaintainVelocityState(_velocity, velocityPx)) {
      return _velocity;
    }
    const fastThreshold = 2.0;
    const normalThreshold = 0.5;
    if (velocityPx.abs() > fastThreshold) return ScrollVelocity.fast;
    if (velocityPx.abs() < normalThreshold) return ScrollVelocity.slow;
    return ScrollVelocity.normal;
  }

  void _executePreloadDecision({
    required int currentIndex,
    required List<String> feedItems,
    required List<String> visibleItemIds,
    required Duration? videoDuration,
    required double hitRate,
    required double p95StartupMs,
  }) {
    if (_disposed) return;
    
    // 🔥 FIX #7: Budget check más permisivo - permitir preload si está cerca del límite
    if (_budgetTracker.currentBytes >= _budgetTracker.hardCap * 0.98) {
      if (kDebugMode) Get.log('⚠️ [COORD] Budget casi lleno: ${_budgetTracker.currentMB.toStringAsFixed(1)}/${_budgetTracker.hardCapMB.toStringAsFixed(1)}MB');
      return;
    }
    
    final hasReplay = visibleItemIds.any(
      (reelId) => _engagementTracker.getViewCount(reelId) > 1,
    );
    final isHighIntent = 
        _predictionEngine.isDeepReading() || 
        _predictionEngine.shouldAggressivePreload() ||
        hasReplay;
    final mode = _predictionEngine.currentMode;
    final currentBudgetBytes = _budgetTracker.currentBytes;
    
    final forwardCount = _preloadPolicy.resolveForwardCount(
      isWifi: _isWifi,
      velocity: _velocity,
      mode: mode,
      direction: _direction,
      isHighIntent: isHighIntent,
      hitRate: hitRate,
      currentBudgetBytes: currentBudgetBytes,
      avgVideoSizeBytes: _avgResourceSizeBytes,
      p95StartupMs: p95StartupMs,
      avgVideoDuration: videoDuration,
    );
    final backwardCount = _preloadPolicy.resolveBackwardCount(
      isWifi: _isWifi,
      velocity: _velocity,
      mode: mode,
      direction: _direction,
      hitRate: hitRate,
    );
    
    final pressure = _pool.currentActiveControllers();
    final adjustedForward = pressure > 8 
        ? (forwardCount ~/ 2).clamp(1, forwardCount) 
        : forwardCount;
    final adjustedBackward = pressure > 8 
        ? (backwardCount ~/ 2).clamp(0, backwardCount) 
        : backwardCount;
    
    if (kDebugMode) {
      Get.log('🎯 [COORD] Preload decision: forward=$adjustedForward, backward=$adjustedBackward | pressure=$pressure');
    }
    
    _enqueueDirectional(
      currentIndex: currentIndex,
      feedItems: feedItems,
      forwardCount: adjustedForward,
      backwardCount: adjustedBackward,
    );
  }

  void _enqueueDirectional({
    required int currentIndex,
    required List<String> feedItems,
    required int forwardCount,
    required int backwardCount,
  }) {
    if (_disposed || feedItems.isEmpty) return;
    
    // 🔥 FIX #7: Budget check más permisivo
    if (_budgetTracker.currentBytes >= _budgetTracker.hardCap * 0.98) return;
    
    final dynamicThrottle = _velocity == ScrollVelocity.fast ? 8 : 16;
    final now = DateTime.now();
    if (_lastEnqueueTime != null && 
        now.difference(_lastEnqueueTime!).inMilliseconds < dynamicThrottle) {
      return;
    }
    _lastEnqueueTime = now;
    
    final maxIndex = feedItems.length - 1;
    if (maxIndex < 0) return;
    final start = (currentIndex - 10).clamp(0, maxIndex);
    final end = (currentIndex + 10).clamp(0, maxIndex);
    
    int _calculatePriority(int distance, String url) {
      int base = switch (distance.abs()) {
        1 => 1,
        2 => 2,
        3 => 3,
        _ => 5,
      };
      final reel = _getReelByUrl(url);
      return _preloadPolicy.adjustPriorityForContent(
        basePriority: base,
        videoDuration: reel?.isVideo == true 
            ? Duration(seconds: reel!.duration ?? 30) 
            : null,
        videoSizeBytes: null,
        isHighIntent: _predictionEngine.isDeepReading() || 
            _predictionEngine.shouldAggressivePreload(),
      );
    }
    
    final isFastForward = _velocity == ScrollVelocity.fast && 
        _direction == ScrollDirection.forward;
    final forwardIndices = isFastForward
        ? [currentIndex + 2, currentIndex + 1, currentIndex + 3]
        : [currentIndex + 1, currentIndex + 2, currentIndex + 3];
    
    int enqueuedForward = 0;
    for (final targetIndex in forwardIndices) {
      if (enqueuedForward >= forwardCount) break;
      if (targetIndex < 0 || targetIndex > maxIndex) continue;
      if (targetIndex < start || targetIndex > end) continue;
      
      final reelId = feedItems[targetIndex];
      final reel = _getReelById(reelId);
      if (reel == null) {
        if (kDebugMode) Get.log('⚠️ [COORD] Reel no encontrado para ID: $reelId');
        continue;
      }
      
      final String urlToPreload;
      final int estimatedSize;
      
      if (reel.isVideo && reel.videoUrl != null && reel.videoUrl!.isNotEmpty) {
        urlToPreload = reel.videoUrl!;
        estimatedSize = 4 * 1024 * 1024;
      } else {
        urlToPreload = (reel.imageUrls.isNotEmpty) 
            ? reel.imageUrls.first 
            : (reel.thumbnailUrl ?? '');
        estimatedSize = 1200 * 1024;
      }
      
      if (urlToPreload.isEmpty) {
        if (kDebugMode) Get.log('⚠️ [COORD] URL vacía para reel: ${reel.id}');
        continue;
      }
      
      // 🔥 FIX #7: Permitir preload si está dentro del 98% del budget (no 100%)
      if (!_budgetTracker.hasBudgetFor(estimatedSize)) {
        if (kDebugMode) Get.log('💰 [COORD] Sin budget para: ${_shortenUrl(urlToPreload)} (${(estimatedSize/1024/1024).toStringAsFixed(1)}MB)');
        continue;
      }
      
      final distance = targetIndex - currentIndex;
      final priority = _calculatePriority(distance, urlToPreload);
      
      if (kDebugMode) {
        Get.log('🚀 [COORD] Enqueue ${reel.isVideo ? 'video' : 'image'}: ${_shortenUrl(urlToPreload)} | priority=$priority | idx=$targetIndex');
      }
      
      if (reel.isVideo) {
        _preloadManager.enqueue(
          urlToPreload,
          priority: priority,
          currentIndex: currentIndex,
          targetIndex: targetIndex,
        );
      } else {
        _preloadImageSafely(urlToPreload, priority);
      }
      enqueuedForward++;
    }
    
    // Fallback edge-case
    if (enqueuedForward == 0 && forwardCount > 0) {
      final fallbackIndex = currentIndex + 1;
      if (fallbackIndex <= maxIndex && fallbackIndex >= 0) {
        final reelId = feedItems[fallbackIndex];
        final reel = _getReelById(reelId);
        if (reel != null) {
          final urlToPreload = reel.isVideo && (reel.videoUrl?.isNotEmpty ?? false)
              ? reel.videoUrl!
              : (reel.imageUrls.isNotEmpty 
                  ? reel.imageUrls.first 
                  : (reel.thumbnailUrl ?? ''));
          
          if (urlToPreload.isNotEmpty) {
            final estimatedSize = reel.isVideo 
                ? (4 * 1024 * 1024) 
                : (1200 * 1024);
            
            if (_budgetTracker.hasBudgetFor(estimatedSize)) {
              if (kDebugMode) Get.log('🔄 [COORD] Fallback enqueue: ${_shortenUrl(urlToPreload)}');
              if (reel.isVideo) {
                _preloadManager.enqueue(
                  urlToPreload,
                  priority: 1,
                  currentIndex: currentIndex,
                  targetIndex: fallbackIndex,
                );
              } else {
                _preloadImageSafely(urlToPreload, 1);
              }
              enqueuedForward = 1;
            }
          }
        }
      }
    }
    
    // Backward
    int enqueuedBackward = 0;
    for (int i = currentIndex - 1; 
         i >= start && enqueuedBackward < backwardCount; 
         i--) {
      if (i < 0 || i > maxIndex) break;
      
      final reelId = feedItems[i];
      final reel = _getReelById(reelId);
      if (reel == null) continue;
      
      final urlToPreload = reel.isVideo && (reel.videoUrl?.isNotEmpty ?? false)
          ? reel.videoUrl!
          : (reel.imageUrls.isNotEmpty 
              ? reel.imageUrls.first 
              : (reel.thumbnailUrl ?? ''));
      
      if (urlToPreload.isEmpty) continue;
      
      final estimatedSize = reel.isVideo 
          ? (4 * 1024 * 1024) 
          : (1200 * 1024);
      
      if (!_budgetTracker.hasBudgetFor(estimatedSize)) continue;
      
      final distance = i - currentIndex;
      final priority = _calculatePriority(distance, urlToPreload).clamp(6, 10);
      
      if (kDebugMode) {
        Get.log('🔙 [COORD] Backward enqueue: ${_shortenUrl(urlToPreload)} | priority=$priority');
      }
      
      if (reel.isVideo) {
        _preloadManager.enqueue(
          urlToPreload,
          priority: priority,
          currentIndex: currentIndex,
          targetIndex: i,
        );
      } else {
        _preloadImageSafely(urlToPreload, priority);
      }
      enqueuedBackward++;
    }
    
    if (kDebugMode && (enqueuedForward > 0 || enqueuedBackward > 0)) {
      Get.log('✅ [COORD] Enqueue completado: forward=$enqueuedForward, backward=$enqueuedBackward');
    }
  }

  void _preloadImageSafely(String imageUrl, int priority) {
    if (priority <= 3) return;
    _imagePreloadManager.preloadImage(
      imageUrl,
      priority: priority,
      memCacheWidth: 1080,
    );
  }

  void _executeSmartCancel({
    required int currentIndex,
    required List<String> feedItems,
    required double hitRate,
  }) {
    if (_disposed) return;
    
    final mode = _predictionEngine.currentMode;
    final shouldCancel = _preloadPolicy.shouldAggressiveCancel(
      mode: mode,
      velocity: _velocity,
      hitRate: hitRate,
      isWifi: _isWifi,
    );
    
    if (shouldCancel) {
      if (kDebugMode) Get.log('🗑️ [COORD] Smart cancel triggered');
      final maxIndex = feedItems.length - 1;
      if (maxIndex < 0) return;
      final pressure = _pool.currentActiveControllers();
      final forwardDistance = _direction == ScrollDirection.forward ? 2 : 1;
      final backwardDistance = _direction == ScrollDirection.backward ? 2 : 1;
      final effectiveForward = pressure > 8 ? 1 : forwardDistance;
      final effectiveBackward = pressure > 8 ? 1 : backwardDistance;
      _preloadManager.cancelDirectional(
        currentIndex: currentIndex,
        forwardDistance: effectiveForward,
        backwardDistance: effectiveBackward,
      );
    }
  }

  String _shortenUrl(String url) => 
      url.length > 40 ? '${url.substring(0, 40)}...' : url;
  
  double _avgResourceSizeBytes = 3 * 1024 * 1024;

  Map<String, dynamic> getStats() {
    return {
      'current_index': _currentIndex,
      'direction': _direction.toString(),
      'velocity': _velocity.toString(),
      'is_wifi': _isWifi,
      'prediction_mode': _predictionEngine.currentMode.toString(),
      'direction_confidence': _predictionEngine.directionConfidence.toStringAsFixed(2),
      'pool_hit_rate': _pool.getGlobalHitRate().toStringAsFixed(1),
      'pool_p95_startup_ms': _pool.p95StartupMs.toStringAsFixed(1),
      'pool_active_controllers': _pool.currentActiveControllers(),
      'budget_current_mb': _budgetTracker.currentMB.toStringAsFixed(2),
      'budget_hardcap_mb': _budgetTracker.hardCapMB.toStringAsFixed(0),
      'preload_avg_resource_size_mb': (_avgResourceSizeBytes / 1024 / 1024).toStringAsFixed(2),
      'is_disposed': _disposed,
      'image_preload_stats': (() {
        try {
          return (_imagePreloadManager as dynamic).getStats();
        } catch (_) {
          return {'cached': _imagePreloadManager.cachedUrls.length};
        }
      })(),
    };
  }

  Future<void> reset() async {
    if (kDebugMode) Get.log('🔄 [COORD] reset() - Reiniciando coordinator');
    _predictionEngine.reset();
    _engagementTracker.dispose();
    await _preloadManager.reset();
    try {
      await (_imagePreloadManager as dynamic).reset();
    } catch (_) {
      _imagePreloadManager.clear();
    }
    _currentIndex = 0;
    _direction = ScrollDirection.forward;
    _velocity = ScrollVelocity.normal;
    _lastEnqueueTime = null;
    _budgetTracker.reset();
    _reelsByUrl.clear();
    _reelsById.clear();
    _totalSkips = 0;
    _totalViews = 0;
    if (kDebugMode) Get.log('✅ [COORD] Reset completado');
  }

  Future<void> dispose() async {
    if (kDebugMode) Get.log('🧹 [COORD] dispose() - Liberando recursos');
    _disposed = true;
    
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    
    _predictionEngine.dispose();
    _engagementTracker.dispose();
    await _preloadManager.dispose();
    try {
      await (_imagePreloadManager as dynamic).dispose();
    } catch (_) {}
    await _budgetTracker.dispose();
    
    _pool.unsubscribeFromLifecycle(_onPoolLifecycleEvent);
    _reelsByUrl.clear();
    _reelsById.clear();
    
    if (kDebugMode) Get.log('✅ [COORD] Recursos liberados correctamente');
  }
}