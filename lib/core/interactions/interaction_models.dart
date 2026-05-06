// lib/core/interactions/interaction_models.dart
// ===================================================================
// INTERACTION MODELS - FASE 2 (PRODUCCIÓN)
// ===================================================================
// ✅ Tipos para estado transitorio de interacciones
// ✅ SIN dependencias de Flutter/UI
// ✅ Puro Dart, testeable en aislamiento
// ===================================================================

/// Estado de una operación de interacción
enum InteractionStatus {
  idle,      // Sin operación en curso
  pending,   // Esperando respuesta del servidor
  success,   // Operación confirmada
  failed,    // Error, requiere rollback
}

/// Resultado de una operación de interacción
class InteractionResult {
  final bool success;
  final String? errorMessage;
  final dynamic data;

  const InteractionResult({
    required this.success,
    this.errorMessage,
    this.data,
  });

  factory InteractionResult.ok([dynamic data]) {
    return InteractionResult(success: true, data: data);
  }

  factory InteractionResult.error(String message) {
    return InteractionResult(success: false, errorMessage: message);
  }

  @override
  String toString() => 'InteractionResult(success: $success, error: $errorMessage)';
}

/// Payload para operaciones de like (útil para rollback)
class LikeOperation {
  final String reelId;
  final bool isLiked;
  final int likesCount;
  final DateTime timestamp;

  LikeOperation({
    required this.reelId,
    required this.isLiked,
    required this.likesCount,
  }) : timestamp = DateTime.now();

  /// Crea un payload de rollback (invierte el estado)
  LikeOperation rollback() {
    return LikeOperation(
      reelId: reelId,
      isLiked: !isLiked,
      likesCount: isLiked ? likesCount - 1 : likesCount + 1,
    );
  }
}