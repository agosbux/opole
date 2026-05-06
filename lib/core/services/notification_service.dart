import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:opole/core/services/supabase_client.dart' as supabase;
import 'package:opole/routes/app_routes.dart';

class NotificationService extends GetxService {
  static NotificationService? _instance;
  static NotificationService get instance {
    _instance ??= Get.put(NotificationService());
    return _instance!;
  }

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    _currentUserId = supabase.SupabaseClient.currentUserId;
    _initializeNotifications();
    _setupMessageHandlers();
  }

  // ===================================================================
  // ðŸ”¹ INICIALIZACIÃ“N
  // ===================================================================
  Future<void> _initializeNotifications() async {
    // ðŸ”¹ 1. Request permissions
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      Get.log('âš ï¸ [NOTIFICATIONS] Permisos de notificaciÃ³n denegados');
      return;
    }

    // ðŸ”¹ 2. Initialize local notifications (para foreground)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // ðŸ”¹ 3. Get FCM token y guardar en Supabase
    await _registerFcmToken();

    // ðŸ”¹ 4. Configurar canales de notificaciÃ³n (Android)
    await _createNotificationChannels();

    // ðŸ”¹ 5. Escuchar refresco de token
    _listenForTokenRefresh();

    Get.log('âœ… [NOTIFICATIONS] Servicio inicializado');
  }

  // ===================================================================
  // ðŸ”¹ REGISTRO DE TOKEN FCM EN SUPABASE
  // ===================================================================
  Future<void> _registerFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null || _currentUserId == null) return;

      // âœ… CORRECCIÃ“N: onConflict para evitar errores de duplicados
      await supabase.SupabaseClient.from('user_devices')
          .upsert({
            'user_id': _currentUserId,
            'fcm_token': token,
            'platform': Platform.isAndroid ? 'android' : 'ios',
            'last_used_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,fcm_token')
          .select();

      Get.log('âœ… [FCM] Token registrado: ${token.substring(0, 20)}...');
    } catch (e) {
      Get.log('âŒ [FCM] Error registrando token: $e');
    }
  }

  // ===================================================================
  // ðŸ”¹ CREAR CANALES DE NOTIFICACIÃ“N (Android)
  // ===================================================================
  Future<void> _createNotificationChannels() async {
    const channelLoQuiero = AndroidNotificationChannel(
      'lo_quiero_channel',
      'Â¡Nuevo Lo Quiero!',
      description: 'Cuando alguien muestra interÃ©s en tu producto',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const channelPreguntas = AndroidNotificationChannel(
      'preguntas_channel',
      'Nueva Pregunta',
      description: 'Cuando alguien pregunta sobre tu reel',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channelLoQuiero);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channelPreguntas);
  }

  // ===================================================================
  // ðŸ”¹ HANDLERS DE MENSAJES
  // ===================================================================
  void _setupMessageHandlers() {
    // ðŸ”¹ Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Get.log('ðŸ“¬ [FCM] Mensaje en foreground: ${message.data}');
      _showLocalNotification(message);
    });

    // ðŸ”¹ Background/terminated messages (al abrir la app)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Get.log('ðŸ”” [FCM] NotificaciÃ³n tocada (background): ${message.data}');
      _handleNotificationData(message.data);
    });

    // ðŸ”¹ Check if app was opened from notification (cold start)
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    final message = await _fcm.getInitialMessage();
    if (message != null) {
      Get.log('ðŸ”” [FCM] App abierta desde notificaciÃ³n (cold start)');
      _handleNotificationData(message.data);
    }
  }

  // ===================================================================
  // ðŸ”¹ MOSTRAR NOTIFICACIÃ“N LOCAL (Foreground)
  // ===================================================================
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    
    if (notification == null) return;

    final id = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    const androidDetails = AndroidNotificationDetails(
      'lo_quiero_channel',
      'Â¡Nuevo Lo Quiero!',
      channelDescription: 'Cuando alguien muestra interÃ©s en tu producto',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data),
    );
  }

  // ===================================================================
  // ðŸ”¹ HANDLER AL TOCAR NOTIFICACIÃ“N (Deep Linking)
  // ===================================================================
  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    
    final data = jsonDecode(response.payload!) as Map<String, dynamic>;
    Get.log('ðŸ”” [NOTIFICATIONS] NotificaciÃ³n tocada: $data');
    _handleNotificationData(data);
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final reelId = data['reel_id'] as String?;
    final openQuestions = data['openQuestions'] == 'true';
    final questionId = data['question_id'] as String?;

    if (reelId == null) return;

    try {
      switch (type) {
        case 'nuevo_lo_quiero':
          Get.toNamed(
            AppRoutes.reelsInmersivePage,
            arguments: {
              'reelId': reelId,
              'fromNotification': true,
              'openQuestions': false,
            },
          );
          break;

        case 'nueva_pregunta_reel':
        case 'respuesta_a_pregunta':
        case 'nuevo_followup_pregunta':
          Get.toNamed(
            AppRoutes.reelsInmersivePage,
            arguments: {
              'reelId': reelId,
              'fromNotification': true,
              'openQuestions': true,
              'questionId': questionId,
            },
          );
          break;

        default:
          Get.log('âš ï¸ [NOTIFICATIONS] Tipo desconocido: $type');
      }
    } catch (e) {
      Get.log('âŒ [NOTIFICATIONS] Error navegando desde notificaciÃ³n: $e');
    }
  }

  // ===================================================================
  // ðŸ”¹ MÃ‰TODOS PÃšBLICOS
  // ===================================================================

  // âœ… NUEVO: MÃ©todo pÃºblico para mostrar notificaciÃ³n local desde main.dart
  Future<void> mostrarNotificacionLocal({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const androidDetails = AndroidNotificationDetails(
      'lo_quiero_channel',
      'Â¡Nuevo Lo Quiero!',
      channelDescription: 'Cuando alguien muestra interÃ©s en tu producto',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload != null ? jsonEncode(payload) : null,
    );
    
    Get.log('ðŸ”” [LOCAL] NotificaciÃ³n mostrada: $title');
  }

  Future<void> updateUserId(String? newUserId) async {
    _currentUserId = newUserId;
    if (newUserId != null) {
      await _registerFcmToken();
    }
  }

  Future<void> clearFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (_currentUserId != null && token != null) {
        await supabase.SupabaseClient.from('user_devices')
            .delete()
            .eq('user_id', _currentUserId!)
            .eq('fcm_token', token);
        Get.log('âœ… [FCM] Token eliminado de la DB');
      }
    } catch (e) {
      Get.log('âŒ [FCM] Error al limpiar token: $e');
    }
  }

  void _listenForTokenRefresh() {
    _fcm.onTokenRefresh.listen((newToken) async {
      Get.log('ðŸ”„ [FCM] Token refrescado, registrando...');
      await _registerFcmToken();
    });
  }

  /// âœ… MÃ©todo pÃºblico que redirige a sendLoQuieroNotification (compatibilidad)
  Future<void> enviarNotificacionLoQuiero({
    required String sellerId,
    required String reelId,
    required String buyerName,
    required String itemTitle,
  }) async {
    await sendLoQuieroNotification(
      sellerId: sellerId,
      reelId: reelId,
      buyerName: buyerName,
      itemTitle: itemTitle,
    );
  }

  Future<void> sendLoQuieroNotification({
    required String sellerId,
    required String reelId,
    required String buyerName,
    required String itemTitle,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(
      id,
      'Â¡Nuevo Lo Quiero! â¤ï¸',
      '$buyerName estÃ¡ interesado en "$itemTitle"',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lo_quiero_channel',
          'Â¡Nuevo Lo Quiero!',
          importance: Importance.high,
        ),
      ),
      payload: jsonEncode({
        'type': 'nuevo_lo_quiero',
        'reel_id': reelId,
        'seller_id': sellerId,
        'buyer_name': buyerName,
      }),
    );
  }

  /// Limpiar badge (no disponible en firebase_messaging actual)
  /// Se comenta/elimina para evitar error
  // Future<void> clearBadge() async {
  //   await _fcm.setBadgeCount(0);
  // }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    Get.log('âœ… [FCM] Suscrito a tÃ³pico: $topic');
  }

  Future<void> subscribeToReel(String reelId) async {
    await _fcm.subscribeToTopic('reel_$reelId');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }
}
