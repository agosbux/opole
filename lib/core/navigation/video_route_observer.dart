// lib/core/navigation/video_route_observer.dart
// ===================================================================
// VIDEO ROUTE OBSERVER v1.1
// ===================================================================
// RouteObserver singleton que detecta automáticamente cuando una ruta
// se apila encima del feed (dialogs, bottom sheets, páginas) y pausa
// el video activo. Al volver, lo reanuda.
//
// COMPORTAMIENTO:
//   • didPushNext()  → cualquier ruta encima    → pauseAllVideos()
//   • didPopNext()   → volvió al feed           → resumeActiveVideo()
//   • didPush()      → el feed entró al stack   → no hace nada
//   • didPop()       → el feed salió del stack  → pauseAllVideos()
//
// INTEGRACIÓN — 3 pasos:
//
// PASO 1: Registrar en GetMaterialApp (main.dart o app_widget.dart):
//   import 'package:opole/core/navigation/video_route_observer.dart';
//
//   GetMaterialApp(
//     navigatorObservers: [VideoRouteObserver.instance],
//     ...
//   )
//
// PASO 2: Suscribir la View al observer (feed_view.dart e inmersive_reels_view.dart):
//   Convertir el widget a StatefulWidget si no lo es, luego:
//
//   class _FeedPageViewState extends State<_FeedPageView>
//       with RouteAware {                              // ← agregar mixin
//
//     @override
//     void didChangeDependencies() {
//       super.didChangeDependencies();
//       VideoRouteObserver.instance.subscribe(        // ← suscribir
//         this,
//         ModalRoute.of(context)!,
//       );
//     }
//
//     @override
//     void dispose() {
//       VideoRouteObserver.instance.unsubscribe(this); // ← desuscribir
//       super.dispose();
//     }
//
//     // ← Implementar los callbacks:
//     @override
//     void didPushNext() => VideoRouteObserver.onRouteAbove(widget.controller);
//
//     @override
//     void didPopNext()  => VideoRouteObserver.onRouteReturned(widget.controller);
//   }
//
// PASO 3 (opcional): Los dialogs y bottom sheets de GetX ya disparan
// los eventos automáticamente. Nada más que hacer en reel_card_widget.dart.
//
// NOTA SOBRE Get.dialog / Get.bottomSheet:
//   GetX usa Navigator internamente, por lo que el RouteObserver los
//   captura igual que cualquier push/pop nativo. No se requiere
//   modificar _showReportDialog() ni _showLoQuieroConfirmation().
// ===================================================================

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:opole/core/video/video_controller_pool.dart';
// ===================================================================
// INTERFAZ VIDEO PLAYBACK HANDLER
// ===================================================================
/// Interfaz genérica para handlers de reproducción de video.
/// Cualquier controlador que maneje video en el feed debe implementarla.
abstract class VideoPlaybackHandler {
  void pauseAllVideos();
  void resumeActiveVideo();
}

// ===================================================================
// VIDEO ROUTE OBSERVER — singleton
// ===================================================================

/// Observer de navegación que coordina pausa/reanudación de video
/// al apilarse rutas encima del feed (dialogs, sheets, páginas).
///
/// Es un [RouteObserver]<[ModalRoute]> porque tanto [PageRoute]
/// como [PopupRoute] (usado por dialogs y bottom sheets) son
/// subclases de [ModalRoute].
class VideoRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  VideoRouteObserver._();

  /// Singleton. Registrar UNA sola vez en [GetMaterialApp.navigatorObservers].
  static final VideoRouteObserver instance = VideoRouteObserver._();

  // ===================================================================
  // CALLBACKS ESTÁTICOS DE CONVENIENCIA
  // Llamados desde los mixins RouteAware de las views.
  // Obtienen el handler de video mediante Get.find<VideoPlaybackHandler>.
  // ===================================================================

  /// Llamar en [RouteAware.didPushNext] — algo se apila encima del feed.
  static void onRouteAbove([dynamic _]) {
    if (!Get.isRegistered<VideoPlaybackHandler>()) {
      // ✅ Fallback: pausar todo el pool directamente si el handler no está registrado
      if (kDebugMode) {
        Get.log('⚠️ [ROUTE_OBS] VideoPlaybackHandler no registrado - fallback a pool.pauseAll()');
      }
      try {
        VideoControllerPool.instance.pauseAll();
      } catch (_) {}
      return;
    }
    final handler = Get.find<VideoPlaybackHandler>();
    if (kDebugMode) {
      Get.log('🎬 [ROUTE_OBS] Ruta apilada encima del feed → pausando video');
    }
    handler.pauseAllVideos();
  }

  /// Llamar en [RouteAware.didPopNext] — volvimos al feed.
  static void onRouteReturned([dynamic _]) {
    if (!Get.isRegistered<VideoPlaybackHandler>()) {
      if (kDebugMode) {
        Get.log('⚠️ [ROUTE_OBS] VideoPlaybackHandler no registrado - no se puede reanudar');
      }
      return;
    }
    final handler = Get.find<VideoPlaybackHandler>();
    if (kDebugMode) {
      Get.log('▶️ [ROUTE_OBS] Volvimos al feed → reanudando video');
    }
    // Nota: la lógica de isUserPaused queda delegada al handler concreto
    handler.resumeActiveVideo();
  }

  // ===================================================================
  // OVERRIDE DE EVENTOS GLOBALES (opcional)
  // Si preferís no usar el mixin RouteAware en las views, podés
  // interceptar aquí globalmente. Descomentá y adaptá según necesites.
  //
  // ⚠️  ADVERTENCIA: Este enfoque intercepta TODAS las rutas de la app,
  // incluyendo rutas que no tienen nada que ver con el feed.
  // El mixin RouteAware en las views es más preciso y recomendado.
  // ===================================================================

  // @override
  // void didPush(Route route, Route? previousRoute) {
  //   super.didPush(route, previousRoute);
  //   _tryPauseFromRoute(previousRoute);
  // }

  // @override
  // void didPop(Route route, Route? previousRoute) {
  //   super.didPop(route, previousRoute);
  //   _tryResumeFromRoute(previousRoute);
  // }

  // void _tryPauseFromRoute(Route? route) {
  //   if (!Get.isRegistered<VideoPlaybackHandler>()) return;
  //   final handler = Get.find<VideoPlaybackHandler>();
  //   handler.pauseAllVideos();
  // }

  // void _tryResumeFromRoute(Route? route) {
  //   if (!Get.isRegistered<VideoPlaybackHandler>()) return;
  //   final handler = Get.find<VideoPlaybackHandler>();
  //   handler.resumeActiveVideo();
  // }
}

// ===================================================================
// MIXIN: VideoFeedRouteAware
// Mixin listo para pegar en cualquier State que necesite
// pausar/reanudar video al ser cubierto por otra ruta.
// ===================================================================

/// Mixin que implementa [RouteAware] con la lógica de pausa/reanudación.
///
/// Pegarlo en cualquier [State] que contenga un feed de video:
///
/// ```dart
/// class _FeedPageViewState extends State<_FeedPageView>
///     with VideoFeedRouteAware<_FeedPageView> {
///
///   @override
///   VideoPlaybackHandler get videoHandler => widget.controller;
/// }
/// ```
///
/// El mixin se encarga de suscribir/desuscribir al observer y de
/// implementar [didPushNext] / [didPopNext] automáticamente.
mixin VideoFeedRouteAware<T extends StatefulWidget>
    on State<T>
    implements RouteAware {
  /// Implementar en el State para proveer el handler de video correcto.
  VideoPlaybackHandler get videoHandler;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      VideoRouteObserver.instance.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    VideoRouteObserver.instance.unsubscribe(this);
    super.dispose();
  }

  // ---------------------------------------------------------------
  // RouteAware callbacks
  // ---------------------------------------------------------------

  /// Se apila una ruta encima → pausar video.
  @override
  void didPushNext() {
    VideoRouteObserver.onRouteAbove(videoHandler);
  }

  /// La ruta de encima desapareció → reanudar video.
  @override
  void didPopNext() {
    VideoRouteObserver.onRouteReturned(videoHandler);
  }

  /// Esta pantalla fue pusheada al stack — no necesitamos hacer nada.
  @override
  void didPush() {}

  /// Esta pantalla fue popeada del stack — pausar por seguridad.
  @override
  void didPop() {
    videoHandler.pauseAllVideos();
  }
}

// ===================================================================
// GUÍA DE INTEGRACIÓN COMPLETA
// ===================================================================
//
// ── main.dart / app_widget.dart ─────────────────────────────────────
//
//   import 'package:opole/core/navigation/video_route_observer.dart';
//
//   GetMaterialApp(
//     navigatorObservers: [
//       VideoRouteObserver.instance,   // ← única línea a agregar
//     ],
//     ...
//   );
//
// ── feed_view.dart → _FeedPageView ──────────────────────────────────
//
//   // Opción A: mixin automático (recomendado)
//   class _FeedPageViewState extends State<_FeedPageView>
//       with VideoFeedRouteAware<_FeedPageView> {
//
//     @override
//     VideoPlaybackHandler get videoHandler => widget.controller;
//
//     // ... resto del State sin cambios
//   }
//
//   // Opción B: manual (si ya tenés otros mixins conflictivos)
//   class _FeedPageViewState extends State<_FeedPageView>
//       with RouteAware {
//
//     @override
//     void didChangeDependencies() {
//       super.didChangeDependencies();
//       VideoRouteObserver.instance.subscribe(this, ModalRoute.of(context)!);
//     }
//
//     @override
//     void dispose() {
//       VideoRouteObserver.instance.unsubscribe(this);
//       super.dispose();
//     }
//
//     @override
//     void didPushNext() =>
//         VideoRouteObserver.onRouteAbove();
//
//     @override
//     void didPopNext() =>
//         VideoRouteObserver.onRouteReturned();
//   }
//
// ── inmersive_reels_view.dart → _InmersiveReelsViewState ────────────
//
//   // Mismo patrón. El videoHandler está disponible como campo o vía Get:
//   class _InmersiveReelsViewState extends State<InmersiveReelsView>
//       with VideoFeedRouteAware<InmersiveReelsView> {
//
//     @override
//     VideoPlaybackHandler get videoHandler =>
//         Get.find<VideoPlaybackHandler>(); // o el campo local
//
//     // ... resto sin cambios
//   }
//
// ── Casos que se manejan automáticamente ────────────────────────────
//
//   Get.dialog(...)         → didPushNext → pausa ✅
//   Get.bottomSheet(...)    → didPushNext → pausa ✅
//   Get.toNamed('/profile') → didPushNext → pausa ✅
//   Navigator.pop()         → didPopNext  → reanuda ✅
//   Get.back()              → didPopNext  → reanuda ✅
//
// ── Casos que NO maneja (intencional) ───────────────────────────────
//
//   Overlay widgets (tooltips, snackbars) — no son rutas del Navigator
//   Si necesitás pausar en esos casos, llamar manualmente a
//   videoHandler.pauseAllVideos() / resumeActiveVideo().
//
// ===================================================================