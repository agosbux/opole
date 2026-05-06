// lib/core/supabase/models/reel_model.dart
// ===================================================================
// REEL MODEL - Modelo puro de reel para Opole
// ===================================================================
// • Parsing seguro con fallbacks para evitar crashes por null/typo
// • Helpers computados para lógica de UI (hasPrice, isExpired, canInteract, etc.)
// • Equality + hashCode (Equatable) para comparaciones eficientes en listas
// • toString() para debug limpio y legible
// • fromJsonList estático para parsing de arrays sin código repetido
// • Validación básica de campos requeridos con assert
// • Formateo de precio, ubicación y hashtags listo para UI
// • ✅ FIX: userPhotoUrl agregado para avatares en ReelCardWidget
// • ✅ FIX: Campos alineados con RPC get_opole_feed (full_name, username, views_count)
// • ✅ NUEVO: postType + imageUrls para feed mixto video/imagen
// ===================================================================

import 'package:equatable/equatable.dart';

// ===================================================================
// 🔹 POST TYPE — determina si el reel es video o galería de imágenes
// ===================================================================
enum PostType { video, image }

class ReelModel extends Equatable {
  final String id;
  final String userId;
  final String? videoUrl;       // ✅ nullable: posts de imagen no tienen video
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final num? price;
  final String? condition;
  final List<String>? categories;
  final String? province;
  final String? locality;
  final int? duration;
  final List<String>? shippingMethods;
  final List<String>? paymentMethods;
  final bool? isBot;

  // 📊 Engagement metrics
  final int? likesCount;
  final int? commentsCount;
  final int? loQuieroCount;
  final int? shareCount;
  final int? viewCount;
  final int? questionsCount;

  // 🏷️ Metadata adicional
  final List<String>? hashtags;
  final String? userRealName;
  final String? userUsername;
  final String? userPhotoUrl;

  // 🚀 Ranking & Boost
  final double? rankingScore;
  final double? boostScore;
  final double? geoPriority;
  final double? interestPriority;
  final String? boostType;
  final DateTime? boostExpiresAt;
  final String? priorityBoostType;
  final DateTime? priorityBoostExpiresAt;

  // 📦 Estado
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // 👤 Interacción del usuario actual
  final bool? isLiked;
  final bool? isLoQuiero;

  // ✅ NUEVO: tipo de post + imágenes (1-6 para posts de imagen)
  final PostType postType;
  final List<String> imageUrls;

  ReelModel({
    required this.id,
    required this.userId,
    this.videoUrl,                          // ✅ ya no required
    this.thumbnailUrl,
    this.title,
    this.description,
    this.price,
    this.condition,
    this.categories,
    this.province,
    this.locality,
    this.duration,
    this.shippingMethods,
    this.paymentMethods,
    this.isBot,
    this.likesCount,
    this.commentsCount,
    this.loQuieroCount,
    this.shareCount,
    this.viewCount,
    this.questionsCount,
    this.hashtags,
    this.userRealName,
    this.userUsername,
    this.userPhotoUrl,
    this.rankingScore,
    this.boostScore,
    this.geoPriority,
    this.interestPriority,
    this.boostType,
    this.boostExpiresAt,
    this.priorityBoostType,
    this.priorityBoostExpiresAt,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isLiked,
    this.isLoQuiero,
    this.postType = PostType.video,         // ✅ default video para retrocompatibilidad
    this.imageUrls = const [],              // ✅ vacío por defecto
  }) {
    assert(id.isNotEmpty, 'id no puede estar vacío');
    assert(userId.isNotEmpty, 'userId no puede estar vacío');
    assert(
      postType == PostType.video ? videoUrl != null && videoUrl!.isNotEmpty : imageUrls.isNotEmpty,
      'Un post de video requiere videoUrl. Un post de imagen requiere al menos 1 imagen.',
    );
    assert(
      imageUrls.length <= 6,
      'Un post de imagen no puede tener más de 6 imágenes.',
    );
  }

  // ===================================================================
  // 🔹 HELPERS DE TIPO
  // ===================================================================
  bool get isVideo => postType == PostType.video;
  bool get isImagePost => postType == PostType.image;

  /// Primera imagen para usar como thumbnail en posts de imagen
  String? get coverImageUrl => isImagePost && imageUrls.isNotEmpty ? imageUrls.first : null;

  /// URL de preview universal: thumbnail para video, primera imagen para galería
  String? get previewUrl => isVideo ? thumbnailUrl : coverImageUrl;

  // ===================================================================
  // 🔹 FACTORY: Parsing seguro desde JSON
  // ===================================================================
  factory ReelModel.fromJson(Map<String, dynamic> json) {
    final rawType = _safeGet<String>(json, 'post_type') ?? 'video';
    final postType = rawType == 'image' ? PostType.image : PostType.video;
    final imageUrls = _safeGetList<String>(json, 'image_urls') ?? [];

    return ReelModel(
      id: _safeGet<String>(json, 'id') ?? '',
      userId: _safeGet<String>(json, 'user_id') ?? '',
      videoUrl: _safeGet<String>(json, 'video_url'),
      thumbnailUrl: _safeGet<String>(json, 'thumbnail_url'),
      title: _safeGet<String>(json, 'title'),
      description: _safeGet<String>(json, 'description'),
      price: _safeGet<num>(json, 'price'),
      condition: _safeGet<String>(json, 'condition'),
      categories: _safeGetList<String>(json, 'categories'),
      province: _safeGet<String>(json, 'province'),
      locality: _safeGet<String>(json, 'locality'),
      duration: _safeGet<int>(json, 'duration'),
      shippingMethods: _safeGetList<String>(json, 'shipping_methods'),
      paymentMethods: _safeGetList<String>(json, 'payment_methods'),
      isBot: _safeGet<bool>(json, 'is_bot'),
      likesCount: _safeGet<int>(json, 'like_count'),
      commentsCount: _safeGet<int>(json, 'comments_count'),
      loQuieroCount: _safeGet<int>(json, 'lo_quiero_count'),
      shareCount: _safeGet<int>(json, 'share_count'),
      viewCount: _safeGet<int>(json, 'views_count'),
      questionsCount: _safeGet<int>(json, 'questions_count'),
      hashtags: _safeGetList<String>(json, 'hashtags'),
      userRealName: _safeGet<String>(json, 'full_name'),
      userUsername: _safeGet<String>(json, 'username'),
      userPhotoUrl: _safeGet<String>(json, 'user_photo_url'),
      rankingScore: _safeGet<num>(json, 'ranking_score')?.toDouble(),
      boostScore: _safeGet<num>(json, 'boost_score')?.toDouble(),
      geoPriority: _safeGet<num>(json, 'geo_priority')?.toDouble(),
      interestPriority: _safeGet<num>(json, 'interest_priority')?.toDouble(),
      boostType: _safeGet<String>(json, 'boost_type'),
      boostExpiresAt: _parseDateTime(json['boost_expires_at']),
      priorityBoostType: _safeGet<String>(json, 'priority_boost_type'),
      priorityBoostExpiresAt: _parseDateTime(json['priority_boost_expires_at']),
      status: _safeGet<String>(json, 'status'),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      isLiked: _safeGet<bool>(json, 'is_liked'),
      isLoQuiero: _safeGet<bool>(json, 'is_lo_quiero'),
      postType: postType,
      imageUrls: imageUrls,
    );
  }

  static List<ReelModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .where((item) => item is Map<String, dynamic>)
        .map((item) => ReelModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ===================================================================
  // 🔹 TO JSON
  // ===================================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'title': title,
      'description': description,
      'price': price,
      'condition': condition,
      'categories': categories,
      'province': province,
      'locality': locality,
      'duration': duration,
      'shipping_methods': shippingMethods,
      'payment_methods': paymentMethods,
      'is_bot': isBot,
      'like_count': likesCount,
      'comments_count': commentsCount,
      'lo_quiero_count': loQuieroCount,
      'share_count': shareCount,
      'views_count': viewCount,
      'questions_count': questionsCount,
      'hashtags': hashtags,
      'full_name': userRealName,
      'username': userUsername,
      'user_photo_url': userPhotoUrl,
      'ranking_score': rankingScore,
      'boost_score': boostScore,
      'geo_priority': geoPriority,
      'interest_priority': interestPriority,
      'boost_type': boostType,
      'boost_expires_at': boostExpiresAt?.toIso8601String(),
      'priority_boost_type': priorityBoostType,
      'priority_boost_expires_at': priorityBoostExpiresAt?.toIso8601String(),
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_liked': isLiked,
      'is_lo_quiero': isLoQuiero,
      'post_type': postType == PostType.image ? 'image' : 'video',  // ✅ NUEVO
      'image_urls': imageUrls,                                        // ✅ NUEVO
    };
  }

  // ===================================================================
  // 🔹 HELPERS COMPUTADOS
  // ===================================================================
  bool get hasPrice => price != null && price! > 0;
  String get formattedPrice {
    if (!hasPrice) return 'Consultar';
    return '\$ ${price!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  bool get hasLocation => province != null || locality != null;
  String get formattedLocation {
    if (locality != null && province != null) return '$locality, $province';
    return locality ?? province ?? 'Sin ubicación';
  }

  String get formattedDuration {
    if (duration == null) return '';
    final mins = duration! ~/ 60;
    final secs = duration! % 60;
    return mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
  }

  List<String> get validHashtags => hashtags?.where((h) => h.isNotEmpty).toList() ?? [];
  bool get hasHashtags => validHashtags.isNotEmpty;

  bool get isBoosted {
    final now = DateTime.now();
    final hasPriority = priorityBoostExpiresAt != null && priorityBoostExpiresAt!.isAfter(now);
    final hasRegular = boostExpiresAt != null && boostExpiresAt!.isAfter(now);
    return hasPriority || hasRegular;
  }

  bool get isPriorityBoosted {
    return priorityBoostType != null &&
        priorityBoostExpiresAt != null &&
        priorityBoostExpiresAt!.isAfter(DateTime.now());
  }

  bool get isActive => status == 'active';
  bool get isSold => status == 'sold';
  bool get isInactive => status == 'inactive' || status == 'deleted';
  bool get isExpired => false;

  String get displayName {
    if (userRealName?.isNotEmpty == true) return userRealName!;
    if (userUsername?.isNotEmpty == true) return '@$userUsername';
    return 'Usuario Opole';
  }

  String? get displayAvatar => userPhotoUrl;

  bool get userHasLiked => isLiked == true;
  bool get userHasLoQuiero => isLoQuiero == true;

  bool canInteract(String currentUserId) {
    return isActive && userId != currentUserId && (isBot ?? false) == false;
  }

  bool isOwnedBy(String userId) => this.userId == userId;

  String getPreviewDescription({int maxLength = 120}) {
    if (description == null || description!.isEmpty) return 'Sin descripción';
    if (description!.length <= maxLength) return description!;
    return '${description!.substring(0, maxLength).trim()}...';
  }

  String getPreviewTitle({int maxLength = 60}) {
    if (title == null || title!.isEmpty) return 'Sin título';
    if (title!.length <= maxLength) return title!;
    return '${title!.substring(0, maxLength).trim()}...';
  }

  int get totalEngagement {
    return (likesCount ?? 0) + (commentsCount ?? 0) + (loQuieroCount ?? 0) + (shareCount ?? 0);
  }

  // ===================================================================
  // 🔹 COPYWITH
  // ===================================================================
  ReelModel copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? thumbnailUrl,
    String? title,
    String? description,
    num? price,
    String? condition,
    List<String>? categories,
    String? province,
    String? locality,
    int? duration,
    List<String>? shippingMethods,
    List<String>? paymentMethods,
    bool? isBot,
    int? likesCount,
    int? commentsCount,
    int? loQuieroCount,
    int? shareCount,
    int? viewCount,
    int? questionsCount,
    List<String>? hashtags,
    String? userRealName,
    String? userUsername,
    String? userPhotoUrl,
    double? rankingScore,
    double? boostScore,
    double? geoPriority,
    double? interestPriority,
    String? boostType,
    DateTime? boostExpiresAt,
    String? priorityBoostType,
    DateTime? priorityBoostExpiresAt,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLiked,
    bool? isLoQuiero,
    PostType? postType,
    List<String>? imageUrls,
  }) {
    return ReelModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      categories: categories ?? this.categories,
      province: province ?? this.province,
      locality: locality ?? this.locality,
      duration: duration ?? this.duration,
      shippingMethods: shippingMethods ?? this.shippingMethods,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isBot: isBot ?? this.isBot,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      loQuieroCount: loQuieroCount ?? this.loQuieroCount,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      questionsCount: questionsCount ?? this.questionsCount,
      hashtags: hashtags ?? this.hashtags,
      userRealName: userRealName ?? this.userRealName,
      userUsername: userUsername ?? this.userUsername,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rankingScore: rankingScore ?? this.rankingScore,
      boostScore: boostScore ?? this.boostScore,
      geoPriority: geoPriority ?? this.geoPriority,
      interestPriority: interestPriority ?? this.interestPriority,
      boostType: boostType ?? this.boostType,
      boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
      priorityBoostType: priorityBoostType ?? this.priorityBoostType,
      priorityBoostExpiresAt: priorityBoostExpiresAt ?? this.priorityBoostExpiresAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLiked: isLiked ?? this.isLiked,
      isLoQuiero: isLoQuiero ?? this.isLoQuiero,
      postType: postType ?? this.postType,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  // ===================================================================
  // 🔹 EQUALITY (Equatable)
  // ===================================================================
  @override
  List<Object?> get props => [
        id, userId, videoUrl, thumbnailUrl, title, description, price, condition,
        categories, province, locality, duration, shippingMethods, paymentMethods,
        isBot, likesCount, commentsCount, loQuieroCount, shareCount, viewCount,
        questionsCount, hashtags, userRealName, userUsername, userPhotoUrl,
        rankingScore, boostScore, geoPriority, interestPriority, boostType,
        boostExpiresAt, priorityBoostType, priorityBoostExpiresAt, status,
        createdAt, updatedAt, isLiked, isLoQuiero,
        postType, imageUrls,                          // ✅ NUEVO en equality
      ];

  // ===================================================================
  // 🔹 TOSTRING
  // ===================================================================
  @override
  String toString() {
    return 'ReelModel('
        'id: ${id.substring(0, 8)}..., '
        'type: ${postType.name}, '
        'user: $displayName, '
        'title: "${getPreviewTitle(maxLength: 30)}", '
        'price: $formattedPrice, '
        'location: $formattedLocation, '
        'engagement: $totalEngagement, '
        'isBoosted: $isBoosted, '
        'isActive: $isActive'
        ')';
  }

  // ===================================================================
  // 🔹 UTILS PRIVADAS
  // ===================================================================
  static T? _safeGet<T>(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is T) return value;
    if (T == int && value is num) return value.toInt() as T?;
    if (T == double && value is num) return value.toDouble() as T?;
    if (T == String && value != null) return value.toString() as T?;
    if (T == bool && value is String) return (value.toLowerCase() == 'true') as T?;
    return null;
  }

  static List<T>? _safeGetList<T>(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is List) return value.whereType<T>().toList();
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
// ✅ FIN DEL ARCHIVO - Alineado con RPC get_opole_feed + feed mixto video/imagen 🇦🇷🚀
