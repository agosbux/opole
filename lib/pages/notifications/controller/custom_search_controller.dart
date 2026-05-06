// lib/pages/search_page/controller/custom_search_controller.dart
// ===================================================================
// CUSTOM SEARCH CONTROLLER v3.0 - GRID SUPPORT
// ===================================================================
// ✅ Flag _hasSearchedFromRoute solo se marca tras éxito
// ✅ Estado de error diferenciado para searchResults
// ✅ onQuestions verifica controller existente antes de crear
// ✅ Delegación a FeedController con fallback seguro
// ✅ Navegación a vista inmersiva con lista completa
// ✅ Mantiene: debounce, analytics, normalización, integración feed
// ===================================================================

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/core/supabase/supabase_api.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:opole/pages/reel_questions/controller/reel_questions_controller.dart';
import 'package:opole/pages/reel_questions/view/reel_questions_sheet.dart';
import 'package:opole/core/utils/analytics.dart';

class CustomSearchController extends GetxController {
  static CustomSearchController get to => Get.find<CustomSearchController>();
  
  final searchTextController = TextEditingController();
  final searchQuery = ''.obs;
  final selectedTabIndex = 0.obs;
  
  final searchResults = <ReelModel>[].obs;
  
  // 🆕 Estado de error para búsqueda (diferenciado de "vacío")
  final hasSearchError = false.obs;
  
  final categories = <String>[].obs;
  final selectedCategory = ''.obs;
  final trendingHashtags = <String>[].obs;
  final selectedHashtags = <String>[].obs;
  
  final isLoading = false.obs;
  
  // Flag para evitar búsqueda duplicada desde ruta
  bool _hasSearchedFromRoute = false;
  
  @override
  void onInit() {
    super.onInit();
    loadInitialData();
    
    debounce(
      searchQuery, 
      (_) => performSearch(searchQuery.value), 
      time: const Duration(milliseconds: 500)
    );
  }
  
  @override
  void onClose() {
    searchTextController.dispose();
    _hasSearchedFromRoute = false;
    hasSearchError.value = false;
    super.onClose();
  }
  
  void loadInitialData() {
    categories.value = [
      'Comedia', 'Deportes', 'Música', 'Educación',
      'Tecnología', 'Viajes', 'Comida', 'Moda',
    ];
    
    trendingHashtags.value = [
      '#viral', '#fyp', '#parati', '#humor',
      '#tendencia', '#music', '#dance', '#comedia',
    ];
  }
  
  void onSearch(String value) {
    searchQuery.value = value;
    hasSearchError.value = false; // Resetear error al cambiar query
    if (value.isEmpty) {
      clearResults();
    }
  }
  
  // ===================================================================
  // MÉTODO: Búsqueda por categoría/hashtag desde ruta
  // ===================================================================
  Future<void> searchByCategory(String category) async {
    try {
      // Evitar búsqueda duplicada si ya se ejecutó desde ruta
      if (_hasSearchedFromRoute) return;
      
      isLoading.value = true;
      hasSearchError.value = false;
      
      final normalized = category.toLowerCase().replaceAll(RegExp(r'[^\p{L}0-9_]'), '');
      searchQuery.value = normalized;
      
      final results = await SupabaseApi.instance.searchByHashtag(
        hashtag: normalized,
        limit: 20,
        excludeUserId: null,
      );
      
      searchResults.assignAll(results);
      selectedTabIndex.value = 0;
      
      // 🆕 MARCAR FLAG SOLO TRAS ÉXITO
      _hasSearchedFromRoute = true;
      
      Analytics.logEvent('search_by_category', parameters: {
        'category': normalized,
        'results_count': results.length,
        'source': 'hashtag_chip',
      });
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ [SEARCH] Error searching by category: $e');
        print('Stack: $stack');
      }
      hasSearchError.value = true; // 🆕 Estado de error explícito
      Get.snackbar('Error', 'No se pudo buscar por categoría', 
        backgroundColor: Colors.red[800], colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
  
  // 🆕 Método público para resetear flag (útil para retry manual)
  void resetSearchFlag() => _hasSearchedFromRoute = false;
  
  // ===================================================================
  // Búsqueda general (texto libre)
  // ===================================================================
  Future<void> performSearch(String query) async {
    if (query.isEmpty) {
      clearResults();
      return;
    }
    
    isLoading.value = true;
    hasSearchError.value = false;
    
    try {
      final normalized = query.toLowerCase().replaceAll(RegExp(r'[^\p{L}0-9_\s]'), '');
      
      final results = await SupabaseApi.instance.searchByHashtag(
        hashtag: normalized,
        limit: 20,
      );
      
      searchResults.assignAll(results);
      
      Analytics.logEvent('search_performed', parameters: {
        'query': normalized,
        'results_count': results.length,
        'tab_index': selectedTabIndex.value,
      });
      
    } catch (e) {
      if (kDebugMode) print('❌ [SEARCH] Error en performSearch: $e');
      hasSearchError.value = true; // 🆕 Estado de error explícito
      Get.snackbar('Error', 'No se pudo realizar la búsqueda', 
        backgroundColor: Colors.red[800], colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
  
  void clearResults() {
    searchResults.clear();
    hasSearchError.value = false;
  }
  
  void clearSearch() {
    searchTextController.clear();
    searchQuery.value = '';
    clearResults();
    selectedCategory.value = '';
    selectedHashtags.clear();
    _hasSearchedFromRoute = false;
  }
  
  void onChangeTab(int index) {
    selectedTabIndex.value = index;
    if (searchQuery.value.isNotEmpty) {
      performSearch(searchQuery.value);
    }
  }
  
  void toggleCategory(String category) {
    if (selectedCategory.value == category) {
      selectedCategory.value = '';
    } else {
      selectedCategory.value = category;
      searchByCategory(category);
    }
  }
  
  void toggleHashtag(String hashtag) {
    if (selectedHashtags.contains(hashtag)) {
      selectedHashtags.remove(hashtag);
    } else {
      selectedHashtags.add(hashtag);
      searchByCategory(hashtag);
    }
  }
  
  // ===================================================================
  // INTERACCIONES EN RESULTADOS (conectadas al feed)
  // ===================================================================
  
  void onLike(String reelId) {
    if (Get.isRegistered<FeedController>()) {
      Get.find<FeedController>().toggleLike(reelId);
    } else if (kDebugMode) {
      print('⚠️ [SEARCH] FeedController no registrado para like');
    }
  }
  
  void onLoQuiero(String reelId) {
    if (Get.isRegistered<FeedController>()) {
      Get.find<FeedController>().registerInterest(reelId);
    } else if (kDebugMode) {
      print('⚠️ [SEARCH] FeedController no registrado para loQuiero');
    }
  }
  
  void onQuestions(String reelId) {
    // 🆕 Verificar si ya existe antes de crear
    if (!Get.isRegistered<ReelQuestionsController>()) {
      Get.put(ReelQuestionsController(), permanent: false);
    }
    final qController = Get.find<ReelQuestionsController>();
    qController.loadQuestions(reelId);
    Get.bottomSheet(
      const ReelQuestionsSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }
  
  void onShare(String reelId) {
    Analytics.logEvent('reel_shared_search', parameters: {'reel_id': reelId});
    // TODO: Implementar native share con share_plus
  }
  
  // 🆕 NAVEGACIÓN A VISTA INMERSIVA CON LISTA COMPLETA
  void onTapReel(ReelModel reel) {
    final currentIndex = searchResults.indexWhere((r) => r.id == reel.id);
    
    Get.toNamed('/reels-inmersive', arguments: {
      'initialIndex': currentIndex >= 0 ? currentIndex : 0,
      'reels': searchResults.toList(), // Lista completa para swipe
      'source': 'search_grid',
      'searchQuery': searchQuery.value,
    });
    
    Analytics.logEvent('reel_tapped_search_grid', parameters: {
      'reel_id': reel.id,
      'index': currentIndex,
      'total_reels': searchResults.length,
      'search_query': searchQuery.value,
    });
  }
  
  // ===================================================================
  // Getters/Setters públicos
  // ===================================================================
  
  bool get hasSearchedFromRoute => _hasSearchedFromRoute;
  void markSearchedFromRoute() => _hasSearchedFromRoute = true;
}