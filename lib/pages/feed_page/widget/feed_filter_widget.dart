//lib/pages/feed_page/widget/feed_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:opole/utils/color.dart';

class FeedFilterWidget extends StatelessWidget {
  const FeedFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FeedController>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // ðŸ”¹ Filtro por provincia
          Expanded(
            child: Obx(() => DropdownButtonFormField<String>(
              value: controller.filterProvince.value.isEmpty 
                  ? null 
                  : controller.filterProvince.value,
              decoration: InputDecoration(
                labelText: 'Provincia',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              items: ['Buenos Aires', 'CÃ³rdoba', 'Santa Fe', 'Mendoza']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) {
                controller.applyFilters(province: value ?? '');
              },
              isDense: true,
            )),
          ),
          
          const SizedBox(width: 8),
          
          // ðŸ”¹ Filtro por localidad (opcional)
          Expanded(
            child: Obx(() => DropdownButtonFormField<String>(
              value: controller.filterLocality.value.isEmpty 
                  ? null 
                  : controller.filterLocality.value,
              decoration: InputDecoration(
                labelText: 'Localidad',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              items: ['Capital', 'Gran Buenos Aires', 'Interior']
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (value) {
                controller.applyFilters(locality: value ?? '');
              },
              isDense: true,
            )),
          ),
          
          const SizedBox(width: 8),
          
          // ðŸ”¹ BotÃ³n limpiar filtros
          Obx(() => controller.filterProvince.value.isNotEmpty || 
                   controller.filterLocality.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: () => controller.clearFilters(),
                  tooltip: 'Limpiar filtros',
                )
              : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
