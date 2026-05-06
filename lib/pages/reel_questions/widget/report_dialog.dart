// lib/pages/reel_questions/widget/report_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/utils/color.dart';

class ReportDialog extends StatefulWidget {
  final Function(String reason, String? details) onSubmit;

  const ReportDialog({super.key, required this.onSubmit});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final List<String> _reasons = [
    'Lenguaje ofensivo',
    'Spam o publicidad',
    'Información engañosa',
    'Contenido inapropiado',
    'Violación de términos y condiciones',
    'Otro',
  ];
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reportar contenido', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Seleccioná el motivo del reporte:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ..._reasons.map((reason) => RadioListTile<String>(
              title: Text(reason, style: const TextStyle(color: Colors.white)),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
              activeColor: AppColor.primary,
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Detalles adicionales (opcional)',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedReason == null
                      ? null
                      : () {
                          widget.onSubmit(_selectedReason!, _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim());
                          Get.back();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Enviar reporte', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}