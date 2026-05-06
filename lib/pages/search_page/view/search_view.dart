// lib/pages/search_page/view/search_view.dart
// ===================================================================
// SEARCH VIEW v3.0 - GRID LAYOUT WITH AUTOPLAY
// ===================================================================
// ✅ GridView 3x3 con autoplay sin audio
// ✅ Navegación a vista inmersiva con lista completa
// ✅ Thumbnails con VideoPlayer optimizado
// ✅ Gestión de visibilidad para pausar/reproducir
// ✅ Caché de imágenes para fallback
// ===================================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/pages/search_page/controller/custom_search_controller.dart';
import 'package:opole/pages/search_page/widget/category_chip_widget.dart';
import 'package:opole/pages/search_page/widget/hashtag_chip_widget.dart';
import 'package:opole/pages/search_page/widget/search_reel_thumb.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/font_style.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomSearchController? controller = _getControllerSafe();
    
    if (controller == null) {
      return const Scaffold(
        backgroundColor: AppColor.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }
    
    // ✅ Auto-búsqueda con guard de mounted
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      final args = Get.arguments as Map<String, dynamic>;
      if (args.containsKey('category') && args['category'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!controller.hasSearchedFromRoute) {
            controller.markSearchedFromRoute();
            controller.searchByCategory(args['category']);
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        toolbarHeight: 80,
        title: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColor.colorGreyBg,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: controller.searchTextController,
            onChanged: controller.onSearch,
            decoration: InputDecoration(
              hintText: 'Buscar reels...',
              hintStyle: AppFontStyle.styleW400(AppColor.colorTextGrey, 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  AppAsset.icSearch,
                  width: 20,
                  color: AppColor.colorTextGrey,
                ),
              ),
              suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: Image.asset(AppAsset.icClose, width: 20, color: AppColor.colorTextGrey),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox.shrink()),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColor.colorBorderGrey)),
            ),
            child: Obx(() => Row(
              children: [
                _buildTab(controller, 'Todos', 0),
                _buildTab(controller, 'Categorías', 1),
                _buildTab(controller, 'Hashtags', 2),
              ],
            )),
          ),
          Expanded(child: _TabContent(controller: controller)),
        ],
      ),
    );
  }

  CustomSearchController? _getControllerSafe() {
    try {
      return Get.find<CustomSearchController>();
    } catch (_) {
      return null;
    }
  }

  Widget _buildTab(CustomSearchController controller, String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.onChangeTab(index),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: controller.selectedTabIndex.value == index ? AppColor.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: AppFontStyle.styleW500(
                controller.selectedTabIndex.value == index ? AppColor.primary : AppColor.colorTextGrey,
                14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  final CustomSearchController controller;
  
  const _TabContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.selectedTabIndex.value) {
        case 0: return _buildAllTab(controller);
        case 1: return _buildCategoriesTab(controller);
        case 2: return _buildHashtagsTab(controller);
        default: return const SizedBox.shrink();
      }
    });
  }

  Widget _buildAllTab(CustomSearchController controller) {
    return RefreshIndicator(
      onRefresh: () async {
        controller.resetSearchFlag();
        if (controller.searchQuery.value.isNotEmpty) {
          await controller.performSearch(controller.searchQuery.value);
        }
      },
      child: _buildSearchResultsGrid(controller),
    );
  }
  
  // 🆕 GRID VIEW 3x3 CON AUTOPLAY
  Widget _buildSearchResultsGrid(CustomSearchController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (controller.hasSearchError.value) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 16),
              const Text(
                "No se pudieron cargar los resultados", 
                style: TextStyle(color: Colors.black54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  controller.resetSearchFlag();
                  if (controller.searchQuery.value.isNotEmpty) {
                    controller.performSearch(controller.searchQuery.value);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (controller.searchResults.isEmpty && controller.searchQuery.value.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppAsset.icNoDataFound, width: 120, height: 120),
            const SizedBox(height: 16),
            Text('No se encontraron resultados', 
                 style: AppFontStyle.styleW400(AppColor.colorTextGrey, 16)),
          ],
        ),
      );
    }

    // 🎯 GRID VIEW 3 COLUMNAS
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 9 / 16, // Proporción vertical para videos
      ),
      itemCount: controller.searchResults.length,
      itemBuilder: (context, index) {
        final reel = controller.searchResults[index];
        return GestureDetector(
          onTap: () => controller.onTapReel(reel),
          child: SearchReelThumb(
            key: ValueKey('grid_${reel.id}_$index'),
            reel: reel,
            autoPlay: true,
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab(CustomSearchController controller) {
    if (controller.searchQuery.value.isNotEmpty) return _buildAllTab(controller);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: controller.categories.map((category) {
          return CategoryChipWidget(
            label: category,
            isSelected: controller.selectedCategory.value == category,
            onTap: () => controller.toggleCategory(category),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHashtagsTab(CustomSearchController controller) {
    if (controller.searchQuery.value.isNotEmpty) return _buildAllTab(controller);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: controller.trendingHashtags.map((hashtag) {
          return HashtagChipWidget(
            label: hashtag,
            isSelected: controller.selectedHashtags.contains(hashtag),
            onTap: () => controller.toggleHashtag(hashtag),
          );
        }).toList(),
      ),
    );
  }
}