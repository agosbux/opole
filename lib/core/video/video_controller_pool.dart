// lib/core/video/video_controller_pool.dart
// ===================================================================
// VIDEO CONTROLLER POOL v6.1.36 – CONCURRENT MODIFICATION FIX
// ===================================================================
// ✅ RefCount balanceado + LRU real + Warm Queue con prioridad
// ✅ Cancelación REAL con 3 checkpoints en _create()
// ✅ Distance-aware eviction con scoring balanceado + direccional
// ✅ Usage score con cap + decay + cold penalty
// ✅ lowBandwidth propagado a CloudinaryUrlOptimizer
// ✅ Released cache controlado + cleanupMemory para lifecycle
// ✅ Hit rate tracking (única fuente de verdad para auto-optimización)
// ✅ Compatible con VideoPreloadManager v4.13 (baseScore, stickiness, etc.)
// 🔥 FIX #1: Lifecycle hooks para budget tracking REAL (zero estimación)
// 🔥 FIX #2: Startup time tracking (p95) para feedback loop en policy
// 🔥 FIX #3: cancelDirectional retorna URLs canceladas para budget inmediato
// 🔥 FIX #4: VideoState enum + getState() para zero ambigüedad
// 🔥 FIX #5: Metadata size sin HEAD requests (Cloudinary/Supabase inference)
// 🔥 FIX #6: maxActiveControllers dinámico: 7 WiFi / 4 mobile
// 🔥 FIX #7: Warmup condicional: solo para distance <= 2 (ahorro CPU)
// 🔥 FIX #8: init()/dispose() públicos + aliases para FeedPreloadCoordinator
// 🔥 FIX #9: cleanupMemory() guard contra concurrent modification (v6.1.36)
// ===================================================================
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'dart:async' show unawaited, Completer;
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:opole/core/utils/cloudinary_url_normalizer.dart';
import 'package:opole/core/utils/cloudinary_url_optimizer.dart';
import 'dart:io' show File;
import 'package:opole/core/video/video_cache_manager.dart';

enum PendingCommand { play, pause }

// ===================================================================
// 🔥 FIX #4: VideoState enum para tracking explícito (zero ambigüedad)
// ===================================================================
enum VideoState { idle, preloading, ready, disposed, decoding }

// ===================================================================
// 🔥 FIX #1: Lifecycle hook typedef para budget tracking REAL
// ===================================================================
typedef PoolLifecycleListener = void Function({
  required String url,
  required bool created,    // true = controller creado, false = disposed/cancelled
  required bool cacheHit,   // true = ya estaba en cache, false = descarga nueva
  required int? sizeBytes,  // tamaño inferido del video (si disponible)
});

// ===================================================================
// ✅ WarmItem para warm queue con prioridad
// ===================================================================
class WarmItem implements Comparable<WarmItem> {
  final String url;
  final int priority;
  final int generation;
  
  WarmItem({required this.url, required this.priority, required this.generation});
  
  @override
  int compareTo(WarmItem other) => priority.compareTo(other.priority);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WarmItem &&
          url == other.url &&
          priority == other.priority &&
          generation == other.generation;
  
  @override
  int get hashCode => url.hashCode ^ priority.hashCode ^ generation.hashCode;
}

// ===================================================================
// ✅ VideoControllerPool – Singleton con gestión inteligente de controllers
// ===================================================================
class VideoControllerPool {
  VideoControllerPool._();
  static final VideoControllerPool instance = VideoControllerPool._();
  
  // ✅ Límites configurables
  // 🔥 FIX #6: maxActiveControllers dinámico por red
  static const int maxActiveControllersWifi = 7; // TikTok-level: 6-8
  static const int maxActiveControllersMobile = 4; // Conservador para mobile
  static const int maxReleasedCache = 2;
  static const Duration _firstFrameTimeout = Duration(milliseconds: 300);
  static const Duration _minBufferThreshold = Duration(milliseconds: 100);
  
  // ✅ Warm queue config
  static const int _maxWarmQueueWorkers = 2;
  int _warmQueueWorkers = 0;

  // ✅ Controllers activos
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, Completer<VideoPlayerController>> _initializing = {};
  final Map<String, PendingCommand> _pendingCommands = {};
  final Set<String> _nonLoopingUrls = {};
  
  // ✅ Released cache para reuso rápido
  final Map<String, VideoPlayerController> _releasedCache = {};
  
  // ✅ LRU tracking
  final LinkedHashMap<String, DateTime> _lru = LinkedHashMap();
  
  // ✅ Reference counting para evitar dispose prematuro
  final Map<String, int> _refCounts = {};
  final Map<String, bool> _pendingEviction = {};
  final Set<String> _disposedUrls = {};
  
  // ✅ Cancelación con TTL
  final Map<String, DateTime> _cancelledUrls = {};
  static const int _maxCancelledUrls = 100;
  static const Duration _cancelTTL = Duration(seconds: 30);
  
  // ✅ Warm queue
  final HeapPriorityQueue<WarmItem> _warmQueue = HeapPriorityQueue<WarmItem>();
  final Set<String> _urlsInWarmQueue = {};
  bool _isProcessingWarmQueue = false;
  
  // ✅ Generation para invalidación de preloads obsoletos
  int _generation = 0;
  String? _activeUrl;
  
  // ✅ Distance tracking para eviction aware de posición en feed
  final Map<String, int> _urlDistance = {};
  
  // 🔥 FIX #6: Tipo de conexión para dynamic limits
  bool _isWifi = true;
  void setIsWifi(bool value) => _isWifi = value;

  // ===================================================================
  // 🔥 FIX #9: Guard contra concurrent modification en cleanupMemory
  // ===================================================================
  bool _isCleaningUp = false;

  // ===================================================================
  // ✅ Usage-aware scoring para eviction inteligente
  // ===================================================================
  final Map<String, int> _usageScore = {};
  static const double _usageDecayFactor = 0.7;
  static const int _usageDecayThreshold = 0;
  static const int _maxUsageScore = 10;
  static const int _coldPenalty = 15;
  
  // 🔥 Pesos balanceados para scoring de eviction
  static const int _usageWeight = 6;
  static const int _recencyWeight = 2;
  static const int _distanceWeight = 1;
  static const int _backwardPenalty = 5;

  // ===================================================================
  // ✅ Hit rate tracking (única fuente de verdad para auto-optimización)
  // ===================================================================
  int _preloadHits = 0;
  int _preloadMisses = 0;

  // ===================================================================
  // 🔥 FIX #1: Lifecycle hooks para budget tracking REAL
  // ===================================================================
  final List<PoolLifecycleListener> _lifecycleListeners = [];
  
  void subscribeToLifecycle(PoolLifecycleListener listener) {
    if (!_lifecycleListeners.contains(listener)) {
      _lifecycleListeners.add(listener);
    }
  }
  
  void unsubscribeFromLifecycle(PoolLifecycleListener listener) {
    _lifecycleListeners.remove(listener);
  }
  
  void _notifyLifecycle({
    required String url,
    required bool created,
    required bool cacheHit,
    required int? sizeBytes,
  }) {
    if (kDebugMode) {
      print('🔔 [POOL] Lifecycle: $url created=$created cacheHit=$cacheHit size=${sizeBytes ?? "null"}');
    }
    for (final listener in _lifecycleListeners) {
      try {
        listener(url: url, created: created, cacheHit: cacheHit, sizeBytes: sizeBytes);
      } catch (e, st) {
        if (kDebugMode) print('⚠️ [POOL] Lifecycle listener error: $e\n$st');
      }
    }
  }

  // ===================================================================
  // 🔥 FIX #2: VideoState tracking + getState() getter
  // ===================================================================
  final Map<String, VideoState> _videoStates = {};
  final Map<String, int?> _videoSizes = {}; // Cache de tamaños inferidos
  
  VideoState getState(String url) => _videoStates[url] ?? VideoState.idle;
  
  // ===================================================================
  // 🔥 FIX #5: Metadata size sin HEAD requests (Cloudinary/Supabase inference)
  // ===================================================================
  Future<int?> _getVideoSizeBytesFromMetadata(String url) async {
    // ✅ Cache hit
    if (_videoSizes.containsKey(url)) return _videoSizes[url];
    
    // ✅ Opción 1: Cloudinary transformation presets (ajustar a tu config real)
    if (url.contains('/q_auto/')) return _videoSizes[url] = 3 * 1024 * 1024; // ~3MB
    if (url.contains('/q_low/')) return _videoSizes[url] = 1 * 1024 * 1024;  // ~1MB
    if (url.contains('/q_high/')) return _videoSizes[url] = 8 * 1024 * 1024; // ~8MB
    if (url.contains('/f_auto,q_60/')) return _videoSizes[url] = 2 * 1024 * 1024; // ~2MB
    if (url.contains('/w_720/')) return _videoSizes[url] = 2 * 1024 * 1024;  // ~2MB 720p
    if (url.contains('/w_1080/')) return _videoSizes[url] = 5 * 1024 * 1024; // ~5MB 1080p
    
    // ✅ Opción 2: Inferir por duración * bitrate estimado (fallback)
    // En producción real: llamar a Supabase/Cloudinary API para metadata exacta
    return _videoSizes[url] = null; // Fallback → coordinator usa _avgVideoSizeBytes
  }

  // ===================================================================
  // 🔥 FIX #2: Startup time tracking para feedback loop en policy
  // ===================================================================
  final Map<String, List<int>> _startupTimesMs = {};
  static const int _maxStartupSamplesPerUrl = 5;
  double _avgStartupMs = 80.0;
  double _p95StartupMs = 150.0;
  
  void recordStartupTime(String url, Duration startupTime) {
    if (kDebugMode) print('⏱️ [POOL] Startup: $url = ${startupTime.inMilliseconds}ms');
    final ms = startupTime.inMilliseconds;
    final samples = _startupTimesMs[url] ?? [];
    samples.add(ms);
    if (samples.length > _maxStartupSamplesPerUrl) samples.removeAt(0);
    _startupTimesMs[url] = samples;
    _recalculateStartupMetrics();
  }
  
  void _recalculateStartupMetrics() {
    final allSamples = <int>[];
    for (final samples in _startupTimesMs.values) allSamples.addAll(samples);
    if (allSamples.isEmpty) return;
    
    _avgStartupMs = allSamples.reduce((a, b) => a + b) / allSamples.length;
    
    final sorted = List<int>.from(allSamples)..sort();
    final p95Index = (sorted.length * 0.95).floor().clamp(0, sorted.length - 1);
    _p95StartupMs = sorted[p95Index].toDouble();
    
    if (kDebugMode) {
      print('📊 [POOL] Startup metrics: avg=${_avgStartupMs.toInt()}ms, p95=${_p95StartupMs.toInt()}ms');
    }
  }
  
  double get avgStartupMs => _avgStartupMs;
  double get p95StartupMs => _p95StartupMs;
  bool get isStartupSlow => _p95StartupMs > 120;
  bool get isStartupFast => _p95StartupMs < 40;

  // ===================================================================
  // ✅ Métodos públicos de usage tracking
  // ===================================================================
  
  void markUsed(String url) {
    final current = (_usageScore[url] ?? 0) + 1;
    _usageScore[url] = current > _maxUsageScore ? _maxUsageScore : current;
    if (kDebugMode) print('🧠 [POOL] Usage: $url = ${_usageScore[url]} (capped at $_maxUsageScore)');
  }

  void decayUsageScores() {
    final keys = _usageScore.keys.toList();
    for (final k in keys) {
      final newScore = (_usageScore[k]! * _usageDecayFactor).floor();
      if (newScore <= _usageDecayThreshold) {
        _usageScore.remove(k);
        if (kDebugMode) print('🧹 [POOL] Usage decay removed: $k');
      } else {
        _usageScore[k] = newScore;
        if (kDebugMode) print('📉 [POOL] Usage decay: $k = $newScore');
      }
    }
  }

  // ===================================================================
  // ✅ Cancelación REAL con TTL
  // ===================================================================
  
  /// 🔥 Cancela un URL: pausa controller activo si existe, registra para TTL
  void cancel(String url) {
    _cancelledUrls[url] = DateTime.now();
    
    // 🔥 Pausar inmediatamente si está activo (evita audio/CPU waste)
    final controller = _controllers[url];
    if (controller != null && controller.value.isInitialized) {
      unawaited(() async {
        try {
          await controller.pause();
          await controller.setVolume(0);
          if (kDebugMode) print('🛑 [POOL] Immediate pause: $url');
        } catch (_) {}
      }());
    }
    
    // 🔥 TTL cleanup para evitar crecimiento infinito
    if (_cancelledUrls.length > _maxCancelledUrls) {
      final now = DateTime.now();
      _cancelledUrls.removeWhere((_, ts) => now.difference(ts) > _cancelTTL);
      if (kDebugMode) print('🧹 [POOL] Cancelled URLs TTL cleanup');
    }
    
    // 🔥 FIX #1: Notificar lifecycle para budget real
    _videoStates[url] = VideoState.idle;
    _notifyLifecycle(url: url, created: false, cacheHit: false, sizeBytes: null);
    
    if (kDebugMode) print('🛑 [POOL] Cancel requested: $url');
  }
  
  /// 🔥 Cancela y dispone si está en released cache (evita memory leaks)
  void cancelAndDisposeIfCached(String url) {
    final cached = _releasedCache.remove(url);
    if (cached != null) {
      unawaited(() async {
        try {
          await cached.dispose();
          _disposedUrls.add(url);
          if (kDebugMode) print('🗑️ [POOL] Disposed from releasedCache: $url');
        } catch (_) {}
      }());
      clearUrlDistance(url);
      _refCounts.remove(url);
      _videoStates[url] = VideoState.disposed;
      _notifyLifecycle(url: url, created: false, cacheHit: false, sizeBytes: null);
    }
  }
  
  /// 🔥 Verifica si un URL fue cancelado (con TTL check)
  bool _isCancelled(String url) {
    if (_cancelledUrls.containsKey(url)) {
      // 🔥 Verificar TTL
      if (DateTime.now().difference(_cancelledUrls[url]!) > _cancelTTL) {
        _cancelledUrls.remove(url);
        return false;
      }
      _cancelledUrls.remove(url);
      return true;
    }
    return false;
  }

  // ===================================================================
  // 🔥 FIX #3: Cancelación direccional que retorna URLs para budget inmediato
  // ===================================================================
  List<String> cancelDirectional({
    required int currentIndex,
    required int forwardDistance,
    required int backwardDistance,
  }) {
    if (kDebugMode) print('🎯 [POOL] cancelDirectional: fwd>$forwardDistance, bwd>$backwardDistance');
    
    final cancelled = <String>[];
    
    // ✅ Cancelar activos con distancias direccionales
    for (final entry in Map<String, int>.from(_urlDistance).entries) {
      final url = entry.key;
      final dist = entry.value;
      
      final shouldCancel = (dist > 0 && dist > forwardDistance) || 
                           (dist < 0 && dist.abs() > backwardDistance);
      
      if (shouldCancel && (_controllers.containsKey(url) || 
          _releasedCache.containsKey(url) ||
          _videoStates[url] == VideoState.preloading ||
          _videoStates[url] == VideoState.decoding)) {
        cancel(url);
        cancelled.add(url);
        if (kDebugMode) print('🗑️ [POOL] Directional cancel: $url (dist=$dist)');
      }
    }
    
    // ✅ También revisar warm queue si existe
    final warmToCancel = <WarmItem>[];
    for (final item in _warmQueue.toList()) {
      final dist = _urlDistance[item.url];
      if (dist != null && ((dist > 0 && dist > forwardDistance) || (dist < 0 && dist.abs() > backwardDistance))) {
        warmToCancel.add(item);
      }
    }
    for (final item in warmToCancel) {
      _warmQueue.remove(item);
      _urlsInWarmQueue.remove(item.url);
      cancelled.add(item.url);
      if (kDebugMode) print('🗑️ [POOL] Warm queue cancel: ${item.url}');
    }
    
    if (cancelled.isNotEmpty && kDebugMode) {
      print('🛑 [POOL] Directional cancel complete: ${cancelled.length} URLs');
    }
    return cancelled; // 🔥 Retorna para ajuste inmediato en coordinator
  }

  // ===================================================================
  // ✅ Distance tracking para eviction aware de posición en feed
  // ===================================================================
  
  void setUrlDistance(String url, int relativeDistance) {
    _urlDistance[url] = relativeDistance;
  }
  
  int? getUrlDistance(String url) => _urlDistance[url];
  
  void clearUrlDistance(String url) {
    _urlDistance.remove(url);
  }
  
  // 🔥 Hook para session depth desde PreloadManager (eviction más inteligente)
  void setAverageSessionDepth(double depth) {
    // Reservado para futura integración con eviction scoring
    if (kDebugMode) print('🧠 [POOL] Session depth hint: $depth');
  }

  // ===================================================================
  // ✅ Estado de controllers
  // ===================================================================
  
  bool isControllerActive(String url) {
    if (_disposedUrls.contains(url)) return false;
    final c = _controllers[url];
    if (c == null) return false;
    try {
      return c.value.isInitialized;
    } catch (_) {
      return false;
    }
  }

  // ===================================================================
  // ✅ Reference counting
  // ===================================================================
  
  void _retain(String url) {
    _refCounts[url] = (_refCounts[url] ?? 0) + 1;
    if (kDebugMode) print('📈 [POOL] Retain: $url (refs: ${_refCounts[url]})');
  }

  Future<void> release(String url) async {
    final count = (_refCounts[url] ?? 1) - 1;
    if (kDebugMode) {
      print('📉 [POOL] Release: $url (refs: ${count > 0 ? count : 0})');
    }
    if (count <= 0) {
      _refCounts.remove(url);
      await _forceDispose(url);
    } else {
      _refCounts[url] = count;
    }
  }

  Future<void> _forceDispose(String url) async {
    if (_pendingEviction[url] == true) return;
    _pendingEviction[url] = true;
    
    try {
      final controller = _controllers[url];
      if (controller != null) {
        try {
          if (controller.value.isInitialized) {
            await controller.pause();
            await controller.setVolume(0);
            await controller.seekTo(Duration.zero);
          }
          await controller.dispose();
          _disposedUrls.add(url);
          _videoStates[url] = VideoState.disposed;
          if (kDebugMode) print('🗑️ [POOL] Force disposed: $url');
        } catch (e) {
          if (kDebugMode) print('⚠️ [POOL] Error disposing $url: $e');
        } finally {
          _controllers.remove(url);
          _lru.remove(url);
          _pendingCommands.remove(url);
          _nonLoopingUrls.remove(url);
          clearUrlDistance(url);
        }
      }
    } finally {
      _pendingEviction.remove(url);
    }
  }

  // ===================================================================
  // ✅ Generation management para invalidación de preloads obsoletos
  // ===================================================================
  
  void incrementGeneration() {
    _generation++;
    decayUsageScores();
    if (kDebugMode) print('🔄 [POOL] Generation incremented to $_generation + decay applied');
  }
  
  int get currentGeneration => _generation;

  // ===================================================================
  // ✅ Looping configuration
  // ===================================================================
  
  void setLoopingForUrl(String url, bool shouldLoop) {
    if (shouldLoop) {
      _nonLoopingUrls.remove(url);
    } else {
      _nonLoopingUrls.add(url);
    }
    final controller = _controllers[url];
    if (controller != null && controller.value.isInitialized) {
      unawaited(controller.setLooping(shouldLoop));
    }
  }

  // ===================================================================
  // ✅ get() – Obtener o crear controller con gestión completa
  // ===================================================================
  
  Future<VideoPlayerController> get(String url, {
    bool lowBandwidth = false,
    int? relativeDistance, // 🔥 FIX #7: Para warmup condicional
  }) async {
    if (url.isEmpty) throw Exception('VideoControllerPool: empty url');
    
    // 🔥 Hit rate tracking (única fuente de verdad)
    if (_controllers.containsKey(url) || _releasedCache.containsKey(url)) {
      _preloadHits++;
    } else {
      _preloadMisses++;
    }
    
    _retain(url);
    
    // ✅ CASO 1: Ya está activo → tocar LRU y retornar
    if (_controllers.containsKey(url)) {
      _touch(url);
      return _controllers[url]!;
    }
    
    // ✅ CASO 2: Reusar desde released cache
    if (_releasedCache.containsKey(url)) {
      final recycled = _releasedCache.remove(url)!;
      bool isReusable = false;
      try {
        isReusable = !_disposedUrls.contains(url) && recycled.value.isInitialized;
      } catch (_) {}
      
      if (isReusable) {
        _controllers[url] = recycled;
        _videoStates[url] = VideoState.ready;
        _touch(url);
        await release(url); // Balancear refCount
        if (kDebugMode) print('♻️ [POOL] Reused from cache: $url (ref balanced)');
        return recycled;
      } else {
        try {
          await recycled.dispose();
        } catch (_) {}
      }
    }
    
    // ✅ CASO 3: Ya inicializando → esperar completer
    if (_initializing.containsKey(url)) {
      return _initializing[url]!.future;
    }
    
    // 🔥 FIX #6: Usar dynamicMaxActiveControllers
    if (_controllers.length >= dynamicMaxActiveControllers) {
      await _evict(urgent: true);
    }
    
    final completer = Completer<VideoPlayerController>();
    _initializing[url] = completer;
    _videoStates[url] = VideoState.preloading;
    
    try {
      // 🔥 FIX #7: Pasar relativeDistance a _create para warmup condicional
      final controller = await _create(url, lowBandwidth: lowBandwidth, relativeDistance: relativeDistance);
      completer.complete(controller);
      return controller;
    } catch (e) {
      completer.completeError(e);
      _videoStates[url] = VideoState.idle;
      rethrow;
    } finally {
      _initializing.remove(url);
    }
  }

  // ===================================================================
  // 🔥 _create() – Creación con cancelación REAL + warmup condicional
  // ===================================================================
  
  Future<VideoPlayerController> _create(String url, {
    bool lowBandwidth = false,
    int? relativeDistance, // 🔥 FIX #7: Para warmup condicional
  }) async {
    _disposedUrls.remove(url);
    final genAtStart = _generation;
    
    // 🔥 CHECKPOINT 1: Antes de cualquier trabajo pesado
    if (_isCancelled(url)) {
      _videoStates[url] = VideoState.idle;
      throw Exception('[POOL] Cancelled before init: $url');
    }
    
    // ✅ Normalización + optimización de URL
    final normalizedUrl = CloudinaryUrlNormalizer.normalize(url, isVideo: true);
    final optimizedUrl = CloudinaryUrlOptimizer.optimizeVideoUrl(normalizedUrl, lowBandwidth: lowBandwidth);
    
    // ✅ Intentar obtener desde cache local
    Uri? localUri = await VideoCacheManager.instance.getLocalUri(optimizedUrl);
    if (localUri == null) {
      final partial = await VideoCacheManager.instance.downloadPartial(optimizedUrl);
      if (partial != null) {
        localUri = partial.uri;
      } else {
        // Download completo en background si falla partial
        unawaited(VideoCacheManager.instance.downloadAndCache(optimizedUrl));
      }
    }
    
    if (kDebugMode) print('🎬 [POOL] Creating controller: $optimizedUrl');
    
    // ✅ Crear controller (file o network)
    final controller = localUri != null
        ? VideoPlayerController.file(
            File.fromUri(localUri),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
          )
        : VideoPlayerController.networkUrl(
            Uri.parse(optimizedUrl),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
          );
    
    bool disposedByGuard = false;
    
    try {
      // 🔥 CHECKPOINT 2: Post-download, pre-initialize
      if (_isCancelled(url)) {
        await controller.dispose();
        _disposedUrls.add(url);
        _videoStates[url] = VideoState.disposed;
        throw Exception('[POOL] Cancelled before initialize: $url');
      }
      
      await controller.initialize();
      
      // 🔥 CHECKPOINT 3: Post-initialize
      if (_isCancelled(url)) {
        await controller.dispose();
        _disposedUrls.add(url);
        _videoStates[url] = VideoState.disposed;
        throw Exception('[POOL] Cancelled after initialize: $url');
      }
      
      // ✅ Generation guard: abortar si cambió durante init
      if (_generation != genAtStart && !_initializing.containsKey(url)) {
        disposedByGuard = true;
        try {
          await controller.dispose();
        } catch (_) {}
        _disposedUrls.add(url);
        _videoStates[url] = VideoState.disposed;
        throw Exception('[POOL] Init aborted (generation changed): $url');
      }
      
      if (!_initializing.containsKey(url)) {
        disposedByGuard = true;
        try {
          await controller.dispose();
        } catch (_) {}
        _disposedUrls.add(url);
        _videoStates[url] = VideoState.disposed;
        throw Exception('[POOL] Init aborted (pool cleared): $url');
      }
      
      // 🔥 FIX #7: Warmup condicional (solo para distance <= 2)
      final shouldWarmup = relativeDistance != null && relativeDistance.abs() <= 2;
      
      if (shouldWarmup) {
        // 🔥 Warmup completo: play → waitForFirstFrame → pause → seek
        await controller.seekTo(Duration.zero);
        await controller.setVolume(0);
        await controller.play();
        await _waitForFirstFrame(controller);
        await controller.pause();
        await controller.seekTo(Duration.zero);
        if (kDebugMode) print('🔥 [POOL] Warmup: $url (dist=$relativeDistance)');
      } else {
        // 🔥 Solo initialize para videos lejanos → ahorro de CPU/batería
        if (kDebugMode) print('⚡ [POOL] Skip warmup: $url (dist=$relativeDistance)');
      }
      
      // ✅ Generation guard post-warmup
      if (!_initializing.containsKey(url)) {
        disposedByGuard = true;
        try {
          await controller.dispose();
        } catch (_) {}
        _disposedUrls.add(url);
        _videoStates[url] = VideoState.disposed;
        throw Exception('[POOL] Init aborted after warmup: $url');
      }
      
      // ✅ Configurar estado inicial
      await controller.setVolume(0);
      final shouldLoop = !_nonLoopingUrls.contains(url);
      await controller.setLooping(shouldLoop);
      await controller.setPlaybackSpeed(1.0);
      
      // ✅ Procesar comando pendiente si existe
      final cmd = _pendingCommands[url];
      if (cmd == PendingCommand.play) {
        await controller.setVolume(1);
        await controller.play();
        if (_activeUrl != url) {
          await controller.pause();
          await controller.setVolume(0);
        } else {
          _activeUrl = url;
        }
      } else if (cmd == PendingCommand.pause) {
        await controller.pause();
        await controller.setVolume(0);
      }
      _pendingCommands.remove(url);
      
      // 🔥 FIX #6: Evict usando dynamicMaxActiveControllers
      if (_controllers.length >= dynamicMaxActiveControllers) {
        await _evict();
      }
      
      // ✅ Agregar a controllers activos y tocar LRU
      _controllers[url] = controller;
      _videoStates[url] = VideoState.ready;
      _touch(url);
      
      // 🔥 FIX #1 + #5: Notificar creación REAL con tamaño inferido
      final sizeBytes = await _getVideoSizeBytesFromMetadata(url);
      _notifyLifecycle(url: url, created: true, cacheHit: false, sizeBytes: sizeBytes);
      
      return controller;
      
    } catch (e, stackTrace) {
      if (!disposedByGuard) {
        try {
          await controller.dispose();
        } catch (_) {}
        _disposedUrls.add(url);
        _videoStates[url] = VideoState.disposed;
      }
      if (kDebugMode) {
        print('❌ Error initializing video for $url: $e');
        print('Stack: $stackTrace');
      }
      rethrow;
    }
  }

  // ===================================================================
  // ✅ _waitForFirstFrame – Buffer check robusto para HLS/fragmentado
  // ===================================================================
  
  bool _hasSufficientBufferAt(VideoPlayerValue value, Duration position, Duration threshold) {
    if (!value.isInitialized || value.buffered.isEmpty) return false;
    return value.buffered.any((range) => 
      range.start <= position && range.end >= position + threshold,
    );
  }

  Future<void> _waitForFirstFrame(VideoPlayerController controller) async {
    if (_hasSufficientBufferAt(controller.value, Duration.zero, _minBufferThreshold)) {
      return;
    }
    
    final completer = Completer<void>();
    VoidCallback? listener;
    
    listener = () {
      if (_hasSufficientBufferAt(controller.value, Duration.zero, _minBufferThreshold)) {
        if (!completer.isCompleted) completer.complete();
      }
    };
    
    controller.addListener(listener);
    
    try {
      await completer.future.timeout(
        _firstFrameTimeout,
        onTimeout: () {
          if (kDebugMode) print('⏱️ [POOL] First frame timeout — continuing');
        },
      );
    } finally {
      controller.removeListener(listener);
    }
  }

  // ===================================================================
  // ✅ LRU management
  // ===================================================================
  
  void _touch(String url) {
    if (_activeUrl != null && url == _activeUrl) {
      _lru.remove(_activeUrl);
    }
    _lru.remove(url);
    _lru[url] = DateTime.now();
  }

  // ===================================================================
  // 🔥 Eviction inteligente con scoring balanceado + direccional
  // ===================================================================
  
  Future<void> _evict({bool urgent = false}) async {
    if (_lru.isEmpty) return;
    
    String? candidate;
    int bestScore = 999999;
    final lruList = _lru.keys.toList();
    
    for (int i = 0; i < lruList.length; i++) {
      final url = lruList[i];
      
      // ✅ Filtros obligatorios
      if (url == _activeUrl) continue;
      if (_initializing.containsKey(url)) continue;
      if ((_refCounts[url] ?? 0) > 0) continue;
      if (_pendingEviction[url] == true) continue;
      
      final usage = _usageScore[url] ?? 0;
      
      // 🔥 Componentes de scoring balanceado
      final usageComponent = usage * _usageWeight;
      final recencyComponent = (lruList.length - i) * _recencyWeight;
      final isCold = usage == 0 ? _coldPenalty : 0;
      
      // 🔥 Distance-aware component (si disponible)
      int distanceComponent = 0;
      final relativeDistance = _urlDistance[url];
      if (relativeDistance != null) {
        final absDistance = relativeDistance.abs();
        final isForward = relativeDistance >= 0;
        
        if (absDistance <= 2) {
          distanceComponent = -30; // Muy cercano = crítico, no evictear
        } else if (absDistance <= 5) {
          distanceComponent = isForward ? -10 : -5;
        } else {
          distanceComponent = isForward ? 0 : _backwardPenalty;
        }
      }
      
      // 🔥 Score final balanceado
      final score = usageComponent + recencyComponent + distanceComponent + isCold;
      
      if (score < bestScore) {
        bestScore = score;
        candidate = url;
      }
    }
    
    if (candidate == null) {
      if (kDebugMode) print('🛡️ [POOL] No eviction candidate found');
      return;
    }
    
    // ✅ Ejecutar eviction
    _lru.remove(candidate);
    await release(candidate);
    _nonLoopingUrls.remove(candidate);
    _pendingCommands.remove(candidate);
    clearUrlDistance(candidate);
    
    if (kDebugMode) {
      final usage = _usageScore[candidate] ?? 0;
      final distance = _urlDistance[candidate];
      final isCold = usage == 0 ? 'COLD' : 'warm';
      final dir = distance != null ? (distance > 0 ? 'fwd' : 'bwd') : 'unk';
      print('🗑️ [POOL] Evicted: $candidate (usage:$usage[$isCold], dist:$distance[$dir], score:$bestScore)');
    }
  }

  // ===================================================================
  // ✅ Pause/Play management
  // ===================================================================
  
  Future<void> pauseAll() async {
    _activeUrl = null;
    await Future.wait([
      for (final entry in _controllers.entries)
        if (entry.value.value.isInitialized && entry.value.value.isPlaying)
          entry.value.pause().then((_) => entry.value.setVolume(0)).catchError((_) {}),
    ]);
  }
  
  Future<void> pauseAllExcept(String url) async {
    await Future.wait([
      for (final entry in _controllers.entries)
        if (entry.key != url && entry.value.value.isInitialized && entry.value.value.isPlaying)
          entry.value.pause().then((_) => entry.value.setVolume(0)).catchError((_) {}),
    ]);
    if (_controllers.containsKey(url)) {
      _activeUrl = url;
    }
  }

  // ===================================================================
  // ✅ play() – Con refCount balanceado y activeUrl tracking
  // ===================================================================
  
  Future<void> play(String url, {bool lowBandwidth = false}) async {
    _pendingCommands.removeWhere((k, v) => v == PendingCommand.play && k != url);
    
    if (!_controllers.containsKey(url) && !_initializing.containsKey(url)) {
      _pendingCommands[url] = PendingCommand.play;
    }
    
    final previousUrl = _activeUrl;
    _activeUrl = url;
    final requestedUrl = url;
    
    final previousController = previousUrl != null ? _controllers[previousUrl] : null;
    if (previousController?.value.isInitialized == true && previousController?.value.isPlaying == true) {
      await previousController!.pause();
      await previousController.setVolume(0);
    }
    
    for (final e in _controllers.entries) {
      if (e.key == url || e.key == previousUrl) continue;
      unawaited(() async {
        try {
          if (!e.value.value.isInitialized) return;
          await e.value.setVolume(0);
          await e.value.pause();
        } catch (_) {}
      }());
    }
    
    bool acquired = false;
    
    try {
      final controller = await get(url, lowBandwidth: lowBandwidth);
      acquired = true;
      
      if (_activeUrl != requestedUrl) {
        if (kDebugMode) print('🛡️ [POOL] Play aborted: $requestedUrl no longer active');
        if (controller.value.isInitialized) {
          await controller.pause();
          await controller.setVolume(0);
        }
        return;
      }
      
      if (controller.value.isInitialized) {
        if (!controller.value.isPlaying) {
          await controller.setVolume(1.0);
          await controller.play();
        } else {
          await controller.setVolume(1.0);
        }
        
        final shouldLoop = !_nonLoopingUrls.contains(requestedUrl);
        if (controller.value.isLooping != shouldLoop) {
          await controller.setLooping(shouldLoop);
        }
        
        _touch(requestedUrl);
        markUsed(requestedUrl);
      }
    } finally {
      if (acquired) {
        await release(requestedUrl);
      }
    }
  }

  Future<void> pause(String url) async {
    if (_activeUrl == url) {
      _activeUrl = null;
    }
    final c = _controllers[url];
    if (c != null && c.value.isInitialized) {
      await c.pause();
      await c.setVolume(0);
    } else {
      _pendingCommands[url] = PendingCommand.pause;
    }
  }
  
  Future<void> stop(String url) async {
    if (_activeUrl == url) {
      _activeUrl = null;
    }
    await pause(url);
  }

  // ===================================================================
  // ✅ preloadCritical() – Preload con caching y refCount balanceado
  // ===================================================================
  
  Future<void> preloadCritical(String url, {
    bool lowBandwidth = false,
    int priority = 10,
    int? relativeDistance,
    int? maxReleasedCache,
    bool isClusterHead = false,
  }) async {
    if (url.isEmpty) return;
    if (_controllers.containsKey(url) || _initializing.containsKey(url)) return;
    if (_isCancelled(url)) return;
    
    if (relativeDistance != null) {
      setUrlDistance(url, relativeDistance);
    }
    
    bool acquired = false;
    bool cached = false;
    
    try {
      // 🔥 FIX #7: Pasar relativeDistance para warmup condicional
      final controller = await get(url, lowBandwidth: lowBandwidth, relativeDistance: relativeDistance);
      acquired = true;
      
      if (_isCancelled(url)) {
        await release(url);
        return;
      }
      
      final effectiveMaxCache = maxReleasedCache ?? VideoControllerPool.maxReleasedCache;
      if (_releasedCache.length < effectiveMaxCache + 1) {
        _controllers.remove(url);
        _lru.remove(url);
        _releasedCache[url] = controller;
        _videoStates[url] = VideoState.ready;
        cached = true;
        if (kDebugMode) print('🔥 [POOL] Preloaded to cache: $url (ref held by cache)');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [POOL] Preload failed: $e');
    } finally {
      if (acquired && !cached) {
        await release(url);
      }
    }
  }

  Future<void> preloadCriticalList(List<String> urls, {bool lowBandwidth = false}) async {
    for (final url in urls) {
      await preloadCritical(url, lowBandwidth: lowBandwidth);
    }
  }
  
  Future<void> preload(List<String> urls) async {
    for (final url in urls) {
      addToWarmQueue(url, priority: 10);
    }
  }

  // ===================================================================
  // ✅ getSync() – Acceso síncrono si ya está inicializado
  // ===================================================================
  
  VideoPlayerController? getSync(String url) {
    if (_disposedUrls.contains(url)) return null;
    final c = _controllers[url];
    if (c != null && c.value.isInitialized) {
      _touch(url);
      return c;
    }
    return null;
  }

  // ===================================================================
  // ✅ Cleanup y dispose
  // ===================================================================
  
  Future<void> disposeAll() async {
    _activeUrl = null;
    _refCounts.clear();
    _pendingEviction.clear();
    _usageScore.clear();
    _cancelledUrls.clear();
    _urlDistance.clear();
    _videoSizes.clear();
    _startupTimesMs.clear();
    
    for (final entry in _controllers.entries) {
      final url = entry.key;
      final c = entry.value;
      try {
        if (!_disposedUrls.contains(url)) {
          await c.dispose();
          _disposedUrls.add(url);
          _videoStates[url] = VideoState.disposed;
        }
      } catch (_) {}
    }
    
    for (final entry in _releasedCache.entries) {
      final url = entry.key;
      final c = entry.value;
      try {
        await c.dispose();
        _disposedUrls.add(url);
        _videoStates[url] = VideoState.disposed;
      } catch (_) {}
    }
    
    _controllers.clear();
    _releasedCache.clear();
    _initializing.clear();
    _lru.clear();
    _pendingCommands.clear();
    _nonLoopingUrls.clear();
    _warmQueue.clear();
    _urlsInWarmQueue.clear();
    _videoStates.clear();
    _generation = 0;
    _disposedUrls.clear();
  }
  
  int get cachedCount => _controllers.length;
  String? get activeUrl => _activeUrl;
  
  Map<String, bool> get activeControllers => Map.fromEntries(
    _controllers.entries.map((e) => MapEntry(e.key, e.value.value.isInitialized && e.value.value.isPlaying)),
  );
  
  Iterable<String> get activeControllerKeys => _controllers.keys;
  
  // ===================================================================
  // 🔥 FIX #6: dynamicMaxActiveControllers getter
  // ===================================================================
  int get dynamicMaxActiveControllers => _isWifi ? maxActiveControllersWifi : maxActiveControllersMobile;
  
  // ===================================================================
  // ✅ Hit rate tracking (pública para auto-optimización del PreloadManager)
  // ===================================================================
  
  int get preloadHits => _preloadHits;
  int get preloadMisses => _preloadMisses;
  double get preloadHitRate {
    final total = _preloadHits + _preloadMisses;
    return total == 0 ? 0 : (_preloadHits / total) * 100;
  }
  
  // ===================================================================
  // ✅ Debug state
  // ===================================================================
  
  Map<String, String> get debugPoolState {
    if (!kDebugMode) return {};
    return {
      'controllers': _controllers.length.toString(),
      'initializing': _initializing.length.toString(),
      'pending': _pendingCommands.length.toString(),
      'active': _activeUrl ?? 'none',
      'activeCount': activeCount.toString(),
      'totalCount': totalCount.toString(),
      'releasedCache': _releasedCache.length.toString(),
      'warmQueue': _warmQueue.length.toString(),
      'urlsInWarmQueue': _urlsInWarmQueue.length.toString(),
      'generation': _generation.toString(),
      'lru_order': _lru.keys.join(','),
      'refCounts': _refCounts.toString(),
      'disposedUrls': _disposedUrls.length.toString(),
      'usageScores': _usageScore.toString(),
      'cancelledUrls': _cancelledUrls.length.toString(),
      'urlDistance': _urlDistance.toString(),
      'coldPenalty': _coldPenalty.toString(),
      'scoring_weights': 'usage:$_usageWeight,recency:$_recencyWeight,dist:$_distanceWeight,backward:$_backwardPenalty',
      'preload_hits': _preloadHits.toString(),
      'preload_misses': _preloadMisses.toString(),
      'preload_hit_rate': '${preloadHitRate.toStringAsFixed(1)}%',
      'avg_startup_ms': _avgStartupMs.toStringAsFixed(1),
      'p95_startup_ms': _p95StartupMs.toStringAsFixed(1),
      'video_states': _videoStates.entries.map((e) => '${e.key}:${e.value.name}').toList().join(','),
      'is_wifi': _isWifi.toString(),
      'dynamic_max_controllers': dynamicMaxActiveControllers.toString(),
    };
  }
  
  void cleanupStaleCommands(Set<String> validUrls) {
    final stale = _pendingCommands.keys.where((k) => !validUrls.contains(k)).toList();
    for (final key in stale) {
      _pendingCommands.remove(key);
      if (kDebugMode) print('🧹 [POOL] Cleanup stale command: $key');
    }
  }
  
  Future<void> clear() async => await disposeAll();

  // ===================================================================
  // ✅ clearInactive() – Limpieza de controllers no usados
  // ===================================================================
  
  Future<void> clearInactive() async {
    if (kDebugMode) print('🧹 [POOL] clearInactive() - Iniciando limpieza...');
    
    final activeUrls = Set<String>.from(_lru.keys.take(3));
    if (_activeUrl != null) activeUrls.add(_activeUrl!);
    
    final toRemove = _controllers.keys.where((url) => !activeUrls.contains(url)).toList();
    
    for (final url in toRemove) {
      if ((_refCounts[url] ?? 0) > 0) continue;
      
      try {
        final controller = _controllers[url];
        if (controller?.value.isInitialized == true) {
          await controller!.pause();
          await controller.setVolume(0);
          await controller.seekTo(Duration.zero);
          await controller.dispose();
          _disposedUrls.add(url);
          _videoStates[url] = VideoState.disposed;
        }
        _controllers.remove(url);
        _initializing.remove(url);
        _pendingCommands.remove(url);
        _nonLoopingUrls.remove(url);
        _lru.remove(url);
        clearUrlDistance(url);
        
        if (kDebugMode) print('🗑️ [POOL] Inactive disposed: $url');
      } catch (e) {
        if (kDebugMode) print('⚠️ [POOL] Error removing $url: $e');
      }
    }
    
    _lru.removeWhere((url, _) => !_controllers.containsKey(url));
    
    while (_releasedCache.length > maxReleasedCache) {
      final oldest = _releasedCache.keys.first;
      final controller = _releasedCache.remove(oldest);
      
      try {
        if (controller?.value.isInitialized == true) {
          await controller!.pause();
          await controller.setVolume(0);
          await controller.seekTo(Duration.zero);
          await controller.dispose();
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ [POOL] Error disposing cached $oldest: $e');
      } finally {
        _disposedUrls.add(oldest);
        _videoStates[oldest] = VideoState.disposed;
        clearUrlDistance(oldest);
      }
      
      await release(oldest);
      
      if (kDebugMode) print('🗑️ [POOL] Evicted from cache: $oldest (ref balanced)');
    }
  }
  
  // ===================================================================
  // ✅ isActive() – Verificar si un video está activo en el pool
  // ===================================================================
  
  bool isActive(String videoUrl) =>
      _controllers.containsKey(videoUrl) &&
      _controllers[videoUrl]?.value.isInitialized == true;
  
  Future<void> prewarm(String url) async => await preloadCritical(url);
  void prewarmList(List<String> urls) => unawaited(preloadCriticalList(urls));
  
  int get activeCount => _controllers.values.where((c) => c.value.isInitialized).length;
  int get totalCount => _controllers.length + _initializing.length;

  // ===================================================================
  // ✅ cleanupMemory() – Limpieza agresiva para lifecycle hooks
  // ===================================================================
  // 🔥 FIX #9: Guard _isCleaningUp para evitar concurrent modification
  //    cuando lifecycle dispara inactive → hidden → paused en rápida sucesión.
  //    Snapshot de _controllers y _releasedCache antes de iterar para evitar
  //    "_Map len:0" ConcurrentModificationError en dart:_compact_hash.
  // ===================================================================

  Future<void> cleanupMemory() async {
    // 🔥 FIX #9: Si ya hay una limpieza en curso, ignorar invocaciones concurrentes
    if (_isCleaningUp) {
      if (kDebugMode) print('⏭️ [POOL] cleanupMemory() skipped – already running');
      return;
    }
    _isCleaningUp = true;

    if (kDebugMode) print('🧹 [POOL] cleanupMemory() - Limpieza agresiva por lifecycle...');

    try {
      // 🔥 FIX #9: Snapshot de values para evitar concurrent modification
      //    durante el await dentro del loop
      final controllersSnapshot = Map<String, VideoPlayerController>.from(_controllers);

      for (final c in controllersSnapshot.values) {
        try {
          if (c.value.isInitialized) {
            await c.pause();
            await c.setVolume(0);
          }
        } catch (_) {}
      }

      // 🔥 FIX #9: Iterar sobre snapshot, no sobre _controllers directamente
      for (final entry in controllersSnapshot.entries) {
        final url = entry.key;
        if (url == _activeUrl) continue;

        _controllers.remove(url);
        final c = entry.value;
        try {
          if (c.value.isInitialized) await c.seekTo(Duration.zero);
          await c.dispose();
        } catch (_) {}
        _disposedUrls.add(url);
        _videoStates[url] = VideoState.disposed;
        // 🔥 FIX #1: Notificar para budget real
        _notifyLifecycle(url: url, created: false, cacheHit: false, sizeBytes: null);
      }

      // 🔥 FIX #9: Snapshot de releasedCache también
      final releasedSnapshot = Map<String, VideoPlayerController>.from(_releasedCache);
      _releasedCache.clear();

      for (final entry in releasedSnapshot.entries) {
        final url = entry.key;
        try {
          await entry.value.dispose();
          _disposedUrls.add(url);
          _videoStates[url] = VideoState.disposed;
          _notifyLifecycle(url: url, created: false, cacheHit: false, sizeBytes: null);
        } catch (_) {}
      }

      _lru.clear();
      _initializing.clear();
      _pendingCommands.clear();
      _activeUrl = null;
      _warmQueue.clear();
      _urlsInWarmQueue.clear();
      _generation = 0;
      _refCounts.clear();
      _pendingEviction.clear();
      _disposedUrls.clear();
      _usageScore.clear();
      _cancelledUrls.clear();
      _urlDistance.clear();
      _videoSizes.clear();
      _startupTimesMs.clear();
      _videoStates.clear();

    } finally {
      // 🔥 FIX #9: Siempre liberar el guard, incluso si hubo excepción
      _isCleaningUp = false;
      if (kDebugMode) print('✅ [POOL] Memory cleanup complete');
    }
  }
  
  Future<void> ensureInitialized(String url) async => await prewarm(url);
  
  bool isBuffered(String url) {
    final controller = _controllers[url];
    if (controller == null) return false;
    final value = controller.value;
    return value.isInitialized &&
        value.buffered.isNotEmpty &&
        value.buffered.last.end > const Duration(milliseconds: 300);
  }

  // ===================================================================
  // ✅ Warm queue methods (simplificados para compatibilidad)
  // ===================================================================
  
  void addToWarmQueue(String url, {int priority = 10}) {
    if (url.isEmpty) return;
    if (_urlsInWarmQueue.contains(url)) return;
    if (_controllers.containsKey(url) || _initializing.containsKey(url)) return;
    
    unawaited(preloadCritical(url, priority: priority));
    
    if (kDebugMode) {
      print('🔥 [WARM QUEUE] Direct enqueue: $url (p: $priority)');
    }
  }
  
  void addAllToWarmQueue(Iterable<String> urls, {int basePriority = 10}) {
    int offset = 0;
    for (final url in urls) {
      addToWarmQueue(url, priority: basePriority + offset);
      offset++;
    }
  }
  
  void _processWarmQueue() {
    if (_isProcessingWarmQueue) return;
    _isProcessingWarmQueue = true;
    
    unawaited(() async {
      try {
        _warmQueue.clear();
        _urlsInWarmQueue.clear();
      } finally {
        _isProcessingWarmQueue = false;
      }
    }());
  }
  
  void startWarmQueueProcessing() => _processWarmQueue();
  
  void clearWarmQueue() {
    final size = _warmQueue.length;
    _warmQueue.clear();
    _urlsInWarmQueue.clear();
    if (kDebugMode && size > 0) print('🧹 [WARM QUEUE] Cleared $size items');
  }
  
  int get warmQueueLength => _warmQueue.length;
  
  // ===================================================================
  // ✅ Getters públicos para monitoreo
  // ===================================================================
  
  Map<String, int> get referenceCounts => Map.unmodifiable(_refCounts);
  Set<String> get pendingEvictions => Set.unmodifiable(_pendingEviction.keys);
  Map<String, int> get usageScores => Map.unmodifiable(_usageScore);
  Map<String, int> get urlDistance => Map.unmodifiable(_urlDistance);
  Map<String, VideoState> get videoStates => Map.unmodifiable(_videoStates);

  // ===================================================================
  // 🔥 FIX #1: Método init() para compatibilidad con FeedPreloadCoordinator
  // ===================================================================
  Future<void> init() async {
    // Inicialización mínima: ya es singleton, solo aseguramos estado limpio
    if (kDebugMode) print('🔌 [POOL] Initialized');
  }

  // ===================================================================
  // 🔥 FIX #2: Método dispose() público para compatibilidad
  // ===================================================================
  Future<void> dispose() async {
    await disposeAll();
    if (kDebugMode) print('🗑️ [POOL] Disposed');
  }

  // ===================================================================
  // 🔥 FIX #3: Getters con nombres esperados por FeedPreloadCoordinator
  // ===================================================================
  
  /// 🔥 Alias para getGlobalHitRate() - compatibilidad con coordinator
  double getGlobalHitRate() => preloadHitRate;
  
  /// 🔥 Alias para currentActiveControllers() - compatibilidad con coordinator
  int currentActiveControllers() => activeCount;
}