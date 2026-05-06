// lib/pages/search_page/controller/custom_search_controller.dart
// ===================================================================
// CUSTOM SEARCH CONTROLLER v2.1 - PRODUCTION SAFE
// ===================================================================
// ✅ Flag _hasSearchedFromRoute solo se marca tras éxito
// ✅ Estado de error diferenciado para searchResults
// ✅ onQuestions con tags únicos por reel
// ✅ Cleanup automático de controllers al cerrar sheet
// ✅ Race condition prevention con _currentOperationId
// ✅ Delegación a FeedController con fallback seguro
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
  
  // Estado de error para búsqueda (diferenciado de "vacío")
  final hasSearchError = false.obs;
  
  final categories = <String>[].obs;
  final selectedCategory = ''.obs;
  final trendingHashtags = <String>[].obs;
  final selectedHashtags = <String>[].obs;
  
  final isLoading = false.obs;
  final isSearching = false.obs;
  
  // Flag para evitar búsqueda duplicada desde ruta
  bool _hasSearchedFromRoute = false;
  
  // Race condition prevention
  int _currentOperationId = 0;
  
  // Flag para evitar múltiples aperturas de questions
  bool _isOpeningQuestions = false;
  
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
    cancelPendingOperations();
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
    hasSearchError.value = false;
    if (value.isEmpty) {
      clearResults();
    }
  }
  
  // ===================================================================
  // MÉTODO: Búsqueda por categoría/hashtag desde ruta
  // ===================================================================
  Future<void> searchByCategory(String category) async {
    // Guard contra múltiples llamadas simultáneas
    if (isSearching.value) {
      if (kDebugMode) print('⚠️ [SEARCH] Búsqueda ya en progreso, ignorando');
      return;
    }
    
    // Evitar búsqueda duplicada si ya se ejecutó desde ruta
    if (_hasSearchedFromRoute) return;
    
    // Asignar ID único a esta operación
    final operationId = ++_currentOperationId;
    
    isLoading.value = true;
    isSearching.value = true;
    hasSearchError.value = false;
    
    try {
      final normalized = category.toLowerCase().replaceAll(RegExp(r'[^\p{L}0-9_]'), '');
      searchQuery.value = normalized;
      
      final results = await SupabaseApi.instance.searchByHashtag(
        hashtag: normalized,
        limit: 20,
        excludeUserId: null,
      );
      
      // Verificar que esta operación sigue siendo la más reciente
      if (operationId != _currentOperationId) {
        if (kDebugMode) print('⚠️ [SEARCH] Operación obsoleta, ignorando resultados');
        return;
      }
      
      searchResults.assignAll(results);
      selectedTabIndex.value = 0;
      
      // MARCAR FLAG SOLO TRAS ÉXITO
      _hasSearchedFromRoute = true;
      
      Analytics.logEvent('search_by_category', parameters: {
        'category': normalized,
        'results_count': results.length,
        'source': 'hashtag_chip',
      });
      
    } catch (e, stack) {
      // Solo procesar error si es la operación más reciente
      if (operationId != _currentOperationId) return;
      
      if (kDebugMode) {
        print('❌ [SEARCH] Error searching by category: $e');
        print('Stack: $stack');
      }
      hasSearchError.value = true;
      Get.snackbar('Error', 'No se pudo buscar por categoría', 
        backgroundColor: Colors.red[800], colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM);
    } finally {
      // Solo resetear si es la operación más reciente
      if (operationId == _currentOperationId) {
        isLoading.value = false;
        isSearching.value = false;
      }
    }
  }
  
  // Método público para resetear flag (útil para retry manual)
  void resetSearchFlag() => _hasSearchedFromRoute = false;
  
  // ===================================================================
  // Búsqueda general (texto libre)
  // ===================================================================
  Future<void> performSearch(String query) async {
    if (query.isEmpty) {
      clearResults();
      return;
    }
    
    // Guard contra múltiples llamadas
    if (isSearching.value) return;
    
    final operationId = ++_currentOperationId;
    
    isLoading.value = true;
    isSearching.value = true;
    hasSearchError.value = false;
    
    try {
      final normalized = query.toLowerCase().replaceAll(RegExp(r'[^\p{L}0-9_\s]'), '');
      
      final results = await SupabaseApi.instance.searchByHashtag(
        hashtag: normalized,
        limit: 20,
      );
      
      if (operationId != _currentOperationId) return;
      
      searchResults.assignAll(results);
      
      Analytics.logEvent('search_performed', parameters: {
        'query': normalized,
        'results_count': results.length,
        'tab_index': selectedTabIndex.value,
      });
      
    } catch (e) {
      if (operationId != _currentOperationId) return;
      
      if (kDebugMode) print('❌ [SEARCH] Error en performSearch: $e');
      hasSearchError.value = true;
      Get.snackbar('Error', 'No se pudo realizar la búsqueda', 
        backgroundColor: Colors.red[800], colorText: Colors.white);
    } finally {
      if (operationId == _currentOperationId) {
        isLoading.value = false;
        isSearching.value = false;
      }
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
    // Tag único por reel para evitar colisiones de estado
    final questionsTag = 'questions_$reelId';
    
    // Evitar múltiples taps que abran el mismo sheet
    if (_isOpeningQuestions) return;
    _isOpeningQuestions = true;
    
    try {
      // Registrar/find controller CON TAG
      if (!Get.isRegistered<ReelQuestionsController>(tag: questionsTag)) {
        Get.put(ReelQuestionsController(), tag: questionsTag, permanent: false);
      }
      final qController = Get.find<ReelQuestionsController>(tag: questionsTag);
      
      // Configurar controller
      qController.loadQuestions(reelId);
      
      // Abrir sheet PASANDO reelId
      Get.bottomSheet(
        ReelQuestionsSheet(reelId: reelId),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        ignoreSafeArea: false,
        clipBehavior: Clip.antiAlias,
      )?.whenComplete(() {
        // Cleanup al cerrar
        _cleanupQuestionsController(questionsTag);
        _isOpeningQuestions = false;
      }).catchError((error) {
        // Manejo de errores al abrir el sheet
        if (kDebugMode) print('❌ [SEARCH] Error opening questions sheet: $error');
        _cleanupQuestionsController(questionsTag);
        _isOpeningQuestions = false;
      });
      
      // Analytics
      Analytics.logEvent('questions_opened_from_search', parameters: {
        'reel_id': reelId,
      });
      
    } catch (e) {
      if (kDebugMode) print('❌ [SEARCH] Error in onQuestions: $e');
      _cleanupQuestionsController(questionsTag);
      _isOpeningQuestions = false;
    }
  }
  
  // Helper para cleanup consistente de questions controller
  void _cleanupQuestionsController(String tag) {
    if (Get.isRegistered<ReelQuestionsController>(tag: tag)) {
      try {
        // Intentar llamar dispose si existe
        final controller = Get.find<ReelQuestionsController>(tag: tag);
        if (controller.hasListeners) {
          controller.dispose();
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ [SEARCH] Error disposing questions controller: $e');
      } finally {
        // Forzar eliminación del controller
        Get.delete<ReelQuestionsController>(tag: tag, force: true);
      }
    }
  }
  
  void onShare(String reelId) {
    Analytics.logEvent('reel_shared_search', parameters: {'reel_id': reelId});
    // TODO: Implementar native share con share_plus
  }
  
  void onTapReel(ReelModel reel) {
    Get.toNamed('/reels-inmersive', arguments: {
      'reelId': reel.id,
      'source': 'search',
    });
    
    Analytics.logEvent('reel_tapped_search', parameters: {
      'reel_id': reel.id,
      'category': searchQuery.value,
    });
  }
  
  // ===================================================================
  // UTILIDADES
  // ===================================================================
  
  // Cancelar operaciones pendientes (útil en dispose)
  void cancelPendingOperations() {
    _currentOperationId++;
    isSearching.value = false;
  }
  
  // ===================================================================
  // Getters/Setters públicos
  // ===================================================================
  
  bool get hasSearchedFromRoute => _hasSearchedFromRoute;
  void markSearchedFromRoute() => _hasSearchedFromRoute = true;
}