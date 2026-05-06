// lib/pages/notifications/controller/notifications_controller.dart
// ===================================================================
// NOTIFICATIONS CONTROLLER - Query optimizada a tu schema de 6 columnas
// ===================================================================

import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:opole/core/services/supabase_client.dart' as local;
import 'package:opole/controllers/session_controller.dart';
import '../model/notification_model.dart';

class NotificationsController extends GetxController {
  static NotificationsController get to => Get.find();
  
  final notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;
  final hasUnread = false.obs;
  
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    _startPolling();
    fetchNotifications();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (Get.isRegistered<SessionController>() && SessionController.to.isReady) {
        fetchNotifications(refresh: true);
      }
    });
  }

  // 📥 Fetch exacto a tu tabla
  Future<void> fetchNotifications({bool refresh = false}) async {
    final userId = SessionController.to.uid;
    if (userId.isEmpty) return;
    if (!refresh && notifications.isNotEmpty) return;
    
    isLoading.value = true;
    try {
      final response = await local.SupabaseClient
          .from('notifications')
          .select('id, user_id, type, data, read, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final parsed = (response as List).map((row) => 
        NotificationModel.fromSupabase(row as Map<String, dynamic>)
      ).toList();

      if (refresh) {
        notifications.assignAll(parsed);
      } else {
        notifications.addAll(parsed.where((n) => 
          !notifications.any((existing) => existing.id == n.id)
        ));
      }
      
      hasUnread.value = notifications.any((n) => !n.isRead);
      if (kDebugMode) Get.log('🔔 [NOTIF] Cargadas ${parsed.length} notificaciones');
      
    } catch (e, stack) {
      if (kDebugMode) {
        Get.log('❌ [NOTIF] Error: $e\n📋 Stack: $stack');
      }
      if (notifications.isEmpty) _loadDemoData();
    } finally {
      isLoading.value = false;
    }
  }

  void _loadDemoData() {
    final now = DateTime.now();
    notifications.assignAll([
      NotificationModel(
        id: 'demo_1', userId: 'user', type: NotificationType.loQuiero,
        data: {
          'reel_id': 'reel_123', 'reel_title': 'iPhone 13 Pro',
          'from_user_id': 'usr_456', 'from_username': 'carlos_tech',
          'from_user_level': 7, 'wait_until': now.add(const Duration(hours: 47)).toIso8601String()
        },
        isRead: false, createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      NotificationModel(
        id: 'demo_2', userId: 'user', type: NotificationType.profilePointAdd,
        data: {'action_id': 'complete_profile', 'points': 10},
        isRead: false, createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'demo_3', userId: 'user', type: NotificationType.boostPointSub,
        data: {'action_id': 'penalty_no_response', 'points': 2},
        isRead: true, createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);
    hasUnread.value = true;
  }

  Future<void> markAsRead(String id) async {
    try {
      await local.SupabaseClient.from('notifications').update({'read': true}).eq('id', id);
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        notifications[idx] = NotificationModel(
          id: notifications[idx].id,
          userId: notifications[idx].userId,
          type: notifications[idx].type,
          data: notifications[idx].data,
          isRead: true, // ✅ Actualizado
          createdAt: notifications[idx].createdAt,
        );
        notifications.refresh();
      }
      hasUnread.value = notifications.any((n) => !n.isRead);
    } catch (e) {
      if (kDebugMode) Get.log('❌ [NOTIF] Error markAsRead: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await local.SupabaseClient.from('notifications')
          .update({'read': true})
          .eq('user_id', SessionController.to.uid)
          .eq('read', false);
      
      notifications.assignAll(notifications.map((n) => NotificationModel(
        id: n.id, userId: n.userId, type: n.type, data: n.data,
        isRead: true, createdAt: n.createdAt,
      )).toList());
      hasUnread.value = false;
    } catch (e) {
      if (kDebugMode) Get.log('❌ [NOTIF] Error markAllAsRead: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await local.SupabaseClient.from('notifications').delete().eq('id', id);
      notifications.removeWhere((n) => n.id == id);
      hasUnread.value = notifications.any((n) => !n.isRead);
    } catch (e) {
      if (kDebugMode) Get.log('❌ [NOTIF] Error delete: $e');
    }
  }

  void viewUserProfile(String userId) => Get.toNamed('/profile', arguments: {'userId': userId, 'isOtherUser': true});
  void viewReel(String reelId) => Get.toNamed('/reels-inmersive', arguments: {'reelId': reelId, 'source': 'notification'});
}