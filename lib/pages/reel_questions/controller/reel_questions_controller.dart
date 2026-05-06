// lib/pages/reel_questions/controller/reel_questions_controller.dart
// ===================================================================
// REEL QUESTIONS CONTROLLER v1.2 - Delete + Report + Owner Reply Fix
// ===================================================================

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:opole/core/supabase/models/question_model.dart';
import 'package:opole/core/supabase/supabase_api.dart';
import 'package:opole/core/services/supabase_client.dart';
import 'package:opole/core/utils/analytics.dart';

class ReelQuestionsController extends GetxController {
  // ===================================================================
  // 🔹 ESTADO REACTIVO
  // ===================================================================
  final RxList<QuestionModel> questions = <QuestionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxString currentReelId = ''.obs;
  final RxBool isAsking = false.obs;
  final RxBool hasError = false.obs;
  
  String? reelOwnerId;
  String? _currentReelId;

  // ===================================================================
  // 🔹 UI HELPERS
  // ===================================================================
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // ===================================================================
  // 🔹 PAGINACIÓN
  // ===================================================================
  static const int _pageSize = 20;
  int _currentOffset = 0;
  String? _lastLoadedReelId;

  // ===================================================================
  // 🔹 DEPENDENCIAS
  // ===================================================================
  final SupabaseApi _api = SupabaseApi.instance;
  String get _currentUserId => SupabaseClient.currentUserId ?? '';

  // ✅ Getter para saber si el usuario actual es dueño del reel
  bool get isCurrentUserReelOwner => reelOwnerId == _currentUserId;

  // ===================================================================
  // 🔹 INICIALIZACIÓN
  // ===================================================================
  void setReelOwnerId(String? ownerId) {
    reelOwnerId = ownerId;
    if (kDebugMode) Get.log('👤 [QUESTIONS] Reel owner ID set: $ownerId');
  }

  Future<void> loadQuestions(String reelId, {bool refresh = false}) async {
    _currentReelId = reelId;
    
    if (reelId != _lastLoadedReelId || refresh) {
      _resetState(reelId);
    }

    if (isLoading.value || !hasMore.value) return;

    isLoading.value = true;
    hasError.value = false;
    
    try {
      final newQuestions = await _api.obtenerPreguntasReel(
        reelId: reelId,
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (newQuestions.isEmpty) {
        hasMore.value = false;
      } else {
        _currentOffset += newQuestions.length;
        _lastLoadedReelId = reelId;
        questions.addAll(newQuestions);
      }
    } catch (e, stack) {
      hasError.value = true;
      if (kDebugMode) {
        Get.log('❌ [QUESTIONS] Error cargando preguntas: $e');
        Get.log('❌ [QUESTIONS] Stack: $stack');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void retryLoad() {
    if (_currentReelId?.isNotEmpty == true) {
      hasError.value = false;
      loadQuestions(_currentReelId!, refresh: true);
    }
  }

  void _resetState(String reelId) {
    currentReelId.value = reelId;
    questions.clear();
    _currentOffset = 0;
    hasMore.value = true;
    hasError.value = false;
    _lastLoadedReelId = reelId;
  }

  // ✅ Refresh manual
  Future<void> refreshQuestions() async {
    if (currentReelId.value.isNotEmpty) {
      await loadQuestions(currentReelId.value, refresh: true);
    }
  }

  // ✅ Scroll infinito
  void onScrollEnd() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (currentReelId.value.isNotEmpty) {
        loadQuestions(currentReelId.value);
      }
    }
  }

  // ===================================================================
  // 🔹 ACCIONES PRINCIPALES
  // ===================================================================

  Future<void> askQuestion({
    required String questionText,
    String? parentId,
  }) async {
    final userId = _currentUserId;
    final reelId = currentReelId.value;
    
    if (userId.isEmpty || reelId.isEmpty) return;

    try {
      isAsking.value = true;
      final questionId = await _api.crearPregunta(
        reelId: reelId,
        askerId: userId,
        questionText: questionText,
        parentId: parentId,
      );
      textController.clear();
      await loadQuestions(reelId, refresh: true);
      Analytics.logEvent('question_created', parameters: {
        'reel_id': reelId,
        'question_id': questionId,
      });
      Get.snackbar('¡Pregunta enviada!', 'El vendedor recibirá tu consulta',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[800],
        colorText: Colors.white,
      );
    } catch (e) {
      _handleError(e, fallback: 'No se pudo enviar tu pregunta');
    } finally {
      isAsking.value = false;
    }
  }

  Future<void> answerQuestion({
    required String questionId,
    required String answerText,
  }) async {
    final userId = _currentUserId;
    final reelId = currentReelId.value;
    
    if (userId.isEmpty || reelId.isEmpty) return;
    
    if (!isCurrentUserReelOwner) {
      Get.snackbar('Permiso denegado', 'Solo el vendedor puede responder',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[800],
        colorText: Colors.white,
      );
      return;
    }

    try {
      final success = await _api.responderPregunta(
        questionId: questionId,
        answererId: userId,
        answerText: answerText,
      );
      if (success) {
        await loadQuestions(reelId, refresh: true);
        Analytics.logEvent('question_answered', parameters: {'question_id': questionId});
      }
    } catch (e) {
      _handleError(e, fallback: 'No se pudo enviar tu respuesta');
    }
  }

  Future<void> followUp({
    required String parentQuestionId,
    required String followupText,
  }) async {
    final userId = _currentUserId;
    final reelId = currentReelId.value;
    
    if (userId.isEmpty || reelId.isEmpty) return;

    try {
      await _api.seguirConversacion(
        parentQuestionId: parentQuestionId,
        askerId: userId,
        followupText: followupText,
      );
      await loadQuestions(reelId, refresh: true);
      Analytics.logEvent('conversation_followup', parameters: {'parent_question_id': parentQuestionId});
    } catch (e) {
      _handleError(e, fallback: 'No se pudo continuar la conversación');
    }
  }

  Future<void> closeConversation({required String questionId}) async {
    final userId = _currentUserId;
    final reelId = currentReelId.value;
    if (userId.isEmpty || reelId.isEmpty) return;
    
    final question = questions.firstWhereOrNull((q) => q.id == questionId);
    if (question != null && question.askerId != userId && reelOwnerId != userId) {
      return;
    }

    try {
      final success = await _api.cerrarConversacion(
        questionId: questionId,
        userId: userId,
      );
      if (success) {
        await loadQuestions(reelId, refresh: true);
        Analytics.logEvent('conversation_closed', parameters: {'question_id': questionId});
      }
    } catch (e) {
      _handleError(e, fallback: 'No se pudo cerrar la conversación');
    }
  }

  // ✅ NUEVO: Eliminar pregunta (solo dueño del reel)
  Future<void> deleteQuestion(String questionId) async {
    if (!isCurrentUserReelOwner) {
      Get.snackbar('Error', 'Solo el dueño del reel puede eliminar preguntas',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[800],
        colorText: Colors.white,
      );
      return;
    }

    try {
      await _api.eliminarPregunta(questionId);
      await loadQuestions(currentReelId.value, refresh: true);
      Analytics.logEvent('question_deleted', parameters: {'question_id': questionId});
      Get.snackbar('Eliminada', 'La pregunta ha sido eliminada',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[800],
        colorText: Colors.white,
      );
    } catch (e) {
      _handleError(e, fallback: 'No se pudo eliminar la pregunta');
    }
  }

  // ✅ NUEVO: Reportar pregunta
  Future<void> reportQuestion({
    required String questionId,
    required String reason,
    String? details,
  }) async {
    try {
      await _api.reportarPregunta(
        questionId: questionId,
        reason: reason,
        details: details,
      );
      Get.snackbar('Reporte enviado', 'Gracias por ayudarnos a mantener la comunidad segura',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue[800],
        colorText: Colors.white,
      );
      Analytics.logEvent('question_reported', parameters: {'question_id': questionId, 'reason': reason});
    } catch (e) {
      _handleError(e, fallback: 'No se pudo enviar el reporte');
    }
  }

  // ===================================================================
  // 🔹 HELPERS UI
  // ===================================================================
  bool isQuestionClosed(QuestionModel question) => question.isThreadClosed == true;

  bool canAnswer(QuestionModel question) {
    return isCurrentUserReelOwner && !isQuestionClosed(question) && !question.hasAnswer;
  }

  bool canFollowUp(QuestionModel question) {
    return !isQuestionClosed(question) && question.hasAnswer;
  }

  bool canClose(QuestionModel question) {
    final uid = _currentUserId;
    return (isCurrentUserReelOwner || question.askerId == uid) && !isQuestionClosed(question);
  }

  Future<void> handleSendQuestion(String text) async {
    if (text.trim().isEmpty) return;
    await askQuestion(questionText: text.trim());
  }

  void clearCache() {
    questions.clear();
    hasError.value = false;
    hasMore.value = true;
    _currentOffset = 0;
  }

  void _handleError(dynamic e, {required String fallback}) {
    String mensaje = fallback;
    if (e.toString().contains('AUTO_PREGUNTA')) {
      mensaje = 'No podés preguntar sobre tu propio reel';
    } else if (e.toString().contains('VALIDACION_TEXTO')) {
      mensaje = 'La pregunta debe tener entre 10 y 500 caracteres';
    } else if (e.toString().contains('PERMISO_DENEGADO')) {
      mensaje = 'No tenés permiso para realizar esta acción';
    }
    Get.snackbar('Error', mensaje,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[800],
      colorText: Colors.white,
    );
  }

  // ===================================================================
  // 🔹 LIFECYCLE
  // ===================================================================
  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(onScrollEnd);
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    questions.clear();
    super.onClose();
  }
}