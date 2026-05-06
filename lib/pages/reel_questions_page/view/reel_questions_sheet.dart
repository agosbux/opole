// lib/pages/feed_page/views/question_bottom_sheet.dart
// ===================================================================
// QUESTION BOTTOM SHEET - UI para preguntas (usa FeedController directo)
// ===================================================================
// âœ… Arquitectura limpia: View â†’ FeedController â†’ SupabaseApi
// âœ… Reactiva: Obx + RxList para updates en tiempo real
// âœ… Optimistic UI: Feedback instantÃ¡neo + rollback si falla
// âœ… Validaciones: IDs temporales, permisos, lÃ­mites de texto
// ===================================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/core/supabase/models/question_model.dart';
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:opole/pages/feed_page/widgets/question_card.dart'; // âœ… Tu widget existente
import 'package:opole/theme/app_colors.dart'; // AjustÃ¡ segÃºn tu tema

class QuestionBottomSheet extends StatefulWidget {
  final ReelModel reel;
  
  const QuestionBottomSheet({Key? key, required this.reel}) : super(key: key);

  @override
  State<QuestionBottomSheet> createState() => _QuestionBottomSheetState();
}

class _QuestionBottomSheetState extends State<QuestionBottomSheet> {
  late final FeedController _controller;
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  
  String? _currentUserId;
  bool _isReelOwner = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<FeedController>();
    _textController = TextEditingController();
    
    // âœ… Cargar preguntas al abrir + obtener datos del usuario
    _initData();
  }

  Future<void> _initData() async {
    // Obtener ID del usuario actual (desde SessionController vÃ­a controller)
    // Nota: Si tu FeedController no expone userId pÃºblicamente, usÃ¡ AuthService directo
    // AquÃ­ asumimos que podÃ©s acceder vÃ­a Get.find<SessionController>().uid
    // O pasalo como parÃ¡metro desde donde abrÃ­s el bottom sheet
    
    _currentUserId = Get.find<SessionController>().uid;
    _isReelOwner = _currentUserId == widget.reel.ownerId;
    
    // Cargar preguntas desde el controller
    await _controller.loadQuestionsForReel(widget.reel.id);
    
    // Auto-focus en el input si es nuevo
    if (mounted) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ðŸ”¹ HEADER
          _buildHeader(),
          
          // ðŸ”¹ LISTA DE PREGUNTAS
          Expanded(
            child: _buildQuestionsList(),
          ),
          
          // ðŸ”¹ INPUT PARA NUEVA PREGUNTA
          _buildQuestionInput(),
        ],
      ),
    );
  }

  // ===================================================================
  // ðŸ”¹ WIDGETS PRIVADOS
  // ===================================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preguntas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Obx(() {
                  final count = _controller.getQuestionsForReel(widget.reel.id).length;
                  return Text(
                    '$count ${count == 1 ? 'pregunta' : 'preguntas'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  );
                }),
              ],
            ),
          ),
          
          // âœ… BotÃ³n de refresh
          IconButton(
            onPressed: () => _controller.loadQuestionsForReel(widget.reel.id),
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Actualizar',
          ),
          
          // âœ… BotÃ³n de cerrar
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return Obx(() {
      final questions = _controller.getQuestionsForReel(widget.reel.id);
      final isLoading = _controller.isQuestionsLoading(widget.reel.id);
      
      // ðŸ”„ Estado de carga inicial
      if (isLoading && questions.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      // ðŸ“­ Sin preguntas aÃºn
      if (questions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.question_answer_outlined, 
                size: 48, color: AppColors.grey),
              const SizedBox(height: 12),
              Text(
                'SÃ© el primero en preguntar ðŸ‘‹',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu consulta ayuda a otros compradores',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      }
      
      // ðŸ“‹ Lista de preguntas
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80), // Espacio para el input
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          
          return QuestionCard(
            question: question,
            isReelOwner: _isReelOwner,
            isAsker: question.askerId == _currentUserId,
            
            // âœ… Callbacks delegados al FeedController
            onReply: () => _showReplyDialog(question),
            onFollowUp: () => _showFollowUpDialog(question),
            onClose: () => _controller.closeConversation(
              questionId: question.id,
              reelId: widget.reel.id,
            ),
          );
        },
      );
    });
  }

  Widget _buildQuestionInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // âœ… Input de texto
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'EscribÃ­ tu pregunta...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10,
                ),
                counterStyle: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => _sendQuestion(),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // âœ… BotÃ³n de enviar
          Obx(() {
            final isAsking = false; // Si tu controller expone estado global de "asking"
            final text = _textController.text.trim();
            final canSend = text.isNotEmpty && text.length >= 10 && !isAsking;
            
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canSend ? AppColors.primary : AppColors.grey,
              ),
              child: IconButton(
                onPressed: canSend ? _sendQuestion : null,
                icon: const Icon(Icons.send, size: 20, color: Colors.white),
                padding: const EdgeInsets.all(8),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===================================================================
  // ðŸ”¹ DIALOGS PARA ACCIONES CONTEXTUALES
  // ===================================================================

  void _showReplyDialog(QuestionModel question) {
    if (!_isReelOwner) return;
    
    final controller = TextEditingController();
    
    Get.defaultDialog(
      title: 'Responder pregunta',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${question.getPreviewText(maxLength: 80)}"',
            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'EscribÃ­ tu respuesta...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          final text = controller.text.trim();
          if (text.length < 5) {
            Get.snackbar('Error', 'La respuesta debe tener al menos 5 caracteres');
            return;
          }
          
          Get.back(); // Cerrar dialog
          
          await _controller.answerQuestion(
            questionId: question.id,
            reelId: widget.reel.id,
            answerText: text,
          );
        },
        child: const Text('Enviar'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Cancelar'),
      ),
    );
  }

  void _showFollowUpDialog(QuestionModel question) {
    if (question.askerId != _currentUserId) return;
    
    final controller = TextEditingController();
    
    Get.defaultDialog(
      title: 'Seguir conversaciÃ³n',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Respondiendo a: "${question.getPreviewText(maxLength: 60)}"',
            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText: 'EscribÃ­ tu seguimiento...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          final text = controller.text.trim();
          if (text.length < 3) {
            Get.snackbar('Error', 'El mensaje debe tener al menos 3 caracteres');
            return;
          }
          
          Get.back();
          
          await _controller.followUpConversation(
            parentQuestionId: question.id,
            reelId: widget.reel.id,
            followupText: text,
          );
        },
        child: const Text('Enviar'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Cancelar'),
      ),
    );
  }

  // ===================================================================
  // ðŸ”¹ SEND QUESTION
  // ===================================================================

  void _sendQuestion() {
    final text = _textController.text.trim();
    
    if (text.length < 10) {
      Get.snackbar(
        'Muy corto', 
        'Tu pregunta debe tener al menos 10 caracteres',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    if (text.length > 500) {
      Get.snackbar(
        'Muy largo', 
        'Tu pregunta no puede superar los 500 caracteres',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // âœ… Delegar al FeedController
    _controller.askQuestion(
      reelId: widget.reel.id,
      questionText: text,
    );
    
    // âœ… Limpiar input y mantener foco para seguir preguntando
    _textController.clear();
    _focusNode.requestFocus();
  }
}
