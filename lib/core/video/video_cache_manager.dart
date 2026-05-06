// lib/core/video/video_cache_manager.dart
// ===================================================================
// VIDEO CACHE MANAGER v3.0 - PARTIAL PRELOAD + FULL CACHE
// ===================================================================
// ✅ Cache persistente en disco (getTemporaryDirectory)
// ✅ LRU eviction por tamaño (800MB) y edad (48h)
// ✅ Deduplicación de descargas (Completer)
// ✅ 🆕 v3.0: Partial download — primeros 800KB para inicio instantáneo
// ✅ 🆕 v3.0: Full download en background después del partial
// ✅ 🆕 v3.0: getLocalUri retorna partial si full no está listo
// ✅ 🧹 CORREGIDO: Eliminado _rebuildFullyDownloadedSet() (bug de paths vs URLs)
// ✅ 🔥 FIX CRÍTICO #1: Stream a disco (sin acumular en RAM)
// ✅ 🔥 FIX CRÍTICO #2: _partialBytes = 800KB (moov atom + bitrate alto)
// ✅ 🔥 FIX CRÍTICO #3: Validación de corrupción (800KB <= size < 5MB)
// ✅ 🔥 FIX OPCIONAL #4: Persistencia de _fullyDownloaded en index.json
// ✅ 🔥 FIX CRÍTICO #5: Cleanup con delay para no competir con startup
// ✅ 🚀 MEJORA PRO: Throttle de background downloads (_fullyDownloaded < 20)
// ===================================================================

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class VideoCacheManager {
  VideoCacheManager._internal();
  static final VideoCacheManager instance = VideoCacheManager._internal();

  late Directory _cacheDir;
  bool _initialized = false;

  final int maxCacheSizeBytes = 800 * 1024 * 1024; // 800MB
  final int maxFileAgeHours = 48;

  // 🔥 FIX #2: 800KB para cubrir moov atom al final + bitrate alto
  static const int _partialBytes = 800 * 1024; // 800KB
  static const int _maxPartialSize = 5 * 1024 * 1024; // 5MB (límite superior para validar)

  final Map<String, Completer<File?>> _ongoingDownloads = {};
  final Map<String, Completer<File?>> _ongoingPartials = {};

  // Set de URLs que ya tienen descarga completa (cache en memoria por sesión)
  final Set<String> _fullyDownloaded = {};

  // 🔥 FIX #4: Archivo para persistir _fullyDownloaded
  File get _indexFile => File('${_cacheDir.path}/index.json');

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getTemporaryDirectory();
    _cacheDir = Directory('${dir.path}/video_cache');
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    _initialized = true;
    
    // 🔥 FIX #4: Reconstruir _fullyDownloaded desde index.json
    await _loadFullyDownloadedIndex();
    
    // 🔥 FIX #5: Delay para que cleanup no compita con startup
    unawaited(Future.delayed(const Duration(seconds: 5), _cleanup));
  }

  // 🔥 FIX #4: Cargar índice persistente al iniciar
  Future<void> _loadFullyDownloadedIndex() async {
    try {
      if (await _indexFile.exists()) {
        final content = await _indexFile.readAsString();
        final List<dynamic> urls = jsonDecode(content);
        _fullyDownloaded.addAll(urls.cast<String>());
        if (kDebugMode) print('📦 [CACHE] Índice cargado: ${_fullyDownloaded.length} URLs');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [CACHE] Error cargando índice: $e');
    }
  }

  // 🔥 FIX #4: Guardar índice persistente cuando se completa una descarga
  Future<void> _saveFullyDownloadedIndex() async {
    try {
      final content = jsonEncode(_fullyDownloaded.toList());
      await _indexFile.writeAsString(content, flush: true);
    } catch (e) {
      if (kDebugMode) print('⚠️ [CACHE] Error guardando índice: $e');
    }
  }

  String _getFileName(String url) {
    final bytes = utf8.encode(url);
    return '${md5.convert(bytes)}.mp4';
  }

  String _getPartialFileName(String url) {
    final bytes = utf8.encode(url);
    return '${md5.convert(bytes)}.partial';
  }

  File _getFile(String url) => File('${_cacheDir.path}/${_getFileName(url)}');
  File _getPartialFile(String url) => File('${_cacheDir.path}/${_getPartialFileName(url)}');

  /// Retorna URI local si hay archivo (completo o partial).
  /// Prioriza el completo, pero acepta el partial si es suficientemente grande.
  Future<Uri?> getLocalUri(String url) async {
    if (!_initialized) await init();

    // 1. Archivo completo — mejor opción
    final fullFile = _getFile(url);
    if (await fullFile.exists()) {
      _touch(fullFile);
      if (kDebugMode) print('💾 [CACHE] FULL HIT: ${_shorten(url)}');
      return fullFile.uri;
    }

    // 2. Archivo partial — sirve para inicializar el player
    final partialFile = _getPartialFile(url);
    if (await partialFile.exists()) {
      final size = await partialFile.length();
      // 🔥 FIX #3: Validar rango de tamaño para evitar corrupción
      if (size >= _partialBytes && size < _maxPartialSize) {
        _touch(partialFile);
        if (kDebugMode) print('💾 [CACHE] PARTIAL HIT (${(size/1024).toStringAsFixed(0)}KB): ${_shorten(url)}');
        // 🚀 MEJORA PRO: Throttle para no saturar red
        if (!_ongoingDownloads.containsKey(url) && _fullyDownloaded.length < 20) {
          unawaited(downloadAndCache(url));
        }
        return partialFile.uri;
      }
    }

    return null;
  }

  /// Descarga los primeros _partialBytes para inicio instantáneo.
  /// Retorna el archivo partial o null si falla.
  Future<File?> downloadPartial(String url) async {
    if (!_initialized) await init();

    // Si ya existe completo, no necesitamos partial
    final fullFile = _getFile(url);
    if (await fullFile.exists()) return fullFile;

    final partialFile = _getPartialFile(url);
    if (await partialFile.exists()) {
      final size = await partialFile.length();
      if (size >= _partialBytes && size < _maxPartialSize) return partialFile;
    }

    // Deduplicar descargas partial en vuelo
    if (_ongoingPartials.containsKey(url)) {
      return _ongoingPartials[url]!.future;
    }

    final completer = Completer<File?>();
    _ongoingPartials[url] = completer;

    try {
      final result = await _downloadPartial(url, partialFile);
      completer.complete(result);
      return result;
    } catch (e) {
      if (kDebugMode) print('❌ [CACHE] Partial failed: ${_shorten(url)}: $e');
      completer.complete(null);
      return null;
    } finally {
      _ongoingPartials.remove(url);
    }
  }

  // 🔥 FIX #1: Stream a disco para partial (sin acumular en RAM)
  Future<File?> _downloadPartial(String url, File partialFile) async {
    final client = HttpClient();
    IOSink? sink;
    try {
      final request = await client.getUrl(Uri.parse(url));
      // Solicitar solo los primeros _partialBytes
      request.headers.add('Range', 'bytes=0-${_partialBytes - 1}');
      final response = await request.close();

      // 206 Partial Content o 200 OK ambos son válidos
      if (response.statusCode != 206 && response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      sink = partialFile.openWrite();
      int received = 0;

      await for (final chunk in response) {
        if (received < _partialBytes) {
          final remaining = _partialBytes - received;
          final slice = chunk.length > remaining ? chunk.sublist(0, remaining) : chunk;
          sink.add(slice);
          received += slice.length;
        } else {
          break;
        }
      }

      await sink.close();
      sink = null;

      if (kDebugMode) {
        print('⬇️ [CACHE] Partial ${(received / 1024).toStringAsFixed(0)}KB: ${_shorten(url)}');
      }
      return partialFile;
    } catch (e) {
      await sink?.close();
      rethrow;
    } finally {
      if (sink != null) await sink.close();
      client.close(force: true);
    }
  }

  /// Descarga completa. Al terminar, elimina el partial si existe.
  Future<File?> downloadAndCache(String url) async {
    if (!_initialized) await init();

    final fullFile = _getFile(url);
    if (await fullFile.exists()) {
      _touch(fullFile);
      _fullyDownloaded.add(url);
      await _saveFullyDownloadedIndex(); // 🔥 FIX #4
      return fullFile;
    }

    if (_ongoingDownloads.containsKey(url)) {
      return _ongoingDownloads[url]!.future;
    }

    final completer = Completer<File?>();
    _ongoingDownloads[url] = completer;

    try {
      final result = await _downloadFull(url, fullFile);
      completer.complete(result);
      return result;
    } catch (e) {
      if (kDebugMode) print('❌ [CACHE] Full download failed: ${_shorten(url)}: $e');
      completer.complete(null);
      return null;
    } finally {
      _ongoingDownloads.remove(url);
    }
  }

  // 🔥 FIX #1: Stream a disco para full (sin acumular en RAM)
  Future<File?> _downloadFull(String url, File fullFile) async {
    final client = HttpClient();
    IOSink? sink;
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      // Escritura atómica con stream
      final tempFile = File('${fullFile.path}.tmp');
      sink = tempFile.openWrite();
      
      await response.forEach(sink.add);
      
      await sink.close();
      sink = null;
      
      await tempFile.rename(fullFile.path);

      _fullyDownloaded.add(url);
      await _saveFullyDownloadedIndex(); // 🔥 FIX #4

      // Limpiar partial si existe
      final partialFile = _getPartialFile(url);
      if (await partialFile.exists()) {
        await partialFile.delete();
        if (kDebugMode) print('🧹 [CACHE] Partial eliminado tras full: ${_shorten(url)}');
      }

      if (kDebugMode) {
        final size = await fullFile.length();
        print('⬇️ [CACHE] Full ${(size / 1024).toStringAsFixed(0)}KB: ${_shorten(url)}');
      }
      return fullFile;
    } catch (e) {
      sink?.close();
      rethrow;
    } finally {
      if (sink != null) await sink.close();
      client.close(force: true);
    }
  }

  /// ✅ Retorna true si la URL está marcada como completa en esta sesión.
  /// Nota: tras restart de la app, se reconstruye desde index.json (FIX #4).
  bool isFullyCached(String url) => _fullyDownloaded.contains(url);
  
  bool isDownloading(String url) => _ongoingDownloads.containsKey(url);
  bool isPartialDownloading(String url) => _ongoingPartials.containsKey(url);

  void _touch(File file) {
    try { file.setLastModifiedSync(DateTime.now()); } catch (_) {}
  }

  Future<void> _cleanup() async {
    try {
      final files = _cacheDir.listSync().whereType<File>().toList();
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      final sizes = <File, int>{};
      int totalSize = 0;
      for (final f in files) {
        try {
          final s = await f.length();
          sizes[f] = s;
          totalSize += s;
        } catch (_) {}
      }

      for (final file in files) {
        if (totalSize <= maxCacheSizeBytes) break;
        final size = sizes[file] ?? 0;
        try {
          await file.delete();
          totalSize -= size;
        } catch (_) {}
      }

      final now = DateTime.now();
      for (final file in files) {
        if (!await file.exists()) continue;
        try {
          final age = now.difference(file.lastModifiedSync()).inHours;
          if (age > maxFileAgeHours) await file.delete();
        } catch (_) {}
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ [CACHE] Cleanup error: $e');
    }
  }

  Future<void> forceCleanup() => _cleanup();

  String _shorten(String url) =>
      url.length > 50 ? '${url.substring(0, 50)}...' : url;
}