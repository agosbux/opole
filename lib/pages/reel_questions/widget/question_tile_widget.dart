// lib/pages/reel_questions/widget/question_tile_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/pages/reel_questions/controller/reel_questions_controller.dart';
import 'package:opole/core/supabase/models/question_model.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/font_style.dart';

class QuestionTileWidget extends StatelessWidget {
  final QuestionModel question;
  final ReelQuestionsController controller;
  final VoidCallback? onAnswerTap;
  final VoidCallback? onFollowUpTap;
  final VoidCallback? onCloseTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onReportTap;

  const QuestionTileWidget({
    super.key,
    required this.question,
    required this.controller,
    this.onAnswerTap,
    this.onFollowUpTap,
    this.onCloseTap,
    this.onDeleteTap,
    this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: question.hasAnswer ? AppColor.primary : Colors.grey[800]!,
          width: question.hasAnswer ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColor.primary.withOpacity(0.2),
                child: question.askerPhoto != null
                    ? ClipOval(child: Image.network(question.askerPhoto!, width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 18)))
                    : const Icon(Icons.person, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(question.askerUsername, style: AppFontStyle.styleW600(Colors.white, 14)),
                        if (question.askerLevel != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(8)),
                            child: Text('N${question.askerLevel}', style: AppFontStyle.styleW400(Colors.white, 10)),
                          ),
                        ],
                      ],
                    ),
                    Text(_formatDate(question.createdAt), style: AppFontStyle.styleW400(Colors.grey[400]!, 11)),
                  ],
                ),
              ),
              // Estado
              if (question.isThreadClosed)
                _buildStatusChip('Cerrado 🔒', Colors.grey)
              else if (question.hasAnswer)
                _buildStatusChip('Respondido ✅', AppColor.primary)
              else
                _buildStatusChip('Pendiente ⏳', Colors.orange),
              // Menú de opciones
              _buildOptionsMenu(),
            ],
          ),
          
          const SizedBox(height: 12),
          Text(question.questionText, style: AppFontStyle.styleW400(Colors.white, 15)),
          
          // Respuesta
          if (question.hasAnswer) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColor.primary.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 16, color: AppColor.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${question.answererUsername ?? 'Respuesta'}:', style: AppFontStyle.styleW600(AppColor.primary, 13)),
                        const SizedBox(height: 4),
                        Text(question.answerText!, style: AppFontStyle.styleW400(Colors.white70, 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Follow-ups (si los hay)
          if (question.hasFollowups && question.followupsCount > 0) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // Navegar a vista de conversación o expandir
              },
              icon: const Icon(Icons.chat, size: 16),
              label: Text('Ver ${question.followupsCount} ${question.followupsCount == 1 ? 'respuesta' : 'respuestas'}', style: AppFontStyle.styleW400(AppColor.primary, 13)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(label, style: AppFontStyle.styleW400(color, 11)),
    );
  }

  Widget _buildOptionsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
      color: Colors.grey[850],
      onSelected: (value) {
        switch (value) {
          case 'answer':
            onAnswerTap?.call();
            break;
          case 'followup':
            onFollowUpTap?.call();
            break;
          case 'close':
            onCloseTap?.call();
            break;
          case 'delete':
            onDeleteTap?.call();
            break;
          case 'report':
            onReportTap?.call();
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        
        // Responder (solo dueño)
        if (controller.canAnswer(question)) {
          items.add(const PopupMenuItem(value: 'answer', child: Text('Responder', style: TextStyle(color: Colors.white))));
        }
        // Follow-up (si hay respuesta y no está cerrada)
        if (controller.canFollowUp(question)) {
          items.add(const PopupMenuItem(value: 'followup', child: Text('Continuar conversación', style: TextStyle(color: Colors.white))));
        }
        // Cerrar
        if (controller.canClose(question)) {
          items.add(const PopupMenuItem(value: 'close', child: Text('Cerrar conversación', style: TextStyle(color: Colors.white))));
        }
        // Eliminar (solo dueño del reel)
        if (controller.isCurrentUserReelOwner) {
          items.add(const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))));
        }
        // Reportar (todos)
        items.add(const PopupMenuItem(value: 'report', child: Text('Reportar', style: TextStyle(color: Colors.orange))));
        
        return items;
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}