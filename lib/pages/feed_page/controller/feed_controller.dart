// lib/pages/feed_page/controller/feed_controller.dart
// ===================================================================
// FEED CONTROLLER v2.5-fix – MEMORY SAFE + MULTI-TAG REBUILD + LOQUIERO
// ===================================================================
// ✅ FIX: pageController.dispose() en onClose() para evitar memory leak
// ✅ FIX: update(['feed_state', 'feed_items']) para rebuild del PageView
// ✅ FIX: Logs estratégicos en kDebugMode para diagnóstico de errores
// ✅ FIX: updateReelInteraction ahora soporta isLoQuiero
// ✅ Mantiene: Arquitectura desacoplada, zero UI deps, SSOT, preload por ID
// ===================================================================

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:opole/core/feed/feed_config.dart';
import 'package:opole/core/feed/feed_item_model.dart';
import 'package:opole/core/feed/opole_feed_engine.dart';
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/core/video/video_controller_pool.dart';
import 'package:opole/core/video/video_preload_manager.dart';
import 'package:opole/controllers/session_controller.dart';

import '../../../core/feed/feed_cursor_manager.dart';
import '../../../core/feed/feed_deduplicator.dart';
import '../../../core/feed/feed_execution_context.dart';
import '../../../core/feed/feed_interaction_bridge.dart';
import '../../../core/feed/feed_playback_coordinator.dart';
import '../../../core/feed/feed_preload_coordinator.dart';
import '../../../core/feed/feed_repository.dart';
import '../../../core/feed/feed_state_updater.dart';
import '../../../core/feed/feed_engagement_tracker.dart';
import '../../../core/feed/preload_budget_tracker.dart';

class FeedController extends GetxController {
  // 🧠 ESTADO REACTIVO (SSOT)
  final RxList<FeedItem> feedItems = <FeedItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isReady = false.obs;
  final RxBool hasMore = true.obs;
  final RxInt currentVisibleIndex = 0.obs;
  final RxString feedState = 'waiting'.obs;
  final RxBool isUserPaused = false.obs;

  // 🛡️ ANTI-RACE
  int _currentRequestId = 0;
  int _generation = 0;

  // 🔥 Flag para prevenir trabajo post-dispose
  bool _isClosed = false;

  // 🌐 CONECTIVIDAD
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // 🧩 DELEGADOS
  late final FeedDeduplicator _deduplicator;
  late final FeedCursorManager _cursorManager;
  late final FeedRepository _repository;
  late final FeedStateUpdater _stateUpdater;
  late final FeedInteractionBridge _interactionBridge;
  late final FeedPlaybackCoordinator _playbackCoordinator;
  
  // Singleton del engagement tracker
  final FeedPreloadCoordinator _preloadCoordinator = FeedPreloadCoordinator.instance;
  final FeedEngagementTracker _engagementTracker = FeedEngagementTracker.instance;

  // 🔗 CONTEXT PROVIDER + HELPERS
  late final FeedExecutionContext Function() _contextProvider;
  late final String? Function(int) _getVideoUrl;
  late final String? Function(int) _getReelId;
  late final bool Function() _isWifi;
  late final int Function() _getItemCount;

  final OpoleFeedEngine _feedEngine = OpoleFeedEngine.instance;
  final VideoControllerPool _pool = VideoControllerPool.instance;
  final VideoPreloadManager _preloadManager = VideoPreloadManager.instance;
  final Connectivity _connectivity = Connectivity();
  SessionController get _session => SessionController.to;

  // 🔥 Tracking para UserType classification
  DateTime? _lastPageChangeTime;
  int _previousVisibleIndex = 0;

  @override
  void onInit() {
    super.onInit();
    _isClosed = false;
    if (kDebugMode) debugPrint('🧠 [FEED] onInit() - Controller creado');
    _initDelegates();
    _initConnectivity();
    _startFeedLoad();
  }

  void _initDelegates() {
    _contextProvider = () => FeedExecutionContext(
      generation: _generation,
      requestId: _currentRequestId,
      userId: _session.uid.isNotEmpty ? _session.uid : null,
      currentIndex: currentVisibleIndex.value,
      isUserPaused: isUserPaused.value,
      hasMore: hasMore.value,
      isLoading: isLoading.value,
    );

    _getVideoUrl = (index) {
      if (index < 0 || index >= feedItems.length) return null;
      final item = feedItems[index];
      return item is ReelFeedItem ? item.reel.videoUrl : null;
    };
    
    _getReelId = (index) {
      if (index < 0 || index >= feedItems.length) return null;
      final item = feedItems[index];
      return item is ReelFeedItem ? item.reel.id : null;
    };

    _isWifi = () => _connectionStatus == ConnectivityResult.wifi;
    _getItemCount = () => feedItems.length;

    _deduplicator = FeedDeduplicator();
    _cursorManager = FeedCursorManager();
    _repository = FeedRepository(
      engine: _feedEngine,
      cursorManager: _cursorManager,
      deduplicator: _deduplicator,
    );
    _stateUpdater = FeedStateUpdater(
      feedItems: feedItems,
      contextProvider: _contextProvider,
    );
    _interactionBridge = FeedInteractionBridge(
      contextProvider: _contextProvider,
      stateUpdater: _stateUpdater,
    );

    _playbackCoordinator = FeedPlaybackCoordinator(
      contextProvider: _contextProvider,
      pool: _pool,
      getVideoUrl: _getVideoUrl,
    );
    
    if (kDebugMode) debugPrint('🔧 [FEED] Delegates inicializados');
  }

  void _initConnectivity() {
    _connectivity.checkConnectivity().then((results) {
      if (results.isNotEmpty) {
        _connectionStatus = results.first;
        _preloadCoordinator.updateConnectionType(_connectionStatus == ConnectivityResult.wifi);
        if (kDebugMode) debugPrint('📶 [CONNECTIVITY] Inicial: $_connectionStatus');
      }
    });

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _connectionStatus = results.first;
        _preloadCoordinator.updateConnectionType(_connectionStatus == ConnectivityResult.wifi);
        if (kDebugMode) debugPrint('📶 [CONNECTIVITY] Cambio: $_connectionStatus');
      }
    });
  }

  @override
  void onClose() {
    if (kDebugMode) debugPrint('🧹 [FEED] onClose() - Limpiando recursos');
    _isClosed = true;
    _connectivitySub?.cancel();
    _connectivitySub = null;

    // 🔥 FIX: Dispose PageController para evitar memory leak crítico
    try {
      pageController.dispose();
      if (kDebugMode) debugPrint('✅ [FEED] PageController disposed');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [FEED] Error disposing PageController: $e');
    }

    _interactionBridge.dispose();
    _playbackCoordinator.dispose();
    _preloadCoordinator.dispose();
    _engagementTracker.dispose();
    _stateUpdater.clear();
    _deduplicator.clear();
    
    if (kDebugMode) debugPrint('✅ [FEED] Recursos liberados correctamente');
    super.onClose();
  }

  Future<void> _initCoordinators() async {
    await _preloadCoordinator.init();
    _pool.setIsWifi(_isWifi());
    if (kDebugMode) debugPrint('🧠 [FEED] Coordinators initialized');
  }

  void _startFeedLoad() async {
    await _initCoordinators();
    fetchFeed(forceLoad: true);
  }

  Future<void> fetchFeed({bool refresh = false, bool forceLoad = false}) async {
    if (_isClosed) {
      if (kDebugMode) debugPrint('⚠️ [FEED] fetchFeed() ignorado: controller cerrado');
      return;
    }
    
    final requestId = ++_currentRequestId;
    if (!_session.isReady && !forceLoad) {
      if (kDebugMode) debugPrint('⏳ [FEED] Esperando sesión ready');
      return;
    }
    if (isLoading.value && !refresh) {
      if (kDebugMode) debugPrint('⏳ [FEED] Ya está cargando, skip');
      return;
    }

    if (refresh) {
      _generation++;
      _deduplicator.clear();
      _cursorManager.reset();
      _stateUpdater.clear();
      hasMore.value = true;
      if (kDebugMode) debugPrint('🔄 [FEED] Refresh iniciado - generación $_generation');
    }

    isLoading.value = true;
    feedState.value = 'loading';

    try {
      final start = DateTime.now();
      final items = await _repository.fetchNextPage(
        userId: _session.uid,
        limit: FeedConfig.pageSize,
        refresh: refresh,
      );
      if (kDebugMode) {
        final ms = DateTime.now().difference(start).inMilliseconds;
        debugPrint('📊 [FETCH] ${items.length} items in ${ms}ms | req: $requestId');
      }

      if (requestId != _currentRequestId) {
        if (kDebugMode) debugPrint('⚠️ [FEED] Request obsoleto, ignorando respuesta');
        return;
      }

      if (items.isEmpty) {
        hasMore.value = false;
        feedState.value = feedItems.isEmpty ? 'empty' : 'ready';
        isReady.value = true;
        // 🔥 FIX: Notificar rebuild incluso si está vacío
        update(['feed_state', 'feed_items']);
        if (kDebugMode) debugPrint('📭 [FEED] No hay más items');
        return;
      }

      _stateUpdater.applyBatch(items, isRefresh: refresh);
      _stateUpdater.trimIfNeeded(currentVisibleIndex.value);
      _registerContentMetadata(items);
      
      // 🔥 FIX: Disparar preload inicial manual
      _triggerInitialPreload();
      
      // 🔥 FIX: Notificar rebuild con tags múltiples para PageView + estado
      update(['feed_state', 'feed_items']);
      
      isReady.value = true;
      feedState.value = 'ready';
      
      if (kDebugMode) {
        debugPrint('✅ [FEED] Feed actualizado: ${feedItems.length} items, state: ${feedState.value}');
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('❌ [FETCH] Error: $e\n$st');
      feedState.value = 'session_error';
      isReady.value = false;
      update(['feed_state', 'feed_items']);
    } finally {
      isLoading.value = false;
    }
  }
  
  void _triggerInitialPreload() {
    if (_isClosed || feedItems.isEmpty) return;
    
    final reelIds = feedItems
        .whereType<ReelFeedItem>()
        .map((item) => item.reel.id)
        .toList();

    final contentMetadata = Map.fromEntries(
      feedItems.whereType<ReelFeedItem>().map((item) => MapEntry(item.reel.id, item.reel)),
    );

    _preloadCoordinator.onScrollUpdate(
      currentIndex: currentVisibleIndex.value,
      previousIndex: currentVisibleIndex.value,
      velocityPx: 0.0,
      feedItems: reelIds,
      visibleItemIds: [],
      currentVideoDuration: _getVideoDuration(currentVisibleIndex.value),
      contentMetadata: contentMetadata,
    );
    
    if (kDebugMode) debugPrint('🚀 [PRELOAD] Trigger inicial con ${reelIds.length} reel IDs');
  }
  
  void _registerContentMetadata(List<FeedItem> items) {
    for (final item in items) {
      if (item is ReelFeedItem) {
        _preloadCoordinator.registerReel(item.reel);
      }
    }
    if (kDebugMode && items.isNotEmpty) {
      debugPrint('📦 [METADATA] Registered ${items.length} reels');
    }
  }

  final PageController pageController = PageController();

  void onPageChanged(int index) {
    if (_isClosed) {
      if (kDebugMode) debugPrint('⚠️ [FEED] onPageChanged ignorado: controller cerrado');
      return;
    }
    
    final now = DateTime.now();
    final delta = _lastPageChangeTime != null 
        ? now.difference(_lastPageChangeTime!) 
        : Duration.zero;
    _lastPageChangeTime = now;

    final prevIndex = _previousVisibleIndex;
    _previousVisibleIndex = index;
    
    final direction = index > prevIndex ? 1 : -1;
    final velocityPx = delta.inMilliseconds > 0 
        ? (index - prevIndex).abs() / delta.inMilliseconds 
        : 0.0;
    
    final reelIds = feedItems
        .whereType<ReelFeedItem>()
        .map((item) => item.reel.id)
        .toList();

    final contentMetadata = Map.fromEntries(
      feedItems.whereType<ReelFeedItem>().map((item) => MapEntry(item.reel.id, item.reel)),
    );

    _preloadCoordinator.onScrollUpdate(
      currentIndex: index,
      previousIndex: prevIndex,
      velocityPx: velocityPx,
      feedItems: reelIds,
      visibleItemIds: [
        if (index > 0 && index < feedItems.length) _getReelId(index),
        if (index + 1 < feedItems.length) _getReelId(index + 1),
      ].where((id) => id != null).cast<String>().toList(),
      currentVideoDuration: _getVideoDuration(index),
      contentMetadata: contentMetadata,
    );
    
    _recordReelMetrics(index, velocityPx, delta);

    _generation++;
    currentVisibleIndex.value = index;

    final ctx = _contextProvider();
    unawaited(_playbackCoordinator.onPageChanged(ctx));

    if (hasMore.value && !isLoading.value && index >= feedItems.length - FeedConfig.preloadTriggerThreshold) {
      if (kDebugMode) debugPrint('📥 [FEED] Triggering loadMore en índice $index');
      unawaited(fetchFeed());
    }
  }
  
  void _recordReelMetrics(int index, double velocityPx, Duration delta) {
    if (_isClosed) return;
    final reelId = _getReelId(index);
    if (reelId == null) return;
    
    final dwellTimeMs = delta.inMilliseconds;
    final wasSkipped = dwellTimeMs < 1000;
    
    _preloadCoordinator.recordReelMetrics(
      reelId: reelId,
      velocity: velocityPx,
      dwellTimeMs: dwellTimeMs,
      wasSkipped: wasSkipped,
    );
  }
  
  Duration? _getVideoDuration(int index) {
    if (index < 0 || index >= feedItems.length) return null;
    final item = feedItems[index];
    if (item is ReelFeedItem && item.reel.duration != null) {
      return Duration(seconds: item.reel.duration!);
    }
    return null;
  }

  // ===================================================================
  // 🔥 ENGAGEMENT TRACKING
  // ===================================================================
  
  Future<void> toggleLike(String reelId) async {
    if (kDebugMode) debugPrint('🔍 [LIKE] Iniciando toggleLike para reel: $reelId');
    
    if (_isClosed) {
      if (kDebugMode) debugPrint('⚠️ [LIKE] Ignorado: controller cerrado');
      return;
    }
    
    await _interactionBridge.toggleLike(reelId);
    _engagementTracker.registerPositiveInteraction(reelId);
    
    if (kDebugMode) debugPrint('✅ [LIKE] Toggle completado para reel: $reelId');
  }

  Future<void> registerInterest(String reelId) async {
    if (_isClosed) return;
    await _interactionBridge.registerInterest(reelId);
    _engagementTracker.registerPositiveInteraction(reelId);
  }

  void onVideoStarted(String reelId, String videoUrl, Duration startupTime) {
    if (_isClosed) return;
    _pool.recordStartupTime(videoUrl, startupTime);
    _engagementTracker.onVisible(reelId);
    _preloadCoordinator.onReelVisible(
      reelId: reelId,
      videoUrl: videoUrl,
      videoDuration: _getVideoDurationForReel(reelId),
    );
  }
  
  void onVideoHidden(String reelId, String videoUrl) {
    if (_isClosed) return;
    _engagementTracker.onHidden(reelId);
    _preloadCoordinator.onReelHidden(
      reelId: reelId,
      videoUrl: videoUrl,
      videoDuration: _getVideoDurationForReel(reelId),
    );
  }
  
  Duration? _getVideoDurationForReel(String reelId) {
    for (final item in feedItems) {
      if (item is ReelFeedItem && item.reel.id == reelId) {
        return item.reel.duration != null
            ? Duration(seconds: item.reel.duration!)
            : null;
      }
    }
    return null;
  }

  // ===================================================================
  // 🎮 INTERACCIONES (DELEGADAS + COMPATIBILIDAD)
  // ===================================================================
  
  @Deprecated('Use interactionBridge.toggleLike')
  Future<void> toggleLikeLegacy(String reelId) => toggleLike(reelId);

  @Deprecated('Use interactionBridge.registerInterest')
  Future<void> registerInterestLegacy(String reelId) => registerInterest(reelId);

  @Deprecated('Use interactionBridge.reportReel')
  Future<void> reportReel(String reelId, String motivo, {String? detalles}) =>
      _interactionBridge.reportReel(reelId, motivo, detalles: detalles);

  @Deprecated('Use interactionBridge.shareReel')
  Future<void> shareReel(String reelId) => _interactionBridge.shareReel(reelId);

  @Deprecated('Use interactionBridge.openUserProfile')
  void openUserProfile(String userId) => _interactionBridge.openUserProfile(userId);

  @Deprecated('Use interactionBridge.onCategorySelected')
  void onCategorySelected(String category) => _interactionBridge.onCategorySelected(category);

  // ===================================================================
  // 🧰 UI CONTRACTS
  // ===================================================================
  
  bool get shouldShowLoading => feedState.value == 'waiting' || feedState.value == 'loading';
  bool get shouldShowEmpty => feedState.value == 'empty';
  bool get shouldShowError => feedState.value == 'session_error';
  bool get shouldShowFeed => feedState.value == 'ready' && feedItems.isNotEmpty;

  // ===================================================================
  // 🔍 ACCESSORS + MÉTRICAS PARA DEBUG
  // ===================================================================
  
  FeedExecutionContext get context => _contextProvider();
  FeedInteractionBridge get interactionBridge => _interactionBridge;
  FeedStateUpdater get stateUpdater => _stateUpdater;
  IPlaybackCoordinator get playbackCoordinator => _playbackCoordinator;
  FeedPreloadCoordinator get preloadCoordinator => _preloadCoordinator;
  
  Map<String, dynamic> get debugStats => {
    'feed_items': feedItems.length,
    'current_index': currentVisibleIndex.value,
    'feed_state': feedState.value,
    'is_ready': isReady.value,
    'has_more': hasMore.value,
    'is_loading': isLoading.value,
    'connection': _connectionStatus.toString(),
    'preload_stats': _preloadCoordinator.getStats(),
    'pool_stats': _pool.debugPoolState,
    'engagement_tracked': _engagementTracker.getViewCount(''),
  };

  Future<void> loadMore() => fetchFeed();
  Future<void> refreshFeed() => fetchFeed(refresh: true);

  // ===================================================================
  // 🔌 COMPATIBILITY BRIDGE
  // ===================================================================

  Future<void> pauseAllVideos() async {
    if (_isClosed) return;
    isUserPaused.value = true;
    await _playbackCoordinator.pauseAll();
  }

  void resumeActiveVideo() {
    if (_isClosed) return;
    isUserPaused.value = false;
    _playbackCoordinator.resumeActive();
  }

  ReelModel? getReelById(String reelId) => _stateUpdater.getReelById(reelId);

  IInteractionBridge get interactionController => _interactionBridge;

  // ===================================================================
  // 🔥 UPDATE REEL INTERACTION – CON SOPORTE isLoQuiero
  // ===================================================================
  void updateReelInteraction({
    required String reelId,
    bool? isLiked,
    bool? isLoQuiero,  // ← NUEVO: aceptar estado de Lo Quiero
    int? likesCount,
  }) {
    if (_isClosed) return;
    _stateUpdater.updateItem(
      reelId: reelId,
      expectedGeneration: _generation,
      transformer: (r) => r.copyWith(
        isLiked: isLiked ?? r.isLiked,
        isLoQuiero: isLoQuiero ?? r.isLoQuiero,  // ← NUEVO: actualizar campo
        likesCount: likesCount ?? r.likesCount,
      ),
    );
  }

  String? get lastError =>
      feedState.value == 'session_error' ? 'Error de sesión' : null;

  int getQuestionsCount(String reelId) => 0;

  void onSessionError(String message) {
    if (_isClosed) return;
    feedState.value = 'session_error';
    isReady.value = false;
    if (kDebugMode) debugPrint('⚠️ [FEED] Session error: $message');
  }
}