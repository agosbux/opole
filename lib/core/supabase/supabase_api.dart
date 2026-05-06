// lib/core/supabase/supabase_api.dart
// ===================================================================
// SUPABASE API - OPOLE PRO V2.1 (Cursor Pagination + Error Handling Alineado)
// ===================================================================
// • ✅ UN SOLO FEED: get_opole_feed → retorna List<ReelModel> (type-safe)
// • ✅ TIMEOUT + RETRY automático para errores transitorios de red
// • ✅ Helper isTemp() PÚBLICO para validación centralizada de IDs temporales
// • ✅ RPC como fuente de verdad (triggers solo para auditoría)
// • ✅ Índices críticos documentados + parámetros consistentes (p_user_id)
// • ✅ PostgrestException NO se reintentan (errores de negocio)
// • ✅ ✅ NUEVO: Error strings alineados con RPCs reales (denunciar_reel, dar_lo_quiero)
// • ✅ ✅ NUEVO: Cursor pagination params (lastScore/lastId) para feed escalable
// ===================================================================

import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:opole/core/services/supabase_client.dart' as supabase;
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/core/supabase/models/question_model.dart';

class SupabaseApi {
  static final SupabaseApi _instance = SupabaseApi._internal();
  static SupabaseApi get instance => _instance;
  factory SupabaseApi() => _instance;
  SupabaseApi._internal();

  // ⏱️ TIMEOUT para llamadas de red (evita hangs infinitos)
  static const Duration _rpcTimeout = Duration(seconds: 10);

  // 🛡️ LISTA BLANCA DE EVENTOS (Seguridad)
  static const Set<String> _allowedEvents = {
    'view', 'watch', 'like', 'share', 'completion', 'lo_quiero', 'question'
  };

  // 🔹 HELPER: Validación centralizada de IDs temporales ✅ FIX: PÚBLICO para uso externo
  static bool isTemp(String? id) => id == null || id.startsWith('temp_');

  // ===================================================================
  // 🔁 HELPER PRINCIPAL: Retry automático para RPC (solo errores transitorios)
  // ===================================================================
  Future<T?> _rpcWithRetry<T>({
    required String functionName,
    required Map<String, dynamic> params,
    bool rethrowBusinessErrors = true,
  }) async {
    Future<T?> _attempt() async {
      final result = await supabase.SupabaseClient
          .rpc(functionName, params: params)
          .timeout(_rpcTimeout);
      return result as T?;
    }

    try {
      return await _attempt();
    } on TimeoutException {
      try {
        Get.log('🔄 [RETRY] $functionName: timeout, intento 2/2');
        return await _attempt();
      } on TimeoutException {
        Get.log('❌ [RETRY] $functionName: timeout definitivo');
        return null;
      }
    } on SocketException catch (e) {
      try {
        Get.log('🔄 [RETRY] $functionName: SocketException, intento 2/2');
        return await _attempt();
      } catch (e) {
        Get.log('❌ [RETRY] $functionName: error de red definitivo: $e');
        return null;
      }
    } on PostgrestException catch (e) {
      if (rethrowBusinessErrors) {
        Get.log('❌ [API] PostgrestException en $functionName: ${e.message}');
        rethrow;
      }
      return null;
    } catch (e) {
      Get.log('❌ [API] Error en $functionName: $e');
      return null;
    }
  }

  // ===================================================================
  // 🔁 HELPER: Operación directa sobre tabla con retry (para DELETE/INSERT)
  // ===================================================================
  Future<T?> _tableOpWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
  }) async {
    Future<T> _attempt() async {
      return await operation().timeout(_rpcTimeout);
    }

    try {
      return await _attempt();
    } on TimeoutException {
      try {
        Get.log('🔄 [RETRY] $operationName: timeout, intento 2/2');
        return await _attempt();
      } on TimeoutException {
        Get.log('❌ [RETRY] $operationName: timeout definitivo');
        return null;
      }
    } on SocketException catch (e) {
      try {
        Get.log('🔄 [RETRY] $operationName: SocketException, intento 2/2');
        return await _attempt();
      } catch (e) {
        Get.log('❌ [RETRY] $operationName: error de red definitivo: $e');
        return null;
      }
    } on PostgrestException catch (e) {
      Get.log('❌ [API] PostgrestException en $operationName: ${e.message}');
      rethrow;
    } catch (e) {
      Get.log('❌ [API] Error en $operationName: $e');
      return null;
    }
  }

  // ===================================================================
  // 🔹 FEED ÚNICO - Cursor Pagination + Type-Safe ReelModel
  // ===================================================================
  Future<List<ReelModel>> getOpoleFeed({
    required String userId,
    int limit = 10,
    double? lastScore,    // ✅ CURSOR PAGINATION
    String? lastId,       // ✅ CURSOR PAGINATION
    String? province,
    String? locality,
    List<String>? userInterests,
    int offset = 0,       // ← DEJAR POR COMPATIBILIDAD (RPC lo ignora)
  }) async {
    if (isTemp(userId)) return [];
    try {
      Get.log('🔹 [API] getOpoleFeed: userId=$userId, cursor=($lastScore, $lastId)');

      final response = await _rpcWithRetry<List<dynamic>>(
        functionName: 'get_opole_feed',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
          // 'p_offset': offset,  // ← OPCIONAL: tu RPC usa cursor, no offset
          'p_last_score': lastScore,  // ✅ CRÍTICO: cursor pagination
          'p_last_id': lastId,        // ✅ CRÍTICO: cursor pagination
          'p_province': province,
          'p_locality': locality,
          'p_user_interests': userInterests,
        },
      );

      if (response != null && response is List) {
        return response
            .map((json) => ReelModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      Get.log('⚠️ [API] Response nulo o inesperado en getOpoleFeed');
      return [];
      
    } on PostgrestException catch (e) {
      Get.log('❌ [CRÍTICO] PostgrestException en getOpoleFeed: ${e.message}', isError: true);
      return [];
    } catch (e, stack) {
      Get.log('❌ [CRÍTICO] Error en getOpoleFeed: $e', isError: true);
      Get.log('StackTrace: $stack');
      return [];
    }
  }

  // ===================================================================
  // 🔹 ENGAGEMENT - Validación + RPC + Retry
  // ===================================================================
  Future<void> trackEngagement(Map<String, dynamic> data) async {
    final String? action = data['action'];
    final String? reelId = data['reel_id'];
    final String? userId = data['user_id'];

    if (action == null || !_allowedEvents.contains(action)) {
      Get.log('⚠️ [SEGURIDAD] Evento no permitido: $action');
      return;
    }
    if (isTemp(reelId) || isTemp(userId)) return;
    try {
      final Map<String, dynamic> metadata = Map<String, dynamic>.from(data);
      metadata.removeWhere((k, v) => ['reel_id', 'user_id', 'action'].contains(k));

      await _rpcWithRetry<void>(
        functionName: 'log_reel_event',
        params: {
          'p_reel_id': reelId,
          'p_user_id': userId,
          'p_event_type': action,
          'p_metadata': metadata.isEmpty ? {} : metadata,
          'p_watch_time_seconds': data['watch_time_seconds'],
          'p_retention_percent': data['retention_percent'],
        },
        rethrowBusinessErrors: false,
      );
    } catch (e, stack) {
      Get.log('❌ [API] Error en trackEngagement: $e', isError: true);
      Get.log('StackTrace: $stack');
    }
  }

  // ===================================================================
  // 🔹 LIKE - Toggle (Type-safe + Retry)
  // ===================================================================
  Future<bool> toggleLike(String reelId, String userId) async {
    if (isTemp(reelId) || isTemp(userId)) return false;
    try {
      final response = await _rpcWithRetry<bool>(
        functionName: 'toggle_like',
        params: {'p_reel_id': reelId, 'p_user_id': userId},
        rethrowBusinessErrors: false,
      );
      return response == true;
    } catch (e) {
      Get.log('❌ Error en toggleLike: $e', isError: true);
      return false;
    }
  }

  // ===================================================================
  // 🔹 REPORT REEL - Error strings alineados con RPC denunciar_reel
  // ===================================================================
  Future<bool> reportReel({
    required String reelId,
    required String motivo,
    String? detalles,
    required String userId,
    String? ip,
  }) async {
    if (isTemp(reelId) || isTemp(userId)) return false;
    try {
      final response = await _rpcWithRetry<bool>(
        functionName: 'denunciar_reel',
        params: {
          'p_denunciante_id': userId,
          'p_reel_id': reelId,
          'p_motivo': motivo,
          'p_detalles': detalles,
          'p_ip': ip,
        },
        rethrowBusinessErrors: true,
      );
      return response == true;
    } on PostgrestException catch (e) {
      // ✅ FIX: Match con strings reales de la RPC denunciar_reel
      final msg = e.message?.toUpperCase() ?? '';
      if (msg.contains('DUPLICADA')) {
        throw Exception('Ya denunciaste este reel.');
      } else if (msg.contains('AUTO_DENUNCIA')) {
        throw Exception('No podés denunciar tu propia publicación.');
      } else if (msg.contains('NO_ENCONTRADO') || msg.contains('INACTIVO')) {
        throw Exception('Este reel no está disponible.');
      }
      return false;
    } catch (e) {
      Get.log('❌ Error en reportReel: $e', isError: true);
      return false;
    }
  }

  // ===================================================================
  // 🔹 COMPARTIR - RPC + Retry
  // ===================================================================
  Future<bool> registrarCompartido(String reelId, String userId) async {
    if (isTemp(reelId) || isTemp(userId)) return false;
    try {
      final response = await _rpcWithRetry<bool>(
        functionName: 'registrar_compartido',
        params: {'p_reel_id': reelId, 'p_user_id': userId},
        rethrowBusinessErrors: false,
      );
      return response == true;
    } catch (e) {
      Get.log('❌ Error en registrarCompartido: $e', isError: true);
      return false;
    }
  }

  // ===================================================================
  // 🔹 "DAR LO QUIERO" - Manejo de NULL como "ya existía"
  // ===================================================================
  Future<String?> darLoQuiero(String reelId, String compradorId) async {
    if (isTemp(reelId) || isTemp(compradorId)) return null;
    try {
      final response = await _rpcWithRetry<String>(
        functionName: 'dar_lo_quiero',
        params: {'p_reel_id': reelId, 'p_comprador_id': compradorId},
        rethrowBusinessErrors: true,
      );
      
      // ✅ FIX: Si retorna null, fue un "ya existía" (ON CONFLICT DO NOTHING)
      if (response == null) {
        throw Exception('YA_DIO_LO_QUIERO');
      }
      return response;
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg?.contains('LIMITE_DIARIO_ALCANZADO') == true) {
        throw Exception('Límite diario de "Lo quiero" alcanzado.');
      } else if (msg?.contains('YA_DIO_LO_QUIERO') == true) {
        throw Exception('Ya expresaste interés en este artículo.');
      } else if (msg?.contains('REEL_NO_EXISTE_O_NO_ACTIVO') == true) {
        throw Exception('Este reel no está disponible.');
      } else if (msg?.contains('AUTO_LO_QUIERO_PROHIBIDO') == true) {
        throw Exception('No podés dar "Lo quiero" a tu propio reel.');
      }
      return null;
    } catch (e) {
      Get.log('❌ Error en darLoQuiero: $e', isError: true);
      return null;
    }
  }

  // ===================================================================
  // 🔹 SEARCH BY HASHTAG - Implementación completa con RPC
  // ===================================================================
  Future<List<ReelModel>> searchByHashtag({
    required String hashtag,
    int limit = 20,
    String? excludeUserId,
  }) async {
    try {
      if (kDebugMode) print('🔍 [SEARCH] Buscando hashtag: #$hashtag');
      
      // Limpiar el hashtag (remover # si viene incluido)
      final cleanHashtag = hashtag.startsWith('#') ? hashtag.substring(1) : hashtag;
      
      final response = await _rpcWithRetry<List<dynamic>>(
        functionName: 'search_reels_by_text',
        params: {
          'p_query': cleanHashtag,
          'p_limit': limit,
          if (excludeUserId != null && !isTemp(excludeUserId)) 
            'p_exclude_user_id': excludeUserId,
        },
        rethrowBusinessErrors: false,
      );
      
      if (response != null && response is List) {
        final results = response
            .whereType<Map<String, dynamic>>()
            .map((json) => ReelModel.fromJson(json))
            .toList();
        
        if (kDebugMode) print('✅ [SEARCH] Encontrados ${results.length} reels para #$cleanHashtag');
        return results;
      }
      
      if (kDebugMode) print('⚠️ [SEARCH] Sin resultados para #$cleanHashtag');
      return [];
      
    } catch (e, stack) {
      Get.log('❌ [API] Error en searchByHashtag: $e', isError: true);
      if (kDebugMode) {
        print('❌ [SEARCH] Error: $e');
        print('StackTrace: $stack');
      }
      return [];
    }
  }

  // ===================================================================
  // 🔹 NOTIFICACIONES - RPC + Retry
  // ===================================================================
  Future<int> getUnreadNotifications(String userId) async {
    if (isTemp(userId)) return 0;
    try {
      final response = await _rpcWithRetry<int>(
        functionName: 'get_unread_notifications_count',
        params: {'p_user_id': userId},
        rethrowBusinessErrors: false,
      );
      return response ?? 0;
    } catch (e) {
      Get.log('❌ Error en getUnreadNotifications: $e', isError: true);
      return 0;
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (isTemp(notificationId)) return;
    await _rpcWithRetry<void>(
      functionName: 'mark_notification_read',
      params: {'p_notification_id': notificationId},
      rethrowBusinessErrors: false,
    );
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    if (isTemp(userId)) return;
    await _rpcWithRetry<void>(
      functionName: 'mark_all_notifications_read',
      params: {'p_user_id': userId},
      rethrowBusinessErrors: false,
    );
  }

  Future<List<Map<String, dynamic>>> getNotifications({
    required String userId,
    int limit = 20,
  }) async {
    if (isTemp(userId)) return [];
    try {
      final response = await _rpcWithRetry<List<dynamic>>(
        functionName: 'get_user_notifications',
        params: {'p_user_id': userId, 'p_limit': limit},
        rethrowBusinessErrors: false,
      );
      return response is List ? List<Map<String, dynamic>>.from(response) : [];
    } catch (e) {
      Get.log('❌ Error en getNotifications: $e', isError: true);
      return [];
    }
  }

  // ===================================================================
  // 🔹 FEED HYGIENE - Marcar como visto + Retry
  // ===================================================================
  Future<void> markAsViewed(String userId, String reelId) async {
    if (isTemp(userId) || isTemp(reelId)) return;
    await _rpcWithRetry<void>(
      functionName: 'mark_reel_viewed',
      params: {'p_user_id': userId, 'p_reel_id': reelId},
      rethrowBusinessErrors: false,
    );
  }

  // ===================================================================
  // 🔹 PUNTOS DE USUARIO + Retry
  // ===================================================================
  Future<void> incrementUserPoints({
    required String userId,
    required int points,
    required String pointType,
  }) async {
    if (isTemp(userId)) return;
    await _rpcWithRetry<void>(
      functionName: 'increment_user_points',
      params: {'p_user_id': userId, 'p_points': points, 'p_point_type': pointType},
      rethrowBusinessErrors: false,
    );
  }

  // ===================================================================
  // 🔹 SISTEMA DE PREGUNTAS - RPC Wrappers + Retry + Type-safe
  // ===================================================================
  Future<String> crearPregunta({
    required String reelId,
    required String askerId,
    required String questionText,
    String? parentId,
  }) async {
    if (isTemp(reelId) || isTemp(askerId)) {
      throw Exception('IDs temporales no válidos');
    }
    try {
      final response = await _rpcWithRetry<String>(
        functionName: 'crear_pregunta',
        params: {
          'p_reel_id': reelId,
          'p_asker_id': askerId,
          'p_question_text': questionText,
          'p_parent_id': parentId,
        },
        rethrowBusinessErrors: true,
      );
      return response!;
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg?.contains('AUTO_PREGUNTA_PROHIBIDA') == true) {
        throw Exception('No podés preguntar sobre tu propio reel');
      } else if (msg?.contains('REEL_NO_EXISTE_O_NO_ACTIVO') == true) {
        throw Exception('Este reel no está disponible');
      } else if (msg?.contains('VALIDACION_TEXTO') == true) {
        throw Exception('La pregunta debe tener entre 10 y 500 caracteres');
      }
      rethrow;
    }
  }

  Future<bool> responderPregunta({
    required String questionId,
    required String answererId,
    required String answerText,
  }) async {
    if (isTemp(questionId) || isTemp(answererId)) {
      throw Exception('IDs temporales no válidos');
    }
    try {
      final response = await _rpcWithRetry<bool>(
        functionName: 'responder_pregunta',
        params: {
          'p_question_id': questionId,
          'p_answerer_id': answererId,
          'p_answer_text': answerText,
        },
        rethrowBusinessErrors: true,
      );
      return response == true;
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg?.contains('PERMISO_DENEGADO') == true) {
        throw Exception('Solo el dueño del reel puede responder');
      } else if (msg?.contains('PREGUNTA_NO_EXISTE') == true) {
        throw Exception('Pregunta no encontrada');
      }
      rethrow;
    }
  }

  Future<String> seguirConversacion({
    required String parentQuestionId,
    required String askerId,
    required String followupText,
  }) async {
    if (isTemp(parentQuestionId) || isTemp(askerId)) {
      throw Exception('IDs temporales no válidos');
    }
    try {
      final response = await _rpcWithRetry<String>(
        functionName: 'seguir_conversacion',
        params: {
          'p_parent_question_id': parentQuestionId,
          'p_asker_id': askerId,
          'p_followup_text': followupText,
        },
        rethrowBusinessErrors: true,
      );
      return response!;
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg?.contains('CONVERSACION_NO_DISPONIBLE') == true) {
        throw Exception('Solo se puede seguir conversaciones con respuesta');
      }
      rethrow;
    }
  }

  Future<bool> cerrarConversacion({
    required String questionId,
    required String userId,
  }) async {
    if (isTemp(questionId) || isTemp(userId)) return false;
    try {
      final response = await _rpcWithRetry<bool>(
        functionName: 'cerrar_conversacion',
        params: {'p_question_id': questionId, 'p_user_id': userId},
        rethrowBusinessErrors: true,
      );
      return response == true;
    } on PostgrestException catch (e) {
      if (e.message?.contains('PERMISO_DENEGADO') == true) {
        throw Exception('Solo el dueño o quien preguntó puede cerrar');
      }
      rethrow;
    }
  }

  // ===================================================================
  // 🔹 ✅ NUEVO: Eliminar pregunta (operación directa con retry)
  // ===================================================================
  /// Elimina una pregunta (solo el dueño del reel puede hacerlo según RLS)
  Future<void> eliminarPregunta(String questionId) async {
    if (isTemp(questionId)) {
      throw Exception('ID temporal no válido');
    }
    
    try {
      await _tableOpWithRetry<void>(
        operation: () => supabase.SupabaseClient
            .from('questions')
            .delete()
            .eq('id', questionId),
        operationName: 'eliminarPregunta',
      );
      Get.log('✅ [API] Pregunta eliminada: $questionId');
    } on PostgrestException catch (e) {
      Get.log('❌ [API] PostgrestException en eliminarPregunta: ${e.message}');
      throw Exception('ERROR_ELIMINAR_PREGUNTA: ${e.message}');
    } catch (e) {
      Get.log('❌ [API] Error en eliminarPregunta: $e');
      throw Exception('ERROR_ELIMINAR_PREGUNTA: $e');
    }
  }

  // ===================================================================
  // 🔹 ✅ NUEVO: Reportar pregunta (operación directa con retry)
  // ===================================================================
  /// Reporta una pregunta o respuesta
  Future<void> reportarPregunta({
    required String questionId,
    required String reason,
    String? details,
  }) async {
    if (isTemp(questionId)) {
      throw Exception('ID de pregunta temporal no válido');
    }
    
    final userId = supabase.SupabaseClient.currentUserId;
    if (userId == null || isTemp(userId)) {
      throw Exception('USUARIO_NO_AUTENTICADO');
    }
    
    try {
      await _tableOpWithRetry<void>(
        operation: () => supabase.SupabaseClient
            .from('reportsquestions')
            .insert({
              'reporter_id': userId,
              'question_id': questionId,
              'reason': reason,
              'details': details,
              'status': 'pending',
              'created_at': DateTime.now().toIso8601String(),
            }),
        operationName: 'reportarPregunta',
      );
      Get.log('✅ [API] Pregunta reportada: $questionId por $userId');
    } on PostgrestException catch (e) {
      final msg = e.message?.toUpperCase() ?? '';
      
      // Manejo de errores específicos de la tabla reportsquestions
      if (msg.contains('DUPLICATE') || msg.contains('UNIQUE')) {
        throw Exception('Ya reportaste esta pregunta anteriormente.');
      } else if (msg.contains('FOREIGN KEY') || msg.contains('VIOLATION')) {
        throw Exception('La pregunta no existe o no está disponible.');
      }
      
      Get.log('❌ [API] PostgrestException en reportarPregunta: ${e.message}');
      throw Exception('ERROR_REPORTAR: ${e.message}');
    } catch (e) {
      Get.log('❌ [API] Error en reportarPregunta: $e');
      throw Exception('ERROR_REPORTAR: $e');
    }
  }

  // ===================================================================
  // 🔹 OBTENER PREGUNTAS - Métodos existentes
  // ===================================================================
  Future<List<QuestionModel>> obtenerPreguntasReel({
    required String reelId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _rpcWithRetry<List<dynamic>>(
        functionName: 'obtener_preguntas_reel',
        params: {'p_reel_id': reelId, 'p_limit': limit, 'p_offset': offset},
        rethrowBusinessErrors: false,
      );
      
      if (response != null && response is List) {
        return response
            .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      Get.log('❌ Error en obtenerPreguntasReel: $e', isError: true);
      return [];
    }
  }

  Future<List<QuestionModel>> obtenerFollowups({
    required String parentQuestionId,
  }) async {
    if (isTemp(parentQuestionId)) return [];
    
    try {
      final response = await _rpcWithRetry<List<dynamic>>(
        functionName: 'obtener_followups',
        params: {'p_parent_question_id': parentQuestionId},
        rethrowBusinessErrors: false,
      );
      
      if (response != null && response is List) {
        return response
            .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      Get.log('❌ Error en obtenerFollowups: $e', isError: true);
      return [];
    }
  }

  Future<QuestionModel?> getQuestionById(String questionId) async {
    if (isTemp(questionId)) return null;
    
    try {
      final response = await _rpcWithRetry<Map<String, dynamic>>(
        functionName: 'obtener_pregunta_por_id',
        params: {'p_question_id': questionId},
        rethrowBusinessErrors: false,
      );
      
      if (response != null) {
        return QuestionModel.fromJson(response);
      }
      return null;
    } catch (e) {
      Get.log('❌ Error en getQuestionById: $e', isError: true);
      return null;
    }
  }

  Future<QuestionModel?> getQuestionThread(String rootQuestionId) async {
    final root = await getQuestionById(rootQuestionId);
    if (root == null) return null;
    return await _loadRepliesRecursively(root);
  }

  Future<QuestionModel> _loadRepliesRecursively(QuestionModel question) async {
    if (!question.hasFollowups) return question;
    
    final replies = await obtenerFollowups(parentQuestionId: question.id);
    final List<QuestionModel> nestedReplies = [];
    
    for (var reply in replies) {
      final nested = await _loadRepliesRecursively(reply);
      nestedReplies.add(nested);
    }
    
    return question.copyWith(
      replies: nestedReplies,
      followupsCount: nestedReplies.length,
    );
  }

  @Deprecated('Usar reel.questions_count desde el Feed principal')
  Future<int> obtenerPreguntasCount({required String reelId}) async {
    Get.log('⚠️ [API] obtenerPreguntasCount está deprecado');
    return 0;
  }

  // ===================================================================
  // 🔹 ECONOMÍA OPOLE - Métodos vitales + Retry
  // ===================================================================
  
  Future<bool> activarBoost({
    required String reelId,
    required String userId,
    required String tipoBoost,
  }) async {
    if (isTemp(reelId) || isTemp(userId)) return false;
    try {
      final response = await _rpcWithRetry<bool>(
        functionName: 'activar_boost_prioridad',
        params: {
          'p_reel_id': reelId,
          'p_user_id': userId,
          'p_tipo_boost': tipoBoost,
        },
        rethrowBusinessErrors: true,
      );
      return response == true;
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg?.contains('SALDO_INSUFICIENTE') == true) {
        throw Exception('Saldo insuficiente para este boost.');
      } else if (msg?.contains('BOOST_YA_ACTIVO') == true) {
        throw Exception('Este reel ya tiene boost activo.');
      }
      return false;
    } catch (e) {
      Get.log('❌ Error en activarBoost: $e', isError: true);
      return false;
    }
  }

  Future<Map<String, dynamic>?> claimDailyLogin(String userId) async {
    if (isTemp(userId)) return null;
    try {
      final response = await _rpcWithRetry<Map<String, dynamic>>(
        functionName: 'claim_daily_login',
        params: {'p_user_id': userId},
        rethrowBusinessErrors: true,
      );
      return response;
    } on PostgrestException catch (e) {
      if (e.message?.contains('YA_RECLAMADO_HOY') == true) {
        throw Exception('Ya reclamaste tu recompensa hoy. ¡Volvé mañana! 🌙');
      }
      return null;
    } catch (e) {
      Get.log('❌ Error en claimDailyLogin: $e', isError: true);
      return null;
    }
  }

  Future<String?> apelarReel({
    required String reelId,
    required String userId,
    required String motivo,
  }) async {
    if (isTemp(reelId) || isTemp(userId)) return null;
    try {
      final response = await _rpcWithRetry<String>(
        functionName: 'apelar_shadow_ban',
        params: {
          'p_reel_id': reelId,
          'p_user_id': userId,
          'p_motivo_apelacion': motivo,
        },
        rethrowBusinessErrors: true,
      );
      return response;
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg?.contains('APELACION_YA_EXISTE') == true) {
        throw Exception('Ya hay una apelación pendiente para este reel.');
      } else if (msg?.contains('REEL_NO_PENALIZADO') == true) {
        throw Exception('Este reel no está penalizado.');
      }
      return null;
    } catch (e) {
      Get.log('❌ Error en apelarReel: $e', isError: true);
      return null;
    }
  }
}