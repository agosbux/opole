// lib/pages/feed_page/views/question_bottom_sheet.dart
// ===================================================================
// QUESTION BOTTOM SHEET - Compatible con FeedController certificado âœ…
// ===================================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/core/supabase/models/question_model.dart';
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:opole/pages/feed_page/widgets/question_card.dart';
import 'package:opole/theme/app_colors.dart';
import 'package:opole/controllers/session_controller.dart';

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
    _initData();
  }

  Future<void> _initData() async {
    _currentUserId = Get.find<SessionController>().uid;
    _isReelOwner = _currentUserId == widget.reel.ownerId;
    await _controller.loadQuestionsForReel(widget.reel.id);
    if (mounted) _focusNode.requestFocus();
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildHeader(), Expanded(child: _buildQuestionsList()), _buildQuestionInput()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preguntas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Obx(() {
                  final count = _controller.getQuestionsCount(widget.reel.id);
                  return Text('$count ${count == 1 ? 'pregunta' : 'preguntas'}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary));
                }),
              ],
            ),
          ),
          IconButton(onPressed: () => _controller.loadQuestionsForReel(widget.reel.id), icon: const Icon(Icons.refresh, size: 20)),
          IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close, size: 20)),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return Obx(() {
      final questions = _controller.getQuestionsForReel(widget.reel.id);
      final isLoading = _controller.isQuestionsLoading(widget.reel.id);
      
      if (isLoading && questions.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
      }
      
      if (questions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.question_answer_outlined, size: 48, color: AppColors.grey),
              const SizedBox(height: 12),
              Text('SÃ© el primero en preguntar ðŸ‘‹', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          return QuestionCard(
            question: question,
            isReelOwner: _isReelOwner,
            isAsker: question.askerId == _currentUserId,
            onReply: () => _showReplyDialog(question),
            onFollowUp: () => _showFollowUpDialog(question),
            onClose: () => _controller.closeConversation(questionId: question.id, reelId: widget.reel.id),
          );
        },
      );
    });
  }

  Widget _buildQuestionInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'EscribÃ­ tu pregunta...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendQuestion(),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final text = _textController.text.trim();
            final canSend = text.length >= 10 && text.length <= 500;
            return Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: canSend ? AppColors.primary : AppColors.grey),
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

  void _showReplyDialog(QuestionModel question) {
    if (!_isReelOwner) return;
    final controller = TextEditingController();
    Get.defaultDialog(
      title: 'Responder pregunta',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"${question.getPreviewText(maxLength: 80)}"', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          TextField(controller: controller, maxLines: 3, maxLength: 500, decoration: const InputDecoration(hintText: 'EscribÃ­ tu respuesta...', border: OutlineInputBorder()), autofocus: true),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          final text = controller.text.trim();
          if (text.length < 5) { Get.snackbar('Error', 'MÃ­nimo 5 caracteres'); return; }
          Get.back();
          await _controller.answerQuestion(questionId: question.id, reelId: widget.reel.id, answerText: text);
        },
        child: const Text('Enviar'),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
    );
  }

  void _showFollowUpDialog(QuestionModel question) {
    if (question.askerId != _currentUserId) return;
    if (_controller.isQuestionClosed(question)) {
      Get.snackbar('ConversaciÃ³n cerrada', 'Esta pregunta ya fue resuelta');
      return;
    }
    final controller = TextEditingController();
    Get.defaultDialog(
      title: 'Seguir conversaciÃ³n',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Respondiendo a: "${question.getPreviewText(maxLength: 60)}"', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          TextField(controller: controller, maxLines: 3, maxLength: 300, decoration: const InputDecoration(hintText: 'EscribÃ­ tu seguimiento...', border: OutlineInputBorder()), autofocus: true),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          final text = controller.text.trim();
          if (text.length < 3) { Get.snackbar('Error', 'MÃ­nimo 3 caracteres'); return; }
          Get.back();
          await _controller.followUpConversation(parentQuestionId: question.id, reelId: widget.reel.id, followupText: text);
        },
        child: const Text('Enviar'),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
    );
  }

  void _sendQuestion() {
    final text = _textController.text.trim();
    if (text.length < 10) { Get.snackbar('Muy corto', 'MÃ­nimo 10 caracteres', snackPosition: SnackPosition.BOTTOM); return; }
    if (text.length > 500) { Get.snackbar('Muy largo', 'MÃ¡ximo 500 caracteres', snackPosition: SnackPosition.BOTTOM); return; }
    _controller.askQuestion(reelId: widget.reel.id, questionText: text);
    _textController.clear();
    _focusNode.requestFocus();
  }
}
