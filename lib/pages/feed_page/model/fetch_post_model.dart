// lib/pages/feed_page/model/fetch_post_model.dart
import 'dart:convert';

// ===================================================================
// ðŸ”¹ FETCH POST MODEL - MAPEO SUPABASE â†’ DART
// ===================================================================
// Nota: Supabase devuelve snake_case, Dart usa camelCase
// Este modelo hace el mapeo automÃ¡tico en fromSupabase()
// ===================================================================

FetchPostModel fetchPostModelFromJson(String str) =>
    FetchPostModel.fromJson(json.decode(str));
String fetchPostModelToJson(FetchPostModel data) =>
    json.encode(data.toJson());

class FetchPostModel {
  FetchPostModel({
    this.id,               // âœ… Campo id declarado explÃ­citamente
    this.userId,
    this.videoUrl,
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
    this.likeCount,
    this.loQuieroCount,
    this.shareCount,
    this.viewCount,
    this.rankingScore,
    this.boostType,
    this.boostExpiresAt,
    this.priorityBoostType,
    this.priorityBoostExpiresAt,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.hasLiked,
    this.hasLoQuiero,
    // Campos calculados por RPC get_opole_feed
    this.geoPriority,
    this.interestPriority,
    // Datos del usuario (pueden venir join en la RPC)
    this.userUsername,
    this.userPhotoUrl,
    this.userLevel,
    this.userReputation,
    // Nuevo campo: cantidad de preguntas
    this.questionsCount,
  });

  // ===================================================================
  // ðŸ”¹ FROM SUPABASE (RPC Response - snake_case â†’ camelCase)
  // ===================================================================
  factory FetchPostModel.fromSupabase(Map<String, dynamic> json) {
    return FetchPostModel(
      // ðŸ”¹ Campos base del reel
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      condition: json['condition'] as String?,
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : [],
      province: json['province'] as String?,
      locality: json['locality'] as String?,
      duration: json['duration'] as int?,
      shippingMethods: json['shipping_methods'] != null
          ? List<String>.from(json['shipping_methods'])
          : [],
      paymentMethods: json['payment_methods'] != null
          ? List<String>.from(json['payment_methods'])
          : [],

      // ðŸ”¹ MÃ©tricas
      isBot: json['is_bot'] as bool? ?? false,
      likeCount: json['like_count'] as int?,
      loQuieroCount: json['lo_quiero_count'] as int?,
      shareCount: json['share_count'] as int?,
      viewCount: json['view_count'] as int?,

      // ðŸ”¹ Boost & Ranking
      rankingScore: (json['ranking_score'] as num?)?.toDouble(),
      boostType: json['boost_type'] as String?,
      boostExpiresAt: json['boost_expires_at'] != null
          ? DateTime.tryParse(json['boost_expires_at'])
          : null,
      priorityBoostType: json['priority_boost_type'] as String?,
      priorityBoostExpiresAt: json['priority_boost_expires_at'] != null
          ? DateTime.tryParse(json['priority_boost_expires_at'])
          : null,

      // ðŸ”¹ Estado y DateTimes
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,

      // ðŸ”¹ Estados del usuario actual
      hasLiked: json['has_liked'] as bool?,
      hasLoQuiero: json['has_lo_quiero'] as bool?,

      // ðŸ”¹ Prioridades calculadas por la RPC
      geoPriority: json['geo_priority'] as int?,
      interestPriority: json['interest_priority'] as int?,

      // ðŸ”¹ Datos del usuario (si vienen en el join de la RPC)
      userUsername: json['user_username'] as String?,
      userPhotoUrl: json['user_photo_url'] as String?,
      userLevel: json['user_level'] as int?,
      userReputation: json['user_reputation'] as int?,

      // ðŸ”¹ Nuevo campo: cantidad de preguntas
      questionsCount: json['questions_count'] as int?,
    );
  }

  // ===================================================================
  // ðŸ”¹ FROM JSON (Para compatibilidad con GetStorage o legacy)
  // ===================================================================
  factory FetchPostModel.fromJson(Map<String, dynamic> json) {
    return FetchPostModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      condition: json['condition'] as String?,
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : [],
      province: json['province'] as String?,
      locality: json['locality'] as String?,
      duration: json['duration'] as int?,
      shippingMethods: json['shippingMethods'] != null
          ? List<String>.from(json['shippingMethods'])
          : [],
      paymentMethods: json['paymentMethods'] != null
          ? List<String>.from(json['paymentMethods'])
          : [],
      isBot: json['isBot'] as bool? ?? false,
      likeCount: json['likeCount'] as int?,
      loQuieroCount: json['loQuieroCount'] as int?,
      shareCount: json['shareCount'] as int?,
      viewCount: json['viewCount'] as int?,
      rankingScore: (json['rankingScore'] as num?)?.toDouble(),
      boostType: json['boostType'] as String?,
      boostExpiresAt: json['boostExpiresAt'] != null
          ? DateTime.tryParse(json['boostExpiresAt'])
          : null,
      priorityBoostType: json['priorityBoostType'] as String?,
      priorityBoostExpiresAt: json['priorityBoostExpiresAt'] != null
          ? DateTime.tryParse(json['priorityBoostExpiresAt'])
          : null,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      hasLiked: json['hasLiked'] as bool?,
      hasLoQuiero: json['hasLoQuiero'] as bool?,
      userUsername: json['userUsername'] as String?,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      userLevel: json['userLevel'] as int?,
      userReputation: json['userReputation'] as int?,
      questionsCount: json['questionsCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['user_id'] = userId;
    data['videoUrl'] = videoUrl;
    data['thumbnailUrl'] = thumbnailUrl;
    data['title'] = title;
    data['description'] = description;
    data['price'] = price;
    data['condition'] = condition;
    data['categories'] = categories;
    data['province'] = province;
    data['locality'] = locality;
    data['duration'] = duration;
    data['shippingMethods'] = shippingMethods;
    data['paymentMethods'] = paymentMethods;
    data['isBot'] = isBot;
    data['likeCount'] = likeCount;
    data['loQuieroCount'] = loQuieroCount;
    data['shareCount'] = shareCount;
    data['viewCount'] = viewCount;
    data['rankingScore'] = rankingScore;
    data['boostType'] = boostType;
    data['boostExpiresAt'] = boostExpiresAt?.toIso8601String();
    data['priorityBoostType'] = priorityBoostType;
    data['priorityBoostExpiresAt'] = priorityBoostExpiresAt?.toIso8601String();
    data['status'] = status;
    data['createdAt'] = createdAt?.toIso8601String();
    data['updatedAt'] = updatedAt?.toIso8601String();
    data['hasLiked'] = hasLiked;
    data['hasLoQuiero'] = hasLoQuiero;
    data['userUsername'] = userUsername;
    data['userPhotoUrl'] = userPhotoUrl;
    data['userLevel'] = userLevel;
    data['userReputation'] = userReputation;
    data['questionsCount'] = questionsCount;
    return data;
  }

  // ===================================================================
  // ðŸ”¹ COPYWITH (Para actualizaciones inmutables de estado)
  // ===================================================================
  FetchPostModel copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? thumbnailUrl,
    String? title,
    String? description,
    double? price,
    String? condition,
    List<String>? categories,
    String? province,
    String? locality,
    int? duration,
    List<String>? shippingMethods,
    List<String>? paymentMethods,
    bool? isBot,
    int? likeCount,
    int? loQuieroCount,
    int? shareCount,
    int? viewCount,
    double? rankingScore,
    String? boostType,
    DateTime? boostExpiresAt,
    String? priorityBoostType,
    DateTime? priorityBoostExpiresAt,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasLiked,
    bool? hasLoQuiero,
    int? geoPriority,
    int? interestPriority,
    String? userUsername,
    String? userPhotoUrl,
    int? userLevel,
    int? userReputation,
    int? questionsCount,
  }) {
    return FetchPostModel(
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
      likeCount: likeCount ?? this.likeCount,
      loQuieroCount: loQuieroCount ?? this.loQuieroCount,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      rankingScore: rankingScore ?? this.rankingScore,
      boostType: boostType ?? this.boostType,
      boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
      priorityBoostType: priorityBoostType ?? this.priorityBoostType,
      priorityBoostExpiresAt: priorityBoostExpiresAt ?? this.priorityBoostExpiresAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasLiked: hasLiked ?? this.hasLiked,
      hasLoQuiero: hasLoQuiero ?? this.hasLoQuiero,
      geoPriority: geoPriority ?? this.geoPriority,
      interestPriority: interestPriority ?? this.interestPriority,
      userUsername: userUsername ?? this.userUsername,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      userLevel: userLevel ?? this.userLevel,
      userReputation: userReputation ?? this.userReputation,
      questionsCount: questionsCount ?? this.questionsCount,
    );
  }

  // ===================================================================
  // ðŸ”¹ PROPIEDADES
  // ===================================================================
  final String? id;               // âœ… Campo id declarado
  final String? userId;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final double? price;
  final String? condition;
  final List<String>? categories;
  final String? province;
  final String? locality;
  final int? duration;
  final List<String>? shippingMethods;
  final List<String>? paymentMethods;
  final bool? isBot;
  final int? likeCount;
  final int? loQuieroCount;
  final int? shareCount;
  final int? viewCount;
  final double? rankingScore;
  final String? boostType;
  final DateTime? boostExpiresAt;
  final String? priorityBoostType;
  final DateTime? priorityBoostExpiresAt;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? hasLiked;
  final bool? hasLoQuiero;
  final int? geoPriority;
  final int? interestPriority;
  final String? userUsername;
  final String? userPhotoUrl;
  final int? userLevel;
  final int? userReputation;
  final int? questionsCount; // âœ… Nuevo campo

  // ===================================================================
  // ðŸ”¹ HELPERS
  // ===================================================================
  bool get isBoosted => boostType != null && boostExpiresAt != null && boostExpiresAt!.isAfter(DateTime.now());
  bool get isPriorityBoosted => priorityBoostType != null && priorityBoostExpiresAt != null && priorityBoostExpiresAt!.isAfter(DateTime.now());
  bool get isAvailable => status == 'active';
  String get formattedPrice => price != null ? '\$${price!.toStringAsFixed(2)}' : 'Gratis';
}
