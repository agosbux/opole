// lib/core/feed/feed_config.dart
// ✅ Centraliza límites y umbrales (listo para inyección por ConnectivityService en Fase 4)

class FeedConfig {
  FeedConfig._();

  /// Tamaño de página para fetch
  static int get pageSize => 15;

  /// Límite máximo de items en memoria antes de trim
  static const int maxMemoryItems = 60;

  /// Cantidad de items a eliminar al hacer trim
  static const int trimCount = 20;

  /// Umbral para disparar paginación automática
  static const int preloadTriggerThreshold = 3;
}