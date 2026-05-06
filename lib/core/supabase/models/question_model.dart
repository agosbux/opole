// lib/core/supabase/models/question_model.dart
// ===================================================================
// QUESTION MODEL v1.1 - Performance-Safe Equatable + Optimistic UI Ready
// ===================================================================
// ✅ Equatable con props optimizados (sin deep equality en replies)
// ✅ Null-safety completo en todos los campos
// ✅ JSON mapping robusto con fallbacks seguros
// ✅ Helpers semánticos: hasAnswer, isRootQuestion, isFollowUp
// ✅ ✅ FIX: replies excluido de props para evitar jank en hilos largos
// ✅ ✅ POLISH: Documentación de convenciones + alias ownerId clarificado
// ✅ ✅ READY: isLocal flag preparado para optimistic UI (opcional)
// ===================================================================

import 'package:equatable/equatable.dart';

/// Modelo de pregunta para el sistema de Q&A de reels.
/// 
/// ## Convenciones de mapeo JSON:
/// - Campos de la BD usan `snake_case`: `reel_id`, `asker_username`, etc.
/// - Campos de Dart usan `camelCase`: `reelId`, `askerUsername`, etc.
/// - Todos los campos opcionales son nullable (`Type?`) para seguridad.
/// 
/// ## Notas de performance:
/// - El campo `replies` NO está en `props` de Equatable para evitar deep equality checks.
/// - Usar `copyWith` para actualizaciones inmutables en UI reactiva.
class QuestionModel extends Equatable {
  // IDs y relaciones
  final String id;
  final String reelId;
  final String? parentId;
  
  // Usuarios (datos denormalizados desde la BD para evitar joins en UI)
  final String askerId;
  final String? askerUsername;
  final String? askerPhoto;
  final int? askerLevel;
  final String? answererId;
  final String? answererUsername;
  
  // Contenido
  final String questionText;
  final String? answerText;
  
  // Estado
  final bool isAnswered;
  final bool isThreadClosed;
  final DateTime createdAt;
  
  // Metadatos del hilo (calculados por la función de Supabase)
  final bool hasFollowups;  final int followupsCount;
  
  // Para UI anidada (opcional, se llena con otra consulta)
  // ✅ NOTA: Este campo NO está en `props` para evitar deep equality checks
  final List<QuestionModel>? replies;

  // ✅ OPTIMISTIC UI: Flag para preguntas creadas localmente antes de confirmar del servidor
  final bool isLocal;

  const QuestionModel({
    required this.id,
    required this.reelId,
    required this.askerId,
    required this.questionText,
    this.parentId,
    this.askerUsername,
    this.askerPhoto,
    this.askerLevel,
    this.answererId,
    this.answererUsername,
    this.answerText,
    this.isAnswered = false,
    this.isThreadClosed = false,
    required this.createdAt,
    this.hasFollowups = false,
    this.followupsCount = 0,
    this.replies,
    this.isLocal = false,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id']?.toString() ?? '',
      reelId: json['reel_id']?.toString() ?? '',
      askerId: json['asker_id']?.toString() ?? '',
      questionText: json['question_text']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      askerUsername: json['asker_username']?.toString(),
      askerPhoto: json['asker_photo']?.toString(),
      askerLevel: json['asker_level'] as int?,
      answererId: json['answerer_id']?.toString(),
      answererUsername: json['answerer_username']?.toString(),
      answerText: json['answer_text']?.toString(),
      isAnswered: json['is_answered'] == true,
      isThreadClosed: json['is_thread_closed'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      hasFollowups: json['has_followups'] == true,
      followupsCount: (json['followups_count'] as int?) ?? 0,      // ✅ isLocal siempre false desde la BD
      isLocal: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reel_id': reelId,
      'asker_id': askerId,
      'question_text': questionText,
      if (parentId != null) 'parent_id': parentId,
      if (answerText != null) 'answer_text': answerText,
      if (answererId != null) 'answerer_id': answererId,
      'is_thread_closed': isThreadClosed,
      // ✅ isLocal no se envía a la BD (es solo estado local)
    };
  }

  // ===================================================================
  // 🔹 HELPERS SEMÁNTICOS (para UI y lógica de negocio)
  // ===================================================================
  
  /// True si la pregunta tiene una respuesta del vendedor.
  bool get hasAnswer => answerText != null && answerText!.isNotEmpty;
  
  /// True si es una pregunta raíz (no es follow-up de otra).
  bool get isRootQuestion => parentId == null;
  
  /// True si es un follow-up (respuesta a otra pregunta).
  bool get isFollowUp => parentId != null;
  
  /// Alias para compatibilidad con UI legacy.
  /// Representa al usuario que hizo la pregunta (NO al dueño del reel).
  String get ownerId => askerId;
  
  /// Nombre más explícito para nuevo código: usuario que preguntó.
  String get askerUserId => askerId;

  // ===================================================================
  // 🔹 COPYWITH PARA ACTUALIZACIONES INMUTABLES
  // ===================================================================
  QuestionModel copyWith({
    String? id,
    String? reelId,
    String? parentId,
    String? askerId,
    String? askerUsername,
    String? askerPhoto,
    int? askerLevel,    String? answererId,
    String? answererUsername,
    String? questionText,
    String? answerText,
    bool? isAnswered,
    bool? isThreadClosed,
    DateTime? createdAt,
    bool? hasFollowups,
    int? followupsCount,
    List<QuestionModel>? replies,
    bool? isLocal,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      reelId: reelId ?? this.reelId,
      parentId: parentId ?? this.parentId,
      askerId: askerId ?? this.askerId,
      askerUsername: askerUsername ?? this.askerUsername,
      askerPhoto: askerPhoto ?? this.askerPhoto,
      askerLevel: askerLevel ?? this.askerLevel,
      answererId: answererId ?? this.answererId,
      answererUsername: answererUsername ?? this.answererUsername,
      questionText: questionText ?? this.questionText,
      answerText: answerText ?? this.answerText,
      isAnswered: isAnswered ?? this.isAnswered,
      isThreadClosed: isThreadClosed ?? this.isThreadClosed,
      createdAt: createdAt ?? this.createdAt,
      hasFollowups: hasFollowups ?? this.hasFollowups,
      followupsCount: followupsCount ?? this.followupsCount,
      replies: replies ?? this.replies,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  // ===================================================================
  // 🔹 EQUALITY CHECK OPTIMIZADO (Equatable)
  // ===================================================================
  @override
  List<Object?> get props => [
        // ✅ Campos primitivos y de valor: equality check rápido
        id, 
        reelId, 
        parentId, 
        askerId, 
        askerUsername, 
        askerPhoto, 
        askerLevel,
        answererId, 
        answererUsername, 
        questionText,         answerText, 
        isAnswered,
        isThreadClosed, 
        createdAt, 
        hasFollowups, 
        followupsCount,
        isLocal,
        // ✅ replies EXCLUIDO: es solo para UI, no para igualdad de datos
        // Incluirlo causaría deep equality checks recursivos → jank en hilos largos
      ];

  @override
  String toString() => 'QuestionModel(id: $id, text: "${questionText.length > 30 ? questionText.substring(0, 30) + '...' : questionText}", answered: $isAnswered, followups: $followupsCount)';
}