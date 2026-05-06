// lib/pages/feed_page/widgets/question_card.dart
// ===================================================================
// QUESTION CARD - Compatible con QuestionModel.isThreadClosed âœ…
// ===================================================================

import 'package:flutter/material.dart';
import 'package:opole/core/supabase/models/question_model.dart';
import 'package:opole/theme/app_colors.dart';

class QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback? onReply;
  final VoidCallback? onFollowUp;
  final VoidCallback? onClose;
  final bool isReelOwner;
  final bool isAsker;

  const QuestionCard({Key? key, required this.question, this.onReply, this.onFollowUp, this.onClose, this.isReelOwner = false, this.isAsker = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: question.isThreadClosed ? Colors.grey.shade300 : question.isAnswered ? Colors.green.shade200 : AppColors.primary!.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Text((question.askerUsername ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(question.askerUsername ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Text(_formatDate(question.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade600))])),
                if (question.isThreadClosed) _buildBadge('Cerrada', Colors.grey),
                if (question.isAnswered && !question.isThreadClosed) _buildBadge('Respondida', Colors.green),
                if (question.followupsCount > 0) _buildBadge('${question.followupsCount} ðŸ”', AppColors.primary),
              ],
            ),
            const SizedBox(height: 10),
            Text(question.questionText, style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4)),
            if (question.isAnswered && question.answerText != null) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200!)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_circle, size: 16, color: Colors.green), const SizedBox(width: 6), Expanded(child: Text(question.answerText!, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3)))])),
            ],
            if (_showActions) ...[const SizedBox(height: 10), Divider(height: 1, color: Colors.grey.shade200), const SizedBox(height: 8), Row(children: _buildActionButtons())],
          ],
        ),
      ),
    );
  }

  bool get _showActions => (isReelOwner && !question.isAnswered && !question.isThreadClosed) || (isAsker && question.isAnswered && !question.isThreadClosed) || ((isReelOwner || isAsker) && !question.isThreadClosed);

  List<Widget> _buildActionButtons() {
    final actions = <Widget>[];
    if (isReelOwner && !question.isAnswered && !question.isThreadClosed && onReply != null) {
      actions.add(Expanded(child: OutlinedButton.icon(onPressed: onReply, icon: const Icon(Icons.reply, size: 16), label: const Text('Responder'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), side: BorderSide(color: AppColors.primary!)))));
    }
    if (isAsker && question.isAnswered && !question.isThreadClosed && onFollowUp != null) {
      actions.add(Expanded(child: OutlinedButton.icon(onPressed: onFollowUp, icon: const Icon(Icons.add_comment, size: 16), label: const Text('Seguir'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), side: BorderSide(color: Colors.green)))));
    }
    if (!question.isThreadClosed && onClose != null) {
      actions.add(IconButton(onPressed: onClose, icon: const Icon(Icons.check, size: 18), tooltip: 'Marcar como resuelta', color: Colors.green));
    }
    return actions;
  }

  Widget _buildBadge(String label, Color color) => Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)));

  String _formatDate(DateTime date) { final now = DateTime.now(); final diff = now.difference(date); if (diff.inMinutes < 1) return 'Ahora'; if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m'; if (diff.inHours < 24) return 'hace ${diff.inHours}h'; return '${date.day}/${date.month}'; }
}
