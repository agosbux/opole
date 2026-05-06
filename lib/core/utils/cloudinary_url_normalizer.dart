// 📍 lib/core/utils/cloudinary_url_normalizer.dart
// ===================================================================
// CLOUDINARY URL NORMALIZER - v4.1 (ANDROID 11 COMPAT)
// ===================================================================
// ✅ FIX: Flag global forceJpgForOldAndroid para compatibilidad Android < 12
// ✅ Mantiene: Zero breaking changes, single responsibility, CDN cache safe
// ===================================================================

class CloudinaryUrlNormalizer {
  CloudinaryUrlNormalizer._();

  // 🔥 FIX: Flag global para forzar JPG en dispositivos Android antiguos
  // Configurar en main.dart: si SDK < 31, establecer en true
  static bool forceJpgForOldAndroid = false;

  /// Normaliza una URL de Cloudinary sin romper transformaciones existentes
  static String normalize(
    String url, {
    bool isVideo = true,
    List<String>? transformations,
  }) {
    if (!_isCloudinaryUrl(url)) return url;

    try {
      final uri = Uri.parse(url);
      final path = uri.path;

      final isVideoAsset = path.contains('/video/upload/');
      final assetType = isVideoAsset ? 'video' : 'image';

      // ⚠️ Si ya tiene transformaciones → NO tocar (clave para CDN cache)
      if (_hasTransformParams(path)) {
        return url;
      }

      // Si no hay transforms y no se pasan → usar defaults mínimos
      final transforms = (transformations != null && transformations.isNotEmpty)
          ? transformations
          : _defaultTransforms(isVideo);

      return _injectParams(uri, assetType, transforms);

    } catch (_) {
      // fallback seguro
      return url;
    }
  }

  /// Thumbnail liviano para placeholder (ultra rápido)
  static String thumbnail(String url) {
    return normalize(
      url,
      isVideo: false,
      transformations: [
        'f_auto',
        'q_auto:low',
        'w_240',
        'h_420',
        'c_fill',
        'so_0',
      ],
    );
  }

  /// Video optimizado para mobile/feed
  static String video(String url) {
    return normalize(
      url,
      isVideo: true,
      transformations: [
        'f_auto',
        'q_auto:eco',
        'w_720',
        'vc_auto',
        'br_800k',
      ],
    );
  }

  // ===================================================================
  // INTERNALS
  // ===================================================================

  static bool _isCloudinaryUrl(String url) {
    return url.contains('res.cloudinary.com') ||
        url.contains('cloudinary.com');
  }

  /// Detecta si ya hay transformaciones después de /upload/
  static bool _hasTransformParams(String path) {
    final parts = path.split('/upload/');
    if (parts.length < 2) return false;

    final firstSegment = parts[1].split('/').first;

    // Si contiene "_" o ":" → muy probablemente es transformación
    return firstSegment.contains('_') || firstSegment.contains(':');
  }

  static List<String> _defaultTransforms(bool isVideo) {
    // 🔥 FIX: Forzar JPG para imágenes en Android < 12 si el flag está activo
    if (!isVideo && forceJpgForOldAndroid) {
      return [
        'f_jpg',           // ← Forzar formato compatible
        'q_auto:low',
        'w_240',
      ];
    }
    
    if (isVideo) {
      return [
        'f_auto',
        'q_auto:eco',
        'w_720',
        'vc_auto',
      ];
    } else {
      return [
        'f_auto',
        'q_auto:low',
        'w_240',
      ];
    }
  }

  static String _injectParams(
    Uri uri,
    String assetType,
    List<String> transforms,
  ) {
    final transformString = transforms.join(',');

    final newPath = uri.path.replaceFirst(
      '/$assetType/upload/',
      '/$assetType/upload/$transformString/',
    );

    return uri.replace(path: newPath).toString();
  }
}