// lib/core/feed/feed_smart_preload_policy.dart
// ===================================================================
// FEED SMART PRELOAD POLICY v3.4 – TIKTOK-CLOSURE
// Shared enums + math.min() fix + adaptive budget/content/startup logic
// ===================================================================

import 'dart:math' as math;
import 'feed_prediction_engine.dart';
import 'feed_preload_coordinator.dart';
import '../models/user_engagement_mode.dart';

class FeedSmartPreloadPolicy {
  // Budgets explícitos por tipo de red
  static const int _maxPreloadBytesWifi = 50 * 1024 * 1024; // 50MB
  static const int _maxPreloadBytesMobile = 15 * 1024 * 1024; // 15MB
  
  // Umbrales de contenido para decisiones content-aware
  static const int _longVideoThresholdSec = 45;
  static const int _heavyVideoThresholdBytes = 8 * 1024 * 1024;
  
  // Controllers activos máximos por red
  static const int _maxControllersWifi = 7;
  static const int _maxControllersMobile = 4;
  
  // Flags para estrategia por UserType
  bool _isScannerMode = false;
  bool _isWatcherMode = false;
  bool _isWifi = true;

  void setScannerMode(bool value) => _isScannerMode = value;
  void setWatcherMode(bool value) => _isWatcherMode = value;
  void setIsWifi(bool value) => _isWifi = value;

  double _getDynamicLowThreshold(bool isWifi) => isWifi ? 45.0 : 35.0;
  double _getDynamicHighThreshold(bool isWifi) => isWifi ? 80.0 : 70.0;

  int get dynamicMaxControllers => _isWifi ? _maxControllersWifi : _maxControllersMobile;

  // ===================================================================
  // resolveForwardCount: lógica adaptativa con budget + content + startup
  // ===================================================================
  int resolveForwardCount({
    required bool isWifi,
    required ScrollVelocity velocity,
    required UserBrowsingMode mode,
    required ScrollDirection direction,
    required bool isHighIntent,
    required double hitRate,
    required double currentBudgetBytes,
    required double avgVideoSizeBytes,
    required double p95StartupMs,
    required Duration? avgVideoDuration,
  }) {
    final lowThreshold = _getDynamicLowThreshold(isWifi);
    final highThreshold = _getDynamicHighThreshold(isWifi);
    
    final maxBudget = isWifi ? _maxPreloadBytesWifi : _maxPreloadBytesMobile;
    final remainingBudget = (maxBudget - currentBudgetBytes).clamp(0.0, maxBudget);
    final avgVideoSize = avgVideoSizeBytes > 0 ? avgVideoSizeBytes : 3 * 1024 * 1024;
    final maxItemsByBudget = (remainingBudget / avgVideoSize).floor().clamp(1, 10);
    final maxByControllers = dynamicMaxControllers - 1;
    
    if (mode == UserBrowsingMode.bored) {
      return math.min(1, math.min(maxItemsByBudget, maxByControllers));
    }

    if (velocity == ScrollVelocity.fast && !isHighIntent) {
      return math.min(2, math.min(maxItemsByBudget, maxByControllers));
    }

    if (isHighIntent) {
      final startupAggression = p95StartupMs > 120 ? 2 : 0;
      
      if (hitRate < lowThreshold) {
        return math.min(
          (isWifi ? 6 + startupAggression : 4).clamp(1, maxItemsByBudget),
          maxByControllers,
        );
      }
      if (hitRate > highThreshold) {
        return math.min(3, math.min(maxItemsByBudget, maxByControllers));
      }
      
      if (avgVideoDuration != null && avgVideoDuration.inSeconds > _longVideoThresholdSec) {
        return math.min(
          (isWifi ? 6 : 4).clamp(1, maxItemsByBudget),
          maxByControllers,
        );
      }
      
      if (isWifi) return direction == ScrollDirection.forward ? 5 : 3;
      return math.min(3, math.min(maxItemsByBudget, maxByControllers));
    }

    if (mode == UserBrowsingMode.engaged || mode == UserBrowsingMode.focused) {
      if (_isScannerMode && isWifi && direction == ScrollDirection.forward) {
        return math.min(6, math.min(maxItemsByBudget, maxByControllers));
      }
      if (_isWatcherMode) {
        return math.min(
          (isWifi ? 4 : 2).clamp(1, maxItemsByBudget),
          maxByControllers,
        );
      }
      
      if (mode == UserBrowsingMode.focused && isWifi) {
        if (avgVideoDuration != null && avgVideoDuration.inSeconds > _longVideoThresholdSec) {
          return math.min(7, math.min(maxItemsByBudget, maxByControllers));
        }
        return math.min(6, math.min(maxItemsByBudget, maxByControllers));
      }
      
      if (hitRate < lowThreshold && isWifi) {
        return direction == ScrollDirection.forward ? 5 : 2;
      }
      if (hitRate > highThreshold) {
        return direction == ScrollDirection.forward ? 3 : 1;
      }
      
      if (isWifi) return direction == ScrollDirection.forward ? 5 : 2;
      return direction == ScrollDirection.forward ? 3 : 1;
    }

    if (hitRate < lowThreshold) {
      return math.min(
        (isWifi ? 4 : 2).clamp(1, maxItemsByBudget),
        maxByControllers,
      );
    }
    
    if (p95StartupMs > 150) {
      return math.min(
        (isWifi ? 4 : 3).clamp(1, maxItemsByBudget),
        maxByControllers,
      );
    }
    
    if (isWifi) {
      final base = direction == ScrollDirection.forward 
          ? (velocity == ScrollVelocity.slow ? 4 : 3)
          : 2;
      return math.min(base, math.min(maxItemsByBudget, maxByControllers));
    }
    return math.min(2, math.min(maxItemsByBudget, maxByControllers));
  }

  // ===================================================================
  // adjustPriorityForContent: prioridad invertida para pesados/largos
  // ===================================================================
  int adjustPriorityForContent({
    required int basePriority,
    required Duration? videoDuration,
    required int? videoSizeBytes,
    required bool isHighIntent,
  }) {
    int priority = basePriority;
    
    if (videoDuration != null && videoDuration.inSeconds > _longVideoThresholdSec) {
      priority = (priority - 1).clamp(1, 15);
    }
    
    if (videoSizeBytes != null && videoSizeBytes > _heavyVideoThresholdBytes) {
      priority = (priority - 1).clamp(1, 15);
    }
    
    if (isHighIntent) {
      if (videoDuration != null && videoDuration.inSeconds > _longVideoThresholdSec) {
        priority = (priority - 1).clamp(1, 15);
      }
      if (videoSizeBytes != null && videoSizeBytes > _heavyVideoThresholdBytes) {
        priority = (priority - 1).clamp(1, 15);
      }
    }
    
    return priority;
  }

  // ===================================================================
  // hasBudgetForVideo helper
  // ===================================================================
  bool hasBudgetForVideo({
    required bool isWifi,
    required double currentBudgetBytes,
    required int videoSizeBytes,
  }) {
    final maxBudget = isWifi ? _maxPreloadBytesWifi : _maxPreloadBytesMobile;
    return (currentBudgetBytes + videoSizeBytes) <= maxBudget;
  }

  // ===================================================================
  // resolveBackwardCount
  // ===================================================================
  int resolveBackwardCount({
    required bool isWifi,
    required ScrollVelocity velocity,
    required UserBrowsingMode mode,
    required ScrollDirection direction,
    required double hitRate,
  }) {
    final lowThreshold = _getDynamicLowThreshold(isWifi);
    
    if (mode == UserBrowsingMode.bored || direction == ScrollDirection.forward) {
      return 0;
    }
    
    if (direction == ScrollDirection.backward && velocity == ScrollVelocity.slow) {
      return isWifi ? 1 : 0;
    }
    
    if (velocity == ScrollVelocity.fast) {
      return 0;
    }
    
    if (isWifi && hitRate >= lowThreshold) {
      return 1;
    }
    
    return 0;
  }

  // ===================================================================
  // shouldAggressiveCancel
  // ===================================================================
  bool shouldAggressiveCancel({
    required UserBrowsingMode mode,
    required ScrollVelocity velocity,
    required double hitRate,
    required bool isWifi,
  }) {
    final lowThreshold = _getDynamicLowThreshold(isWifi);
    final highThreshold = _getDynamicHighThreshold(isWifi);

    if (mode == UserBrowsingMode.bored || velocity == ScrollVelocity.fast) {
      return true;
    }
    
    if (hitRate < lowThreshold) {
      return false;
    }
    
    if (hitRate > highThreshold) {
      return true;
    }
    
    return false;
  }

  // ===================================================================
  // shouldReduceWindow
  // ===================================================================
  bool shouldReduceWindow({
    required bool isLowBattery,
    required bool isMobileData,
    required double hitRate,
    required UserBrowsingMode mode,
    required bool isWifi,
  }) {
    final lowThreshold = _getDynamicLowThreshold(isWifi);

    if (isLowBattery && isMobileData) return true;
    if (hitRate < lowThreshold * 0.8) return true;
    if (mode == UserBrowsingMode.bored && isMobileData) return true;
    return false;
  }
}