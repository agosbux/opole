// lib/core/video/cdn/cloudinary_cdn_provider.dart
// ===================================================================
// CLOUDINARY CDN PROVIDER — Implementación concreta
// ===================================================================
// ✅ Toda la lógica de Cloudinary encapsulada aquí
// ✅ Para migrar: crear nueva implementación de VideoCdnProvider
// ===================================================================

import 'package:opole/core/video/cdn/video_cdn_provider.dart';

class CloudinaryCdnProvider implements VideoCdnProvider {
  const CloudinaryCdnProvider();

  static const String _defaultVideoParams = 'f_auto,q_auto:good,vc_auto';
  static const String _lowBandwidthParams = 'f_mp4,q_auto:eco,vc_h264,br_800k';
  static const String _thumbnailParams = 'f_jpg,q_auto:good,w_400,h_700,c_fill,so_0';
  static const String _lowQualityParams = 'f_mp4,q_auto:low,w_720,vc_h264';

  @override
  String get providerName => 'Cloudinary';

  @override
  bool owns(String url) =>
      url.contains('cloudinary.com') || url.contains('res.cloudinary');

  @override
  String normalizeUrl(String url, {bool isVideo = true}) {
    if (!owns(url)) return url;
    // Asegurar HTTPS
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  String optimizeVideoUrl(String url, {bool lowBandwidth = false}) {
    if (!owns(url)) return url;
    if (_hasTransformParams(url)) return url;
    final params = lowBandwidth ? _lowBandwidthParams : _defaultVideoParams;
    return _injectParams(url, params);
  }

  @override
  String getThumbnailUrl(String videoUrl) {
    if (!owns(videoUrl)) return videoUrl;
    final withoutExt = videoUrl.replaceAll(RegExp(r'\.(mp4|webm|mov)(\?.*)?$'), '');
    return _injectParams(withoutExt, _thumbnailParams)
        .replaceFirst('/video/', '/image/');
  }

  @override
  String downgradeQuality(String url) {
    if (!owns(url)) return url;
    return _injectParams(url, _lowQualityParams);
  }

  bool _hasTransformParams(String url) =>
      RegExp(r'/upload/[^/]+,[^/]+/').hasMatch(url);

  String _injectParams(String url, String params) =>
      url.replaceFirstMapped(
        RegExp(r'(/upload/)'),
        (match) => '${match.group(1)}$params/',
      );
}