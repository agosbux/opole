// lib/main.dart
// ===================================================================
// MAIN v2.1 - OPOLE (Supabase First + Android 11 Compat)
// ===================================================================
// CAMBIOS vs v2.0:
//   ✅ _configureCloudinaryCompat() agregado para forzar f_jpg en Android
//      Elimina ImageDecoder$DecodeException en Android 11 (Moto G31)
//      al evitar formatos AVIF/WebP no soportados en SDK < 31.
//
//   ✅ VideoRouteObserver.instance agregado a navigatorObservers
//      del GetMaterialApp. Una sola línea — pausa automática de video
//      en dialogs, bottom sheets y navegación a otras páginas.
//
//   ✅ textScaleFactor reemplazado por textScaler (deprecation fix)
//      Flutter 3.x deprecó textScaleFactor en favor de TextScaler.
//      Evita el warning en consola sin cambiar el comportamiento.
//
//   ✅ debugPaintSizeEnabled y debugPaintBaselinesEnabled eliminados
//      (ya no se usan en modo debug).
// ===================================================================

import 'dart:async';
import 'dart:ui';
import 'dart:math' show min;
import 'dart:io';

import 'package:opole/pages/feed_page/controller/feed_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/rendering.dart';

import 'package:opole/core/services/supabase_client.dart' as supabase_wrapper;
import 'package:opole/core/services/notification_service.dart';
import 'package:opole/core/engagement/reel_engagement_service.dart';
import 'package:opole/core/services/auth_service.dart';
import 'package:opole/core/video/video_preload_manager.dart';
import 'package:opole/core/feed/opole_feed_engine.dart';
import 'package:opole/services/location_service.dart';
import 'package:opole/utils/internet_connection.dart';
import 'package:opole/utils/utils.dart';

// 🔥 FIX: Import para configuración de compatibilidad Cloudinary
import 'package:opole/core/utils/cloudinary_url_normalizer.dart';

import 'package:opole/localization/locale_constant.dart';
import 'package:opole/routes/app_pages.dart';
import 'package:opole/routes/app_routes.dart';

import 'package:opole/controllers/session_controller.dart';

// ✅ NUEVO: VideoRouteObserver para pausa automática en modales
import 'package:opole/core/navigation/video_route_observer.dart';

// ===================================================================
// ENTRY POINT
// ===================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      print('❌ [PROD ERROR] ${details.exception}');
    }
  };

  if (kDebugMode) print('🚀🚀🚀 MAIN - Iniciando Opole (Supabase First)... 🚀🚀🚀');

  try {
    if (kDebugMode) print('🔧 [0/9] Cargando variables de entorno (.env)...');
    await dotenv.load(fileName: ".env");

    if (kDebugMode) {
      final url = dotenv.env['SUPABASE_URL'] ?? 'NO DEFINIDA';
      final safeUrl = url.length > 30 ? '${url.substring(0, 30)}...' : url;
      print('✅ .env cargado: SUPABASE_URL = $safeUrl');
      print('✅ SUPABASE_ANON_KEY presente: ${dotenv.env['SUPABASE_ANON_KEY'] != null ? "✅ Sí" : "❌ No"}');
    }

    // 🔥 FIX: Configurar compatibilidad Cloudinary para Android 11
    await _configureCloudinaryCompat();

    await _initializeApp().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('Initialization timeout after 30 seconds'),
    );

    if (kDebugMode) print('✅✅✅ MAIN - Todos los servicios inicializados correctamente');

    Get.put(SessionController(), permanent: true);
    if (kDebugMode) print('✅ SessionController registrado permanentemente');

    if (kDebugMode && Platform.isAndroid) {
      HttpOverrides.global = _MyHttpOverrides();
      if (kDebugMode) print('🔓 [DEBUG] Bypass SSL activado para Android (NO USAR EN PRODUCCIÓN)');
    }

    runApp(const MyApp());

  } catch (e, stack) {
    if (kDebugMode) {
      print('❌❌❌ MAIN - ERROR CRÍTICO EN main(): $e');
      print('Stack trace: $stack');
    }
    runApp(ErrorApp(error: e.toString()));
  }
}

// ===================================================================
// 🔥 FIX: Configuración de compatibilidad Cloudinary para Android 11
// ===================================================================
/// Configura CloudinaryUrlNormalizer para forzar f_jpg en dispositivos Android.
/// Esto previene ImageDecoder$DecodeException en Android 11 (SDK 30) que
/// no soporta completamente AVIF/WebP con ciertas transformaciones.
/// 
/// En el futuro, podés refinar esto con device_info_plus para aplicar
/// solo en SDK < 31, pero por ahora usamos enfoque conservador.
Future<void> _configureCloudinaryCompat() async {
  if (!Platform.isAndroid) return;
  
  // Enfoque conservador: forzar JPG para todos los Android
  // Esto garantiza compatibilidad universal sin dependencias extras.
  CloudinaryUrlNormalizer.forceJpgForOldAndroid = true;
  
  if (kDebugMode) {
    print('🛡️ [CLOUDINARY] Compat mode: forceJpgForOldAndroid = true (Android)');
  }
  
  // 🔮 FUTURO: Si querés precisión por SDK, descomentá esto:
  // import 'package:device_info_plus/device_info_plus.dart';
  // final deviceInfo = await DeviceInfoPlugin().androidInfo;
  // if (deviceInfo.version.sdkInt < 31) { // Android 12 = SDK 31
  //   CloudinaryUrlNormalizer.forceJpgForOldAndroid = true;
  //   print('🛡️ [CLOUDINARY] SDK ${deviceInfo.version.sdkInt} < 31 → forcing f_jpg');
  // }
}

// ===================================================================
// INICIALIZACIÓN SECUENCIAL DE SERVICIOS — sin cambios
// ===================================================================
Future<void> _initializeApp() async {
  if (kDebugMode) print('🔧 [1/9] Inicializando GetStorage...');
  await GetStorage.init();
  if (kDebugMode) print('✅ GetStorage inicializado');

  if (kDebugMode) print('🔧 [1.5/9] Configurando GetX logging...');
  Get.config(
    enableLog: kDebugMode,
    logWriterCallback: kDebugMode
        ? (String text, {bool? isError}) => print('[GETX] $text')
        : null,
  );
  if (kDebugMode) print('✅ GetX logging configurado');

  if (kDebugMode) print('🔧 [2/9] Verificando conexión a internet...');
  final hasConnection = await InternetConnection.isConnected;
  if (kDebugMode) print('✅ Conexión a internet: ${hasConnection ? "Sí" : "No"}');

  if (kDebugMode) print('🔧 [3/9] Inicializando Firebase Core...');
  try {
    await Firebase.initializeApp();
    if (kDebugMode) print('✅ Firebase Core inicializado');
  } catch (e) {
    if (kDebugMode) print('⚠️ Advertencia Firebase Core (no crítico): $e');
  }

  if (kDebugMode) print('🔧 [4/9] Inicializando Supabase...');
  try {
    await supabase_wrapper.SupabaseClient.initialize();
    if (kDebugMode) print('✅ Supabase inicializado correctamente');
  } catch (e, stack) {
    if (kDebugMode) {
      print('❌❌❌ ERROR FATAL Supabase.initialize: $e');
      print('Stack: $stack');
    }
    rethrow;
  }

  if (kDebugMode) print('🔧 [5/9] Configurando Firebase Messaging (FCM)...');
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    String? fcmToken = await messaging.getToken();
    if (kDebugMode && fcmToken != null) {
      print('📲 FCM Token: ${fcmToken.substring(0, min(20, fcmToken.length))}...');
    }
    _setupFirebaseMessagingHandlers(messaging);
    if (kDebugMode) print('✅ Firebase Messaging configurado');
  } catch (e) {
    if (kDebugMode) print('⚠️ Advertencia Firebase Messaging (no crítico): $e');
  }

  if (kDebugMode) print('🔧 [6/9] Inicializando NotificationService...');
  try {
    Get.put(NotificationService(), permanent: true);
    if (kDebugMode) print('✅ NotificationService inicializado correctamente');
  } catch (e) {
    if (kDebugMode) print('⚠️ Error en NotificationService, usando fallback: $e');
    Get.put(NotificationServiceDummy(), permanent: true);
  }

  if (kDebugMode) print('🔧 [7/9] Registrando ReelEngagementService...');
  try {
    Get.put(ReelEngagementService(), permanent: true);
    if (kDebugMode) print('✅ ReelEngagementService registrado correctamente');
  } catch (e) {
    if (kDebugMode) print('⚠️ Advertencia registrando ReelEngagementService: $e');
  }

  if (kDebugMode) print('🔧 [8/9] Registrando AuthService en GetX...');
  try {
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(AuthService(), permanent: true);
      if (kDebugMode) print('✅ AuthService registrado en GetX');
    } else {
      if (kDebugMode) print('⚠️ AuthService ya estaba registrado en GetX');
    }
  } catch (e) {
    if (kDebugMode) print('❌ Error registrando AuthService: $e');
  }

  if (kDebugMode) print('🔧 [9/9] Cargando ubicaciones + warmup de video...');
  try {
    await LocationService().loadLocations();
    if (kDebugMode) print('✅ Ubicaciones cargadas en memoria');
    await VideoPreloadManager.instance.init();
    if (kDebugMode) print('✅ VideoPreloadManager warmup completado');
    OpoleFeedEngine.instance;
    if (kDebugMode) print('✅ OpoleFeedEngine inicializado');
  } catch (e) {
    if (kDebugMode) print('⚠️ Advertencia en paso final: $e');
  }

  if (kDebugMode) {
    print('\n🔍 === VERIFICACIÓN FINAL DE INICIALIZACIÓN ===');
    print('📊 Supabase.isInitialized: ${supabase_wrapper.SupabaseClient.isInitialized}');
    print('📊 Supabase.isLoggedIn: ${supabase_wrapper.SupabaseClient.isLoggedIn}');
    print('📊 Supabase.currentUserId: ${supabase_wrapper.SupabaseClient.currentUserId ?? "null"}');
    print('📊 SessionController.registered: ${Get.isRegistered<SessionController>()}');
    print('📊 AuthService.registered: ${Get.isRegistered<AuthService>()}');
    print('📊 ReelEngagementService.registered: ${Get.isRegistered<ReelEngagementService>()}');
    print('🎉 === TODAS LAS INICIALIZACIONES COMPLETADAS ===\n');
  }
}

// ===================================================================
// HANDLERS DE FIREBASE MESSAGING — sin cambios
// ===================================================================
void _setupFirebaseMessagingHandlers(FirebaseMessaging messaging) {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (kDebugMode) print('🔔 [FCM] onMessage: ${message.notification?.title}');
    if (message.notification != null) {
      Get.find<NotificationService>().mostrarNotificacionLocal(
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
        payload: message.data,
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (kDebugMode) print('🔔 [FCM] onMessageOpenedApp: ${message.data}');
    _handleNotificationNavigation(message.data);
  });

  messaging.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      if (kDebugMode) print('🔔 [FCM] getInitialMessage: ${message.data}');
      _handleNotificationNavigation(message.data);
    }
  });
}

void _handleNotificationNavigation(Map<String, dynamic> data) {
  final type = data['type'] as String?;
  final reelId = data['reel_id'] as String?;
  final userId = data['user_id'] as String?;

  switch (type) {
    case 'nuevo_lo_quiero':
    case 'nuevo_comentario':
    case 'nuevo_like':
      if (userId != null) {
        Get.toNamed(AppRoutes.previewUserProfilePage, arguments: {'userId': userId});
      }
      break;
    case 'reel_destacado':
    case 'reel_nuevo':
      if (reelId != null) {
        Get.toNamed(AppRoutes.reelsInmersivePage, arguments: {'reelId': reelId});
      }
      break;
    default:
      if (supabase_wrapper.SupabaseClient.isLoggedIn) {
        Get.toNamed(AppRoutes.bottomBarPage);
      }
      break;
  }
}

// ===================================================================
// NOTIFICATION SERVICE DUMMY — sin cambios
// ===================================================================
class NotificationServiceDummy extends GetxService {
  Future<void> enviarNotificacionLoQuiero({
    required String sellerId,
    required String reelId,
    required String buyerName,
    required String itemTitle,
  }) async {
    if (kDebugMode) print('🔔 [DUMMY] Notificación Lo Quiero: $buyerName → $sellerId (reel: $reelId)');
  }

  Future<void> mostrarNotificacionLocal({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    if (kDebugMode) print('🔔 [DUMMY] Notificación local: $title - $body');
  }
}

// ===================================================================
// APP WIDGET PRINCIPAL
// ===================================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale? _locale;
  bool _isLoading = true;
  String? _error;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    // ✅ DEBUG PAINT ELIMINADO (ya no se usa)

    if (kDebugMode) print('📱 _MyAppState.initState() llamado');
    WidgetsBinding.instance.addObserver(this);

    if (defaultTargetPlatform == TargetPlatform.android) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ));
      if (kDebugMode) print('📱 Android: orientación + UI configurados');
    }

    try {
      GetStorage();
      if (kDebugMode) print('📊 GetStorage inicializado correctamente');
    } catch (e) {
      if (kDebugMode) print('⚠️ Error leyendo GetStorage: $e');
    }

    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final locale = await getLocale();
      if (mounted) {
        setState(() {
          _locale = locale;
          _isLoading = false;
          _initialized = true;
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error cargando locale: $e');
      if (mounted) {
        setState(() {
          _error = 'Error al cargar configuración regional: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (kDebugMode) print('📱 AppLifecycleState: $state');
    if (state == AppLifecycleState.paused) {
      if (Get.isRegistered<FeedController>()) {
        Get.find<FeedController>().pauseAllVideos();
      }
    } else if (state == AppLifecycleState.resumed) {
      // No auto-resume — el usuario debe interactuar
    }
  }

  @override
  void dispose() {
    if (kDebugMode) print('🔴 _MyAppState.dispose() llamado');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 3)),
                SizedBox(height: 20),
                Text('Iniciando Opole...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                SizedBox(height: 10),
                Text('Conectando con servidores...', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 24),
                    const Text('Error de Configuración', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        setState(() { _error = null; _isLoading = true; });
                        _loadLocale();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_initialized) {
      Timer(const Duration(seconds: 10), () {
        if (Get.currentRoute == AppRoutes.splashScreenPage) {
          if (kDebugMode) print('⚠️ [TIMEOUT] App atascada en splash >10s, forzando navegación...');
          Get.offAllNamed(AppRoutes.loginPage);
        }
      });
    }

    return GetMaterialApp(
      title: 'Opole',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      fallbackLocale: const Locale('es', 'AR'),
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 250),
      getPages: AppPages.list,
      initialRoute: AppRoutes.initial,

      // ✅ NUEVO: VideoRouteObserver para pausa automática de video
      // en cualquier dialog, bottom sheet o navegación push.
      // No requiere ningún otro cambio — el observer captura todos
      // los eventos del Navigator de GetX automáticamente.
      navigatorObservers: [
        VideoRouteObserver.instance,
      ],

      onInit: () {
        if (kDebugMode) print('🎯 GetMaterialApp.onInit() - Ruta: ${Get.currentRoute}');
      },
      onReady: () {
        if (kDebugMode) print('✅✅✅ GetMaterialApp.onReady() ✅✅✅');
        final initialRouteExists = AppPages.list.any((page) => page.name == AppRoutes.initial);
        if (!initialRouteExists && kDebugMode) {
          print('❌ ERROR CRÍTICO: Ruta inicial "${AppRoutes.initial}" NO está en AppPages.list');
        }
      },
      routingCallback: (routing) {
        if (routing != null && kDebugMode) {
          print('🔄 [ROUTING] ${routing.previous} → ${routing.current}');
        }
      },
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.heart_broken, size: 64, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('Página no encontrada', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Ruta: ${Get.currentRoute}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Get.offAllNamed(AppRoutes.bottomBarPage),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                    child: const Text('Ir al inicio'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ✅ textScaler reemplaza textScaleFactor (deprecado en Flutter 3.x)
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }
}

// ===================================================================
// APP DE ERROR — sin cambios
// ===================================================================
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) print('🆘 Mostrando ErrorApp: $error');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 72, color: Colors.redAccent),
                const SizedBox(height: 24),
                const Text('Error de Inicialización', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Detalles del error:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Text(error, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 24),
                          const Text('Posibles soluciones:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          _buildSolutionItem('1. Verifica tu conexión a internet'),
                          _buildSolutionItem('2. Reinicia la aplicación completamente'),
                          _buildSolutionItem('3. Verifica que el archivo .env esté configurado'),
                          _buildSolutionItem('4. Confirma que las credenciales de Supabase sean válidas'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () { if (kDebugMode) print('🔄 Reiniciando aplicación...'); },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      child: const Text('Reiniciar'),
                    ),
                    ElevatedButton(
                      onPressed: () { if (kDebugMode) print('📱 Cerrando aplicación...'); },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolutionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        ],
      ),
    );
  }
}

// ===================================================================
// BYPASS SSL PARA DEBUG — sin cambios
// ===================================================================
class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (kDebugMode) {
          print('🔓 [SSL BYPASS] Aceptando certificado para: $host:$port');
          return true;
        }
        return false;
      };
  }
}