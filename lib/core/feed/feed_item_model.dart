// lib/core/feed/feed_item_model.dart
// ===================================================================
// FEED ITEM MODEL v2.1 - PRODUCTION SAFE
// ===================================================================
// ✅ == / hashCode para reactividad GetX confiable
// ✅ Constructor de AdFeedItem simplificado (sin redundancias)
// ✅ badgeLabel con currentTime inyectable + caching
// ✅ Validación de contenido visual en Ads
// ✅ Analytics callbacks para integración con AdInserter v2.0
// ✅ FIX: videoUrl nullable (String?) para posts de imagen
// ✅ FIX: isBoosted sin ?? false innecesario
// ✅ NUEVO: imageUrls, postType, isVideo, isImagePost delegados
// ===================================================================

import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:flutter/foundation.dart';

// ===================================================================
// 🔹 CLASE BASE ABSTRACTA
// ===================================================================
abstract class FeedItem {
  String get id;
  String? get videoUrl;       // ✅ nullable: posts de imagen no tienen video

  bool get isBoosted => false;
  int get position => 0;
  String? get thumbnailUrl;
  String? get title;
  String? get description;
}

// ===================================================================
// 🔹 REEL como item del feed
// ===================================================================
class ReelFeedItem implements FeedItem {
  @override
  final String id;
  final ReelModel reel;
  final double calculatedRankingScore;
  final double calculatedBoostScore;

  // Cache no-final para cálculo perezoso
  String? _cachedBadgeLabel;
  int? _cachedBadgeColorValue;

  ReelFeedItem({
    required this.reel,
    required this.calculatedRankingScore,
    required this.calculatedBoostScore,
  }) : id = reel.id;

  // ===================================================================
  // 🔹 OVERRIDES DE FeedItem
  // ===================================================================

  @override
  String? get videoUrl => reel.videoUrl;  // ✅ FIX: String? en lugar de String

  @override
  int get position => 0;

  @override
  String? get thumbnailUrl => reel.thumbnailUrl;

  @override
  String? get title => reel.title;

  @override
  String? get description => reel.description;

  @override
  bool get isBoosted => reel.isBoosted;   // ✅ FIX: isBoosted ya es bool, sin ?? false

  // ===================================================================
  // 🔹 GETTERS DELEGADOS — existentes
  // ===================================================================
  String? get province => reel.province;
  String? get locality => reel.locality;
  int? get likesCount => reel.likesCount;
  int? get commentsCount => reel.commentsCount;
  int? get loQuieroCount => reel.loQuieroCount;
  int? get shareCount => reel.shareCount;
  int? get viewCount => reel.viewCount;
  int? get questionsCount => reel.questionsCount;
  double get rankingScore => calculatedRankingScore;
  double get boostScore => calculatedBoostScore;
  double? get geoPriority => reel.geoPriority;
  double? get interestPriority => reel.interestPriority;
  DateTime? get createdAt => reel.createdAt;
  String? get userId => reel.userId;
  String? get userUsername => reel.userUsername;
  String? get userRealName => reel.userRealName;
  String? get condition => reel.condition;
  num? get price => reel.price;
  List<String>? get categories => reel.categories;
  List<String>? get shippingMethods => reel.shippingMethods;
  List<String>? get paymentMethods => reel.paymentMethods;
  List<String>? get hashtags => reel.hashtags;
  String? get priorityBoostType => reel.priorityBoostType;

  // ===================================================================
  // ✅ NUEVO: Getters delegados para feed mixto video/imagen
  // ===================================================================
  List<String> get imageUrls => reel.imageUrls;
  PostType get postType => reel.postType;
  bool get isVideo => reel.isVideo;
  bool get isImagePost => reel.isImagePost;

  // ===================================================================
  // 🔹 GETTERS CON CACHÉ PEREZOSO
  // ===================================================================
  String? get badgeLabel {
    if (_cachedBadgeLabel != null) return _cachedBadgeLabel;
    _computeBadge();
    return _cachedBadgeLabel;
  }

  int? get badgeColorValue {
    if (_cachedBadgeColorValue != null) return _cachedBadgeColorValue;
    _computeBadge();
    return _cachedBadgeColorValue;
  }

  void _computeBadge({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    String? badge;
    int? color;

    if (reel.isBoosted && (reel.boostScore ?? 0) > 0.5) {
      badge = "DESTACADO";
      color = 0xFFFFC107;
    } else if (calculatedRankingScore >= 0.85) {
      badge = "🔥 TRENDING";
      color = 0xFFFF9800;
    } else if (reel.createdAt != null) {
      final hoursSince = now.difference(reel.createdAt!).inHours;
      if (hoursSince < 48) {
        badge = "✨ NUEVO";
        color = 0xFF2196F3;
      }
    }

    _cachedBadgeLabel = badge;
    _cachedBadgeColorValue = color;
  }

  // Factory que permite inyectar currentTime para pruebas
  factory ReelFeedItem.withBadgeCache({
    required ReelModel reel,
    required double calculatedRankingScore,
    required double calculatedBoostScore,
    DateTime? currentTime,
  }) {
    final instance = ReelFeedItem(
      reel: reel,
      calculatedRankingScore: calculatedRankingScore,
      calculatedBoostScore: calculatedBoostScore,
    );
    instance._computeBadge(currentTime: currentTime);
    return instance;
  }

  // Constructor interno para copyWith
  ReelFeedItem._internal({
    required this.reel,
    required this.calculatedRankingScore,
    required this.calculatedBoostScore,
  }) : id = reel.id;

  // ===================================================================
  // 🔹 COPYWITH
  // ===================================================================
  ReelFeedItem copyWith({
    ReelModel? reel,
    double? calculatedRankingScore,
    double? calculatedBoostScore,
    bool recalculateBadge = false,
    DateTime? currentTime,
  }) {
    final newReel = reel ?? this.reel;
    final newRanking = calculatedRankingScore ?? this.calculatedRankingScore;
    final newBoost = calculatedBoostScore ?? this.calculatedBoostScore;

    final copy = ReelFeedItem._internal(
      reel: newReel,
      calculatedRankingScore: newRanking,
      calculatedBoostScore: newBoost,
    );

    if (recalculateBadge) {
      copy._computeBadge(currentTime: currentTime);
    } else {
      copy._cachedBadgeLabel = _cachedBadgeLabel;
      copy._cachedBadgeColorValue = _cachedBadgeColorValue;
    }

    return copy;
  }

  // ===================================================================
  // 🔹 EQUALITY (GetX reactivo)
  // ===================================================================
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReelFeedItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          calculatedRankingScore == other.calculatedRankingScore &&
          calculatedBoostScore == other.calculatedBoostScore &&
          reel.isLiked == other.reel.isLiked &&
          reel.isLoQuiero == other.reel.isLoQuiero;

  @override
  int get hashCode =>
      id.hashCode ^
      calculatedRankingScore.hashCode ^
      calculatedBoostScore.hashCode ^
      reel.isLiked.hashCode ^
      reel.isLoQuiero.hashCode;
}

// ===================================================================
// 🔹 ANUNCIO como item del feed
// ===================================================================
class AdFeedItem implements FeedItem {
  @override
  final String id;

  final String? adVideoUrl;
  @override
  String? get videoUrl => adVideoUrl;

  final String adId;
  final String adTitle;
  final String? adSubtitle;
  final String? adImageUrl;
  final String? adClickUrl;

  @override
  final int position;
  @override
  final bool isBoosted;

  @override
  final String? thumbnailUrl;

  @override
  String get title => adTitle;
  @override
  String? get description => adSubtitle;

  final VoidCallback? onImpression;
  final VoidCallback? onClick;

  static const String _defaultPlaceholder = 'assets/images/ad_placeholder_default.png';

  AdFeedItem({
    required String adId,
    required String adTitle,
    String? adVideoUrl,
    String? adSubtitle,
    String? adImageUrl,
    String? adClickUrl,
    required int position,
    bool isBoosted = true,
    String? thumbnailUrl,
    this.onImpression,
    this.onClick,
  })  : adId = adId,
        id = adId,
        adTitle = adTitle,
        adVideoUrl = adVideoUrl?.isNotEmpty == true ? adVideoUrl : null,
        adSubtitle = adSubtitle,
        adImageUrl = adImageUrl,
        adClickUrl = adClickUrl,
        position = position,
        isBoosted = isBoosted,
        thumbnailUrl = thumbnailUrl ?? adImageUrl ?? _defaultPlaceholder;

  factory AdFeedItem.validated({
    required String adId,
    required String adTitle,
    String? adVideoUrl,
    String? adSubtitle,
    String? adImageUrl,
    String? adClickUrl,
    required int position,
    bool isBoosted = true,
    String? thumbnailUrl,
    VoidCallback? onImpression,
    VoidCallback? onClick,
  }) {
    assert(
      (adVideoUrl?.isNotEmpty == true) || (adImageUrl?.isNotEmpty == true),
      'AdFeedItem: debe tener adVideoUrl o adImageUrl',
    );
    return AdFeedItem(
      adId: adId,
      adTitle: adTitle,
      adVideoUrl: adVideoUrl,
      adSubtitle: adSubtitle,
      adImageUrl: adImageUrl,
      adClickUrl: adClickUrl,
      position: position,
      isBoosted: isBoosted,
      thumbnailUrl: thumbnailUrl,
      onImpression: onImpression,
      onClick: onClick,
    );
  }

  bool get hasVideo => adVideoUrl != null && adVideoUrl!.isNotEmpty;
  String get ctaText => 'Ver más';
  String get adType => 'feed_native';

  AdFeedItem copyWith({
    String? adId,
    String? adTitle,
    String? adVideoUrl,
    String? adSubtitle,
    String? adImageUrl,
    String? adClickUrl,
    int? position,
    bool? isBoosted,
    String? thumbnailUrl,
    VoidCallback? onImpression,
    VoidCallback? onClick,
  }) {
    return AdFeedItem(
      adId: adId ?? this.adId,
      adTitle: adTitle ?? this.adTitle,
      adVideoUrl: adVideoUrl ?? this.adVideoUrl,
      adSubtitle: adSubtitle ?? this.adSubtitle,
      adImageUrl: adImageUrl ?? this.adImageUrl,
      adClickUrl: adClickUrl ?? this.adClickUrl,
      position: position ?? this.position,
      isBoosted: isBoosted ?? this.isBoosted,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      onImpression: onImpression ?? this.onImpression,
      onClick: onClick ?? this.onClick,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdFeedItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          position == other.position &&
          adTitle == other.adTitle;

  @override
  int get hashCode => id.hashCode ^ position.hashCode ^ adTitle.hashCode;
}
