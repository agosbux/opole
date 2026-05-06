// lib/core/video/cdn/video_cdn_provider.dart
// ===================================================================
// VIDEO CDN PROVIDER — Interfaz abstracta de proveedor de video
// ===================================================================
// ✅ Desacopla completamente el proveedor del resto de la app
// ✅ Para cambiar de CDN: solo cambiar qué implementación se registra
// ✅ Sin tocar VideoControllerPool, VideoCacheManager, ni feeds
// ===================================================================

abstract class VideoCdnProvider {
  /// URL optimizada para reproducción según conectividad.
  /// [lowBandwidth]: true si la conexión es 4G o inferior.
  String optimizeVideoUrl(String url, {bool lowBandwidth = false});

  /// URL del thumbnail del primer frame.
  /// Usar como placeholder mientras el video carga.
  String getThumbnailUrl(String videoUrl);

  /// URL degradada para dispositivos de gama baja.
  String downgradeQuality(String url);

  /// Normaliza la URL al formato canónico del proveedor.
  /// Ej: convierte URLs cortas o con parámetros extra al formato estándar.
  String normalizeUrl(String url, {bool isVideo = true});

  /// Nombre del proveedor actual (para logs y analytics).
  String get providerName;

  /// True si esta URL pertenece a este proveedor.
  bool owns(String url);
}