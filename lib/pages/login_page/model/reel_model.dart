import 'dart:convert';

// ===================================================================
// ðŸ”¹ MODELO REEL - MAPEO SUPABASE â†’ DART
// ===================================================================
// Nota: Los campos de Supabase usan snake_case, Dart usa camelCase
// Este modelo hace el mapeo automÃ¡tico en fromJson/fromSupabase
// ===================================================================

ReelModel reelModelFromJson(String str) => ReelModel.fromJson(json.decode(str));
String reelModelToJson(ReelModel data) => json.encode(data.toJson());

class ReelModel {
  ReelModel({
    this.id,
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
    // Campos calculados por la RPC get_opole_feed
    this.geoPriority,
    this.interestPriority,
  });

  // ===================================================================
  // ðŸ”¹ FROM SUPABASE (RPC Response)
  // ===================================================================
  /// Crea un ReelModel desde la respuesta de la RPC get_opole_feed
  /// Los campos vienen en snake_case desde PostgreSQL
  factory ReelModel.fromSupabase(Map<String, dynamic> json) {
    return ReelModel(
      // ðŸ”¹ Campos base (mapeo snake_case â†’ camelCase)
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
      
      // âœ… CORRECCIÃ“N: Uso seguro de toInt() para nÃºmeros
      duration: (json['duration'] as num?)?.toInt(),
      shippingMethods: json['shipping_methods'] != null 
          ? List<String>.from(json['shipping_methods']) 
          : [],
      paymentMethods: json['payment_methods'] != null 
          ? List<String>.from(json['payment_methods']) 
          : [],
      
      // ðŸ”¹ MÃ©tricas (seguras)
      isBot: json['is_bot'] as bool? ?? false,
      likeCount: (json['like_count'] as num?)?.toInt(),
      loQuieroCount: (json['lo_quiero_count'] as num?)?.toInt(),
      shareCount: (json['share_count'] as num?)?.toInt(),
      viewCount: (json['view_count'] as num?)?.toInt(),
      
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
      
      // ðŸ”¹ Campos de prioridad calculados por la RPC (seguros)
      geoPriority: (json['geo_priority'] as num?)?.toInt(),
      interestPriority: (json['interest_priority'] as num?)?.toInt(),
    );
  }

  // ===================================================================
  // ðŸ”¹ FROM/TO JSON (Para compatibilidad con GetStorage o API legacy)
  // ===================================================================
  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
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
      
      // âœ… CORRECCIÃ“N: Uso seguro de toInt()
      duration: (json['duration'] as num?)?.toInt(),
      shippingMethods: json['shippingMethods'] != null 
          ? List<String>.from(json['shippingMethods']) 
          : [],
      paymentMethods: json['paymentMethods'] != null 
          ? List<String>.from(json['paymentMethods']) 
          : [],
      isBot: json['isBot'] as bool? ?? false,
      likeCount: (json['likeCount'] as num?)?.toInt(),
      loQuieroCount: (json['loQuieroCount'] as num?)?.toInt(),
      shareCount: (json['shareCount'] as num?)?.toInt(),
      viewCount: (json['viewCount'] as num?)?.toInt(),
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
      // Los campos geoPriority e interestPriority no suelen estar en JSON de almacenamiento local
      geoPriority: (json['geoPriority'] as num?)?.toInt(),
      interestPriority: (json['interestPriority'] as num?)?.toInt(),
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
    // GeoPriority e InterestPriority no se suelen guardar en JSON local, pero se incluyen por si acaso
    data['geoPriority'] = geoPriority;
    data['interestPriority'] = interestPriority;
    return data;
  }

  // ===================================================================
  // ðŸ”¹ COPYWITH (Para actualizaciones inmutables de estado)
  // ===================================================================
  ReelModel copyWith({
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
    );
  }

  // ===================================================================
  // ðŸ”¹ PROPIEDADES
  // ===================================================================
  final String? id;
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
}
