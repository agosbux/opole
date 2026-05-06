// lib/pages/reel_questions_page/controller/reel_questions_controller.dart
import 'package:flutter/material.dart'; // â† Para Colors y Snackbar
import 'package:get/get.dart';
import 'package:opole/core/supabase/models/question_model.dart';
import 'package:opole/core/supabase/supabase_api.dart';
import 'package:opole/core/services/supabase_client.dart' as supabase;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReelQuestionsController extends GetxController {
  final String reelId;
  final String reelOwnerId;
  
  ReelQuestionsController({
    required this.reelId,
    required this.reelOwnerId,
  });

  // ðŸ”¹ Estado reactivo
  final RxList<QuestionModel> questions = <QuestionModel>[].obs;
  final RxInt questionsCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  
  // ðŸ”¹ Para optimistic UI rollback
  QuestionModel? _lastOptimisticQuestion;
  
  // ðŸ†• CachÃ© del username actual para optimistic UI mÃ¡s precisa
  String? _currentUsername;
  
  // ðŸ”¹ Servicios
  final SupabaseApi _api = SupabaseApi.instance;
  RealtimeChannel? _questionsChannel;
  
  // ðŸ”¹ Usuario actual
  String get _userId => supabase.SupabaseClient.currentUserId ?? '';
  bool get _isReelOwner => _userId == reelOwnerId;

  @override
  void onInit() {
    super.onInit();
    _fetchCurrentUsername();
    _fetchQuestions();
    _subscribeToQuestions();
    _refreshQuestionsCount();
  }

  @override
  void onClose() {
    _unsubscribeFromQuestions();
    super.onClose();
  }

  // ===================================================================
  // ðŸ†• OBTENER USERNAME DEL USUARIO ACTUAL (para optimistic UI)
  // ===================================================================
  Future<void> _fetchCurrentUsername() async {
    if (_userId.isEmpty) return;
    try {
      final response = await supabase.SupabaseClient
          .from('profiles')
          .select('username')
          .eq('id', _userId)
          .maybeSingle();
      _currentUsername = response?['username'] as String?;
      Get.log('ðŸ“ [QUESTIONS] Username obtenido: $_currentUsername');
    } catch (e) {
      Get.log('âš ï¸ [QUESTIONS] Error obteniendo username: $e');
    }
  }

  // ===================================================================
  // ðŸ”¹ FETCH DE PREGUNTAS (usa tu RPC: obtener_preguntas_reel)
  // ===================================================================
  Future<void> _fetchQuestions() async {
    if (isLoading.value) return;
    
    isLoading.value = true;
    try {
      final response = await _api.obtenerPreguntasReel(
        reelId: reelId,
        limit: 50,
        offset: 0,
      );
      
      final parsed = response
          .map((item) => QuestionModel.fromJson(item as Map<String, dynamic>))
          .toList();
      
      questions.assignAll(parsed);
      questionsCount.value = parsed.length;
      
      Get.log('âœ… [QUESTIONS] ${parsed.length} preguntas cargadas para reel: $reelId');
      
    } catch (e) {
      Get.log('âŒ [QUESTIONS] Error fetching: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ===================================================================
  // ðŸ”¹ POST DE NUEVA PREGUNTA (Optimistic UI + tu RPC: crear_pregunta)
  // ===================================================================
  
  void addQuestionOptimistic(String content) {
    final askerUsername = _currentUsername ?? 'TÃº';
    
    final tempQuestion = QuestionModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      reelId: reelId,
      parentId: null,
      askerId: _userId,
      askerUsername: askerUsername,
      askerPhoto: null,
      askerLevel: 0,
      answererId: null,
      answererUsername: null,
      questionText: content,
      answerText: null,
      isAnswered: false,
      isThreadClosed: false,
      createdAt: DateTime.now(),
      hasFollowups: false,
      followupsCount: 0,
    );
    
    _lastOptimisticQuestion = tempQuestion;
    questions.insert(0, tempQuestion);
    questionsCount.value++;
    
    Get.log('ðŸ“ [QUESTIONS] Optimistic question added con username: $askerUsername');
  }

  Future<void> postQuestion(String content) async {
    if (isSending.value) return;
    
    isSending.value = true;
    try {
      final questionId = await _api.crearPregunta(
        reelId: reelId,
        askerId: _userId,
        questionText: content,
        parentId: null,
      );
      
      if (_lastOptimisticQuestion != null) {
        final index = questions.indexOf(_lastOptimisticQuestion!);
        if (index != -1) {
          await _fetchQuestions();
        }
      }
      
      Get.log('âœ… [QUESTIONS] Pregunta creada: $questionId');
      
    } catch (e) {
      Get.log('âŒ [QUESTIONS] Error creando pregunta: $e');
      rethrow;
    } finally {
      isSending.value = false;
      _lastOptimisticQuestion = null;
    }
  }

  void rollbackLastQuestion() {
    if (_lastOptimisticQuestion != null) {
      questions.remove(_lastOptimisticQuestion!);
      questionsCount.value = questions.length;
      Get.log('ðŸ”™ [QUESTIONS] Rollback aplicado');
    }
  }

  // ===================================================================
  // ðŸ”¹ RESPONDER PREGUNTA (solo dueÃ±o del reel) - CON VALIDACIÃ“N TEMP ID
  // ===================================================================
  Future<void> answerQuestion({
    required String questionId,
    required String answerText,
  }) async {
    // ðŸ›¡ï¸ VALIDACIÃ“N: No permitir acciones con IDs temporales
    if (questionId.startsWith('temp_')) {
      Get.snackbar(
        'Espera un momento',
        'La pregunta aÃºn se estÃ¡ guardando...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (!_isReelOwner) {
      throw Exception('Solo el dueÃ±o del reel puede responder');
    }
    
    try {
      await _api.responderPregunta(
        questionId: questionId,
        answererId: _userId,
        answerText: answerText,
      );
      
      // âœ… Optimistic update local
      final index = questions.indexWhere((q) => q.id == questionId);
      if (index != -1) {
        questions[index] = questions[index].copyWith(
          isAnswered: true,
          answerText: answerText,
          answererId: _userId,
          answererUsername: _currentUsername,
        );
      }
      
      await _fetchQuestions();
      Get.log('âœ… [QUESTIONS] Pregunta respondida: $questionId');
      
    } catch (e) {
      Get.log('âŒ [QUESTIONS] Error respondiendo: $e');
      Get.snackbar('Error', 'No se pudo responder la pregunta', 
        snackPosition: SnackPosition.BOTTOM);
      rethrow;
    }
  }

  // ===================================================================
  // ðŸ”¹ SEGUIR CONVERSACIÃ“N (follow-up) - CON VALIDACIÃ“N TEMP ID
  // ===================================================================
  Future<void> followUpQuestion({
    required String parentQuestionId,
    required String followupText,
  }) async {
    // ðŸ›¡ï¸ VALIDACIÃ“N: No permitir acciones con IDs temporales
    if (parentQuestionId.startsWith('temp_')) {
      Get.snackbar(
        'Espera un momento',
        'La pregunta aÃºn se estÃ¡ guardando...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      final followupId = await _api.seguirConversacion(
        parentQuestionId: parentQuestionId,
        askerId: _userId,
        followupText: followupText,
      );
      
      await _fetchQuestions();
      Get.log('âœ… [QUESTIONS] Follow-up creado: $followupId');
      
    } catch (e) {
      Get.log('âŒ [QUESTIONS] Error en follow-up: $e');
      Get.snackbar('Error', 'No se pudo enviar el seguimiento', 
        snackPosition: SnackPosition.BOTTOM);
      rethrow;
    }
  }

  // ===================================================================
  // ðŸ”¹ CERRAR CONVERSACIÃ“N - CON VALIDACIÃ“N DE ID TEMPORAL
  // ===================================================================
  Future<void> closeThread({required String questionId}) async {
    // ðŸ›¡ï¸ VALIDACIÃ“N: No permitir acciones con IDs temporales
    if (questionId.startsWith('temp_')) {
      Get.snackbar(
        'Espera un momento',
        'La pregunta aÃºn se estÃ¡ guardando...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    
    // ðŸ›¡ï¸ VALIDACIÃ“N: Solo dueÃ±o o quien preguntÃ³ puede cerrar
    final question = questions.firstWhereOrNull((q) => q.id == questionId);
    if (question == null) {
      Get.log('âš ï¸ [QUESTIONS] Pregunta no encontrada para cerrar: $questionId');
      return;
    }
    
    if (!_isReelOwner && question.askerId != _userId) {
      Get.snackbar(
        'Permiso denegado',
        'Solo el dueÃ±o del reel o quien preguntÃ³ puede cerrar',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await _api.cerrarConversacion(
        questionId: questionId,
        userId: _userId,
      );
      
      // âœ… Actualizar estado local inmediatamente (optimistic update para cerrar)
      final index = questions.indexWhere((q) => q.id == questionId);
      if (index != -1) {
        questions[index] = questions[index].copyWith(isThreadClosed: true);
      }
      
      await _fetchQuestions(); // Refrescar para sincronizar con DB
      Get.log('âœ… [QUESTIONS] ConversaciÃ³n cerrada: $questionId');
      
    } catch (e) {
      Get.log('âŒ [QUESTIONS] Error cerrando: $e');
      Get.snackbar('Error', 'No se pudo cerrar la conversaciÃ³n', 
        snackPosition: SnackPosition.BOTTOM);
      rethrow;
    }
  }

  // ===================================================================
  // ðŸ”¹ REAL-TIME SUBSCRIPTION PARA CONTADOR
  // ===================================================================
  void _subscribeToQuestions() {
    _questionsChannel = Supabase.instance.client
        .channel('questions:$reelId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'questions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'reel_id',
            value: reelId,
          ),
          callback: (payload) {
            _refreshQuestionsCount();
            
            if (payload.eventType == 'INSERT') {
              final newRecord = payload.newRecord;
              if (newRecord['parent_id'] == null) {
                _fetchQuestions();
              }
            }
          },
        )
        .subscribe();
        
    Get.log('ðŸ“¡ [QUESTIONS] SuscripciÃ³n real-time activa para reel: $reelId');
  }

  void _unsubscribeFromQuestions() {
    if (_questionsChannel != null) {
      Supabase.instance.client.removeChannel(_questionsChannel!);
      Get.log('ðŸ”Œ [QUESTIONS] SuscripciÃ³n cerrada');
    }
  }

  Future<void> _refreshQuestionsCount() async {
    try {
      final count = await _api.obtenerPreguntasCount(reelId: reelId);
      questionsCount.value = count;
    } catch (e) {
      Get.log('âš ï¸ [QUESTIONS] Error refrescando contador: $e');
    }
  }

  // ===================================================================
  // ðŸ”¹ MÃ‰TODOS PÃšBLICOS PARA LA UI
  // ===================================================================
  Future<void> refreshQuestions() async {
    await _fetchQuestions();
    await _refreshQuestionsCount();
  }
  
  bool canAnswer(String questionId) {
    // ðŸ›¡ï¸ No permitir responder preguntas temporales
    if (questionId.startsWith('temp_')) return false;
    
    final question = questions.firstWhereOrNull((q) => q.id == questionId);
    return _isReelOwner && question != null && !question.isAnswered;
  }
  
  bool canFollowUp(String questionId) {
    // ðŸ›¡ï¸ No permitir follow-up en preguntas temporales
    if (questionId.startsWith('temp_')) return false;
    
    final question = questions.firstWhereOrNull((q) => q.id == questionId);
    return question != null && question.askerId == _userId && question.isAnswered && !question.isThreadClosed;
  }
  
  bool canClose(String questionId) {
    // ðŸ›¡ï¸ No permitir cerrar preguntas temporales
    if (questionId.startsWith('temp_')) return false;
    
    return _isReelOwner || questions.any((q) => q.id == questionId && q.askerId == _userId);
  }
}
