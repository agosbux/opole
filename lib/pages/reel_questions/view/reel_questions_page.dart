// lib/pages/reel_questions/view/reel_questions_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/pages/reel_questions/controller/reel_questions_controller.dart';
import 'package:opole/pages/reel_questions/widget/question_tile_widget.dart';
import 'package:opole/pages/reel_questions/widget/ask_question_dialog.dart';
import 'package:opole/pages/reel_questions/widget/report_dialog.dart'; // Nuevo diálogo de reporte
import 'package:opole/utils/color.dart';
import 'package:opole/utils/font_style.dart';

class ReelQuestionsPage extends StatelessWidget {
  const ReelQuestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String reelId = Get.arguments['reelId'] as String;
    final String reelOwnerId = Get.arguments['reelOwnerId'] as String;
    final String tag = 'questions_$reelId';

    // Registrar controller si no existe
    if (!Get.isRegistered<ReelQuestionsController>(tag: tag)) {
      final controller = ReelQuestionsController();
      controller.setReelOwnerId(reelOwnerId);
      Get.put(controller, tag: tag, permanent: false);
    }
    final controller = Get.find<ReelQuestionsController>(tag: tag);

    // Carga inicial
    if (controller.questions.isEmpty && !controller.isLoading.value) {
      controller.loadQuestions(reelId);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        title: const Text('Preguntas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (controller.isCurrentUserReelOwner)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => controller.refreshQuestions(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.questions.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppColor.primary));
              }
              
              if (controller.hasError.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      const Text('Error al cargar preguntas', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => controller.retryLoad(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.questions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.help_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Sin preguntas aún', style: AppFontStyle.styleW400(Colors.grey, 16)),
                      const SizedBox(height: 8),
                      Text('Sé el primero en preguntar', style: AppFontStyle.styleW400(Colors.grey[600]!, 14)),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () => controller.refreshQuestions(),
                child: ListView.builder(
                  controller: controller.scrollController,
                  itemCount: controller.questions.length + (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.questions.length) {
                      return const Center(child: CircularProgressIndicator(color: AppColor.primary));
                    }
                    
                    final question = controller.questions[index];
                    return QuestionTileWidget(
                      key: ValueKey(question.id),
                      question: question,
                      controller: controller,
                      onAnswerTap: () => _showAnswerDialog(context, controller, question),
                      onFollowUpTap: () => _showFollowUpDialog(context, controller, question),
                      onCloseTap: () => _confirmCloseThread(context, controller, question),
                      onDeleteTap: () => _confirmDeleteQuestion(context, controller, question),
                      onReportTap: () => _showReportDialog(context, controller, question),
                    );
                  },
                ),
              );
            }),
          ),
          
          // Bottom input area (solo visible si el usuario está autenticado)
          _buildInputArea(controller, context),
        ],
      ),
    );
  }

  Widget _buildInputArea(ReelQuestionsController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '¿Tenés una pregunta?',
              style: AppFontStyle.styleW400(Colors.grey[400]!, 14),
            ),
          ),
          Obx(() => ElevatedButton.icon(
            onPressed: controller.isAsking.value
                ? null
                : () => _showAskDialog(context, controller),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Preguntar', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          )),
        ],
      ),
    );
  }

  void _showAskDialog(BuildContext context, ReelQuestionsController controller) {
    Get.dialog(AskQuestionDialog(
      onSubmit: (text) async {
        Get.back();
        await controller.askQuestion(questionText: text);
      },
    ));
  }

  void _showAnswerDialog(BuildContext context, ReelQuestionsController controller, QuestionModel question) {
    Get.dialog(AskQuestionDialog(
      isAnswer: true,
      onSubmit: (text) async {
        Get.back();
        await controller.answerQuestion(questionId: question.id, answerText: text);
      },
    ));
  }

  void _showFollowUpDialog(BuildContext context, ReelQuestionsController controller, QuestionModel question) {
    Get.dialog(AskQuestionDialog(
      isFollowUp: true,
      onSubmit: (text) async {
        Get.back();
        await controller.followUp(parentQuestionId: question.id, followupText: text);
      },
    ));
  }

  void _confirmCloseThread(BuildContext context, ReelQuestionsController controller, QuestionModel question) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Cerrar conversación', style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que querés cerrar esta conversación? No se podrán agregar más respuestas.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.closeConversation(questionId: question.id);
            },
            child: const Text('Cerrar', style: TextStyle(color: AppColor.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteQuestion(BuildContext context, ReelQuestionsController controller, QuestionModel question) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Eliminar pregunta', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de eliminar esta pregunta? Esta acción no se puede deshacer.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteQuestion(question.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, ReelQuestionsController controller, QuestionModel question) {
    Get.dialog(ReportDialog(
      onSubmit: (reason, details) {
        controller.reportQuestion(questionId: question.id, reason: reason, details: details);
      },
    ));
  }
}