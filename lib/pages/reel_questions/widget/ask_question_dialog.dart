// lib/pages/reel_questions/widget/ask_question_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/font_style.dart';

class AskQuestionDialog extends StatelessWidget {
  final bool isAnswer;
  final bool isFollowUp;
  final Function(String) onSubmit;

  const AskQuestionDialog({
    super.key,
    this.isAnswer = false,
    this.isFollowUp = false,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final int maxLength = isAnswer ? 1000 : 500;
    final int minLength = isAnswer ? 5 : 10;
    final String title = isAnswer ? 'Responder' : (isFollowUp ? 'Continuar conversación' : 'Hacer una pregunta');
    final String hint = isAnswer ? 'Escribí tu respuesta...' : (isFollowUp ? 'Escribí tu mensaje...' : 'Escribí tu pregunta...');

    return Dialog(
      backgroundColor: Colors.grey[900],
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppFontStyle.styleW600(Colors.white, 18)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: maxLength,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[700]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColor.primary)),
                filled: true,
                fillColor: Colors.grey[850],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.length >= minLength) {
                      onSubmit(text);
                    } else {
                      Get.snackbar('Error', 'El texto debe tener al menos $minLength caracteres', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: const Text('Enviar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}