// lib/pages/bottom_bar_page/controller/bottom_bar_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opole/core/services/supabase_client.dart' as local;
import 'package:opole/routes/app_routes.dart';
import 'package:opole/core/services/auth_service.dart';
import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:opole/controllers/session_controller.dart';

class BottomBarController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxInt unreadNotifications = 0.obs;
  final RxBool isLoadingNotifications = false.obs;

  SessionController get _session => SessionController.to;
  String? get currentUserId =>
      _session.uid.isNotEmpty ? _session.uid : local.SupabaseClient.currentUserId;
  bool get isLoggedIn => _session.uid.isNotEmpty;

  // ✅ Tabs actualizados: Índice 3 → Notificaciones, Índice 4 → Perfil
  final List<Map<String, dynamic>> tabs = [
    {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Inicio'},
    {'icon': Icons.search_outlined, 'activeIcon': Icons.search, 'label': 'Buscar'},
    {'icon': Icons.add_circle_outline, 'activeIcon': Icons.add_circle, 'label': 'Publicar'},
    {'icon': Icons.notifications_outlined, 'activeIcon': Icons.notifications, 'label': 'Notificaciones'},
    {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Perfil'},
  ];

  StreamSubscription<AuthState>? _authSubscription;
  Timer? _notificationsDebounce;

  @override
  void onInit() {
    super.onInit();
    Get.log('🚀 [BOTTOM BAR] onInit - Iniciando controller');

    if (!Get.isRegistered<FeedController>()) {
      Get.put<FeedController>(FeedController(), permanent: true);
      Get.log('📦 [BOTTOM BAR] FeedController registrado (permanent)');
    }

    _setupAuthListener();

    if (isLoggedIn) {
      _triggerNotificationsLoad();
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _notificationsDebounce?.cancel();
    Get.log('🧹 [BOTTOM BAR] onClose - Resources cleaned');
    super.onClose();
  }

  void changeTab(int index) {
    Get.log('👆 [TAB] Tocaste el índice $index - ${tabs[index]['label']}');

    if (!_canAccessTab(index)) {
      Get.log('⚠️ [TAB] Acceso denegado al tab $index - requiere login');
      _promptLoginIfNeeded();
      return;
    }

    final wasOnHome = currentIndex.value == 0;
    final goingToHome = index == 0;

    if (wasOnHome && !goingToHome) {
      if (Get.isRegistered<FeedController>()) {
        Get.find<FeedController>().pauseAllVideos();
        Get.log('⏸️ [BOTTOM BAR] Videos pausados al salir de Home');
      }
    }

    // Tab 2: Publicar (abre upload)
    if (index == 2) {
      Get.log('📤 [TAB] Navegando a Upload Reels');
      _navigateToUpload();
      return;
    }

    // Doble tap en Home refresca feed
    if (index == 0 && currentIndex.value == 0) {
      Get.log('🔄 [TAB] Refrescando feed (doble tap en Home)');
      refreshFeed();
      return;
    }

    if (currentIndex.value != index) {
      currentIndex.value = index;
      update(["onChangeBottomBar"]);
      Get.log('🎯 [TAB] Índice actualizado a: $index');

      if (goingToHome && Get.isRegistered<FeedController>()) {
        Get.find<FeedController>().resumeActiveVideo();
        Get.log('▶️ [BOTTOM BAR] Video reanudado al volver a Home');
      }
    }
  }

  bool _canAccessTab(int index) {
    // Índices 2, 3, 4 requieren autenticación
    final requiresAuth = [2, 3, 4].contains(index);
    return !requiresAuth || isLoggedIn;
  }

  void _promptLoginIfNeeded() {
    if (!isLoggedIn) {
      Get.snackbar(
        'Iniciar sesión',
        'Registrate para acceder a esta sección',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue[800],
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        mainButton: TextButton(
          onPressed: () => Get.toNamed(AppRoutes.loginPage),
          child: const Text(
            'Ir a Login',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _navigateToUpload() {
    if (!isLoggedIn) {
      _promptLoginIfNeeded();
      return;
    }
    Get.toNamed(AppRoutes.uploadReelsPage);
  }

  void refreshFeed() {
    if (Get.isRegistered<FeedController>()) {
      try {
        final feedController = Get.find<FeedController>();
        feedController.fetchFeed(refresh: true);
        Get.log('🔄 [BOTTOM BAR] Feed recargado manualmente');
      } catch (e) {
        Get.log('❌ [BOTTOM BAR] Error refrescando feed: $e');
      }
    }
  }

  void _triggerNotificationsLoad() {
    _notificationsDebounce?.cancel();
    _notificationsDebounce = Timer(const Duration(milliseconds: 300), _loadUnreadNotifications);
    Get.log('⏱️ [NOTIF] Debounce iniciado para cargar notificaciones');
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      if (!isLoggedIn || currentUserId == null) {
        Get.log('⚠️ [NOTIF] Sin usuario - Skipping notifications');
        return;
      }

      isLoadingNotifications.value = true;
      Get.log('🔍 [NOTIF] Cargando notificaciones para: $currentUserId');

      final notifications = await local.SupabaseClient
          .from('notifications')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('read', false);

      final count = notifications.length;
      unreadNotifications.value = count > 99 ? 99 : count;

      Get.log('🔔 [NOTIF] Notificaciones no leídas: $count');
    } on PostgrestException catch (e) {
      Get.log('❌ [NOTIF] Error Postgrest: ${e.message}');
      unreadNotifications.value = 0;
    } catch (e, stack) {
      Get.log('❌ [NOTIF] Error inesperado: $e');
      Get.log('📋 [NOTIF] Stack: $stack');
      unreadNotifications.value = 0;
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  void _setupAuthListener() {
    _authSubscription = local.SupabaseClient.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        Get.log('🔄 [AUTH] Usuario autenticado - Recargando notificaciones');
        _triggerNotificationsLoad();
      } else if (event.event == AuthChangeEvent.signedOut) {
        Get.log('🔄 [AUTH] Usuario deslogueado - Limpiando notificaciones');
        unreadNotifications.value = 0;
      }
    });
    Get.log('✅ [AUTH] Listener configurado');
  }

  Future<void> refreshNotifications() async {
    await _loadUnreadNotifications();
  }

  Future<void> markNotificationsAsRead() async {
    try {
      if (!isLoggedIn || currentUserId == null) return;

      Get.log('✅ [NOTIF] Marcando notificaciones como leídas...');

      await local.SupabaseClient
          .from('notifications')
          .update({'read': true})
          .eq('user_id', currentUserId)
          .eq('read', false);

      unreadNotifications.value = 0;
      Get.log('✅ [NOTIF] Notificaciones actualizadas');
    } catch (e) {
      Get.log('❌ [NOTIF] Error marcando notificaciones: $e');
    }
  }

  void goToNotifications() {
    markNotificationsAsRead();
    // Al estar ya en el tab 3, solo marcamos como leídas, no navegamos
    Get.log('🔔 [BOTTOM BAR] Notificaciones marcadas como leídas');
  }

  Future<void> logout() async {
    try {
      Get.log('🚪 [BOTTOM BAR] Iniciando logout...');

      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '¿Cerrar sesión?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Vas a tener que iniciar sesión nuevamente para acceder a tu cuenta.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Get.back(result: true),
              child: const Text('Sí, cerrar'),
            ),
          ],
        ),
        barrierDismissible: true,
      );

      if (confirmed != true) {
        Get.log('⏭️ [BOTTOM BAR] Logout cancelado por usuario');
        return;
      }

      final authService = Get.find<AuthService>();
      await authService.signOut();

      unreadNotifications.value = 0;
      currentIndex.value = 0;
      update();

      Get.offAllNamed(AppRoutes.loginPage);
      Get.log('✅ [BOTTOM BAR] Logout completado');
    } catch (e) {
      Get.log('❌ [BOTTOM BAR] Error en logout: $e');
      Get.snackbar(
        'Error',
        'No se pudo cerrar sesión. Intente nuevamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  IconData get currentIcon => tabs[currentIndex.value]['icon'];
  IconData get currentActiveIcon => tabs[currentIndex.value]['activeIcon'];
  String get currentLabel => tabs[currentIndex.value]['label'];
  bool get hasUnreadNotifications => unreadNotifications.value > 0;
  String get notificationBadgeText {
    if (unreadNotifications.value == 0) return '';
    if (unreadNotifications.value > 99) return '99+';
    return unreadNotifications.value.toString();
  }
}