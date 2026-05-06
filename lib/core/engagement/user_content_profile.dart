// lib/core/engagement/user_content_profile.dart
// ===================================================================
// USER CONTENT PROFILE - FASE 4
// ===================================================================
// ✅ Pure Dart: CERO imports, CERO dependencias de Flutter/UI
// ✅ Lógica de dominio: vectores de interés con decay temporal
// ===================================================================

/// Vector de preferencia para una categoría/tag de contenido.
/// score > 0 = le gusta, score < 0 = lo skipea
class ContentVector {
  final String tag;
  double score;
  int sampleCount;
  DateTime lastUpdated;

  ContentVector({
    required this.tag,
    this.score = 0.0,
    this.sampleCount = 0,
  }) : lastUpdated = DateTime.now();

  /// Actualización incremental con decay temporal.
  /// Señales viejas pesan menos (decay ~3% por hora).
  void update(double engagementScore) {
    final hoursSinceLast = DateTime.now().difference(lastUpdated).inHours;
    final decayFactor = (1.0 / (1.0 + hoursSinceLast * 0.03)).clamp(0.01, 1.0);

    // Weighted moving average con decay
    score = (score * decayFactor * sampleCount + engagementScore) /
        (sampleCount * decayFactor + 1);
    sampleCount++;
    lastUpdated = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'score': score,
        'sample_count': sampleCount,
        'last_updated': lastUpdated.toIso8601String(),
      };

  factory ContentVector.fromJson(Map<String, dynamic> json) {
    final vector = ContentVector(
      tag: json['tag'] as String,
      score: (json['score'] as num).toDouble(),
      sampleCount: json['sample_count'] as int,
    );
    final lastUpdatedStr = json['last_updated'] as String?;
    if (lastUpdatedStr != null) {
      vector.lastUpdated = DateTime.tryParse(lastUpdatedStr) ?? DateTime.now();
    }
    return vector;
  }
}

/// Perfil de preferencias de contenido del usuario.
/// Gestiona vectores de interés por tag para ranking personalizado.
class UserContentProfile {
  final String userId;
  final Map<String, ContentVector> _vectors = {};
  DateTime _lastSyncedAt = DateTime.fromMillisecondsSinceEpoch(0);

  UserContentProfile({required this.userId});

  /// Actualizar perfil con una señal de engagement.
  /// [tags]: categorías/hashtags del reel que se acaba de ver.
  /// [engagementScore]: valor entre -1.0 (skip) y 1.0 (interacción fuerte).
  void recordSignal({
    required List<String> tags,
    required double engagementScore,
  }) {
    for (final tag in tags) {
      _vectors.putIfAbsent(tag, () => ContentVector(tag: tag));
      _vectors[tag]!.update(engagementScore);
    }
  }

  /// Score de afinidad entre este usuario y un reel dado sus tags.
  /// Retorna valor entre -1.0 (muy malo) y 1.0 (muy bueno).
  double affinityScore(List<String> reelTags) {
    if (reelTags.isEmpty || _vectors.isEmpty) return 0.0;
    
    double total = 0.0;
    int matched = 0;
    
    for (final tag in reelTags) {
      final vector = _vectors[tag];
      if (vector != null) {
        total += vector.score;
        matched++;
      }
    }
    
    return matched == 0 ? 0.0 : (total / matched).clamp(-1.0, 1.0);
  }

  /// Tags que el usuario claramente no quiere ver (score < -0.2)
  Set<String> get negativeInterests => _vectors.entries
      .where((entry) => entry.value.score < -0.2)
      .map((entry) => entry.key)
      .toSet();

  /// Top tags positivos para el cursor de ranking (enviar a Supabase).
  /// Retorna máximo 10 tags con score > 0.1, ordenados por score descendente.
  List<String> get topInterests => (_vectors.entries.toList()
        ..sort((a, b) => b.value.score.compareTo(a.value.score)))
      .take(10)
      .where((entry) => entry.value.score > 0.1)
      .map((entry) => entry.key)
      .toList();

  /// Indica si el perfil necesita sincronizarse con el servidor.
  /// true si pasaron más de 5 minutos desde el último sync.
  bool get needsSync =>
      DateTime.now().difference(_lastSyncedAt).inMinutes > 5;

  /// Marca el perfil como sincronizado.
  void markSynced() => _lastSyncedAt = DateTime.now();

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'vectors': _vectors.values.map((v) => v.toJson()).toList(),
        'last_synced_at': _lastSyncedAt.toIso8601String(),
      };

  factory UserContentProfile.fromJson(Map<String, dynamic> json) {
    final profile = UserContentProfile(
      userId: json['user_id'] as String,
    );
    
    final vectorsJson = json['vectors'] as List?;
    if (vectorsJson != null) {
      for (final v in vectorsJson) {
        final vector = ContentVector.fromJson(v as Map<String, dynamic>);
        profile._vectors[vector.tag] = vector;
      }
    }
    
    final syncedAtStr = json['last_synced_at'] as String?;
    if (syncedAtStr != null) {
      profile._lastSyncedAt = DateTime.tryParse(syncedAtStr) ?? 
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    
    return profile;
  }

  @override
  String toString() => 'UserContentProfile('
      'userId: $userId, '
      'vectors: ${_vectors.length}, '
      'topInterests: $topInterests, '
      'needsSync: $needsSync)';
}