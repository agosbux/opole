// lib/pages/reel_questions/view/reel_questions_sheet.dart
// ===================================================================
// REEL QUESTIONS SHEET v1.2 - Sin "Vendedor", con Delete y Report
// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controller/reel_questions_controller.dart';
import 'package:opole/core/supabase/models/question_model.dart';
import 'package:opole/controllers/session_controller.dart';
import 'package:opole/pages/reel_questions/widget/ask_question_dialog.dart';
import 'package:opole/pages/reel_questions/widget/report_dialog.dart';

// Colores por nivel
class LevelColors {
  static Color get(int level) {
    if (level >= 50) return const Color(0xFFBA68C8);
    if (level >= 35) return const Color(0xFFEC407A);
    if (level >= 20) return const Color(0xFFFFB300);
    if (level >= 10) return const Color(0xFF42A5F5);
    return const Color(0xFF66BB6A);
  }
  static Color getBackground(int level) => get(level).withOpacity(0.15);
  static Color getBorder(int level) => get(level).withOpacity(0.35);
}

class ReelQuestionsSheet extends StatelessWidget {
  final String reelId;
  
  const ReelQuestionsSheet({super.key, required this.reelId});

  SessionController get _session => SessionController.to;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SessionController>()) {
      return const SizedBox.shrink();
    }
    
    final controller = Get.find<ReelQuestionsController>(tag: 'questions_$reelId');

    return Container(
      height: Get.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 5) Get.back();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text("Preguntas y dudas", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          
          const Divider(color: Colors.white10, height: 1),

          // Lista
          Expanded(
            child: Obx(() {
              if (controller.hasError.value) {
                return _buildErrorState(controller);
              }
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
              }
              if (controller.questions.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: controller.questions.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final question = controller.questions[index];
                  return _QuestionTile(
                    key: ValueKey(question.id),
                    question: question,
                    controller: controller,
                  );
                },
              );
            }),
          ),

          _buildInputArea(controller, context),
        ],
      ),
    );
  }

  Widget _buildErrorState(ReelQuestionsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 16),
            const Text("No se pudieron cargar las preguntas", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => controller.retryLoad(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 48),
            SizedBox(height: 16),
            Text("Aún no hay preguntas.", style: TextStyle(color: Colors.white38)),
            Text("¡Sé el primero en preguntar!", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ReelQuestionsController controller, BuildContext context) {
    final bottomPadding = Get.bottomBarHeight > 0 ? Get.bottomBarHeight + 12 : MediaQuery.of(context).padding.bottom + 12;
    
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blueAccent.withOpacity(0.2),
            backgroundImage: _session.photoUrl != null && _session.photoUrl!.isNotEmpty
                ? NetworkImage(_session.photoUrl!)
                : null,
            child: (_session.photoUrl == null || _session.photoUrl!.isEmpty)
                ? const Icon(Icons.person, size: 20, color: Colors.blueAccent)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => TextField(
              controller: controller.textController,
              enabled: !controller.isAsking.value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (text) => _handleSend(controller, text),
              decoration: InputDecoration(
                hintText: "Preguntale algo al vendedor...",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                isDense: true,
              ),
            )),
          ),
          const SizedBox(width: 8),
          Obx(() => IconButton(
            onPressed: controller.isAsking.value ? null : () => _handleSend(controller, controller.textController.text),
            icon: controller.isAsking.value
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.blueAccent),
          )),
        ],
      ),
    );
  }

  void _handleSend(ReelQuestionsController controller, String text) {
    if (text.trim().isEmpty) return;
    controller.handleSendQuestion(text);
    FocusScope.of(Get.context!).unfocus();
  }
}

// ============================================================================
// 🔹 TILE INTERNO (sin "Vendedor", con menú de opciones)
// ============================================================================
class _QuestionTile extends StatelessWidget {
  final QuestionModel question;
  final ReelQuestionsController controller;

  const _QuestionTile({Key? key, required this.question, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Usuario + nivel + menú de opciones
          Row(
            children: [
              Text(
                "@${question.askerUsername ?? 'usuario'}",
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              if (question.askerLevel != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: LevelColors.getBackground(question.askerLevel!),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: LevelColors.getBorder(question.askerLevel!)),
                  ),
                  child: Text(
                    "Lvl ${question.askerLevel}",
                    style: TextStyle(color: LevelColors.get(question.askerLevel!), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const Spacer(),
              // Menú de opciones (Responder, Eliminar, Reportar, etc.)
              _buildOptionsMenu(context),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            question.questionText,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          // Respuesta
          if (question.answerText != null && question.answerText!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 12, left: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        "Respuesta${question.answererUsername != null ? ' de @${question.answererUsername}' : ''}",
                        style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.answerText!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.3),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
      color: Colors.grey[850],
      onSelected: (value) async {
        switch (value) {
          case 'answer':
            _showAnswerDialog(context);
            break;
          case 'delete':
            _confirmDelete(context);
            break;
          case 'report':
            _showReportDialog(context);
            break;
          case 'close':
            controller.closeConversation(questionId: question.id);
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        
        // Responder (solo dueño del reel y si no está respondida)
        if (controller.isCurrentUserReelOwner && !question.hasAnswer && !question.isThreadClosed) {
          items.add(const PopupMenuItem(value: 'answer', child: Text('Responder', style: TextStyle(color: Colors.white))));
        }
        // Eliminar (solo dueño del reel)
        if (controller.isCurrentUserReelOwner) {
          items.add(const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))));
        }
        // Cerrar conversación
        if (controller.canClose(question)) {
          items.add(const PopupMenuItem(value: 'close', child: Text('Cerrar conversación', style: TextStyle(color: Colors.white))));
        }
        // Reportar (todos, excepto quizás el dueño del reel? Lo dejamos para todos)
        items.add(const PopupMenuItem(value: 'report', child: Text('Reportar', style: TextStyle(color: Colors.orange))));
        
        return items;
      },
    );
  }

  void _showAnswerDialog(BuildContext context) {
    Get.dialog(AskQuestionDialog(
      isAnswer: true,
      onSubmit: (text) async {
        Get.back();
        await controller.answerQuestion(questionId: question.id, answerText: text);
      },
    ));
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Eliminar pregunta', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de eliminar esta pregunta?', style: TextStyle(color: Colors.grey)),
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

  void _showReportDialog(BuildContext context) {
    Get.dialog(ReportDialog(
      onSubmit: (reason, details) {
        controller.reportQuestion(questionId: question.id, reason: reason, details: details);
      },
    ));
  }
}