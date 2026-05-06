// ===================================================================
// CLOUDINARY SERVICE - Upload optimizado de imÃ¡genes y videos
// â€¢ Singleton con cliente HTTP reutilizable
// â€¢ ValidaciÃ³n de configuraciÃ³n al iniciar
// â€¢ Upload con progreso, timeout y transformaciones automÃ¡ticas
// â€¢ Manejo centralizado de errores y respuestas JSON
// â€¢ URLs optimizadas para CDN mÃ³vil (calidad/velocidad)
// â€¢ âœ… CORREGIDO: AppConstants.maxImageSizeBytes (typo fix)
// â€¢ âœ… FIX http package: Response.bytes sin isStreaming
// ===================================================================

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class CloudinaryService {
  
  // âœ… Singleton para reutilizar cliente HTTP y conexiones
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();
  
  final _client = http.Client();
  bool _isInitialized = false;
  
  /// âœ… InicializaciÃ³n con validaciÃ³n de configuraciÃ³n
  Future<void> init() async {
    if (_isInitialized) return;
    
    // Validar que las variables crÃ­ticas estÃ©n configuradas
    if (AppConstants.cloudinaryCloudName.isEmpty) {
      throw StateError('â˜ï¸ Cloudinary cloud_name no configurado en AppConstants');
    }
    
    _isInitialized = true;
    print("â˜ï¸ Cloudinary Service Inicializado âœ“");
  }
  
  /// âœ… Upload con transformaciones, progreso y manejo seguro del stream
  Future<String> uploadFile(File file, {
    required bool isVideo,
    String? folder,
    Function(double)? onProgress,
    Duration timeout = const Duration(minutes: 5), // âœ… Timeout configurable
  }) async {
    try {
      await init(); // Asegurar inicializaciÃ³n
      
      // ðŸ“ Validar tamaÃ±o ANTES de subir (ahorra ancho de banda)
      final fileSize = await file.length();
      // âœ… CORRECCIÃ“N: maxImageSizeBytes estÃ¡ directamente en AppConstants
      final maxSize = isVideo 
          ? AppConstants.maxVideoSizeBytes 
          : AppConstants.maxImageSizeBytes;
      
      if (fileSize > maxSize) {
        throw Exception(isVideo 
            ? AppConstants.errorVideoTooLarge 
            : AppConstants.errorImageTooLarge);
      }
      
      // ðŸŒ URL de upload con transformaciones para videos
      final uploadUrl = AppConstants.getCloudinaryUploadUrl(isVideo: isVideo);
      
      print('ðŸ“¤ Subiendo ${isVideo ? 'video' : 'imagen'} (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)...');
      
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['upload_preset'] = AppConstants.cloudinaryUploadPreset;
      
      // ðŸ“ Carpeta opcional para organizaciÃ³n
      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = 'opole/$folder';
      }
      
      // ðŸŽ¬ Transformaciones para videos: optimizaciÃ³n automÃ¡tica
      if (isVideo) {
        request.fields['transformation'] = 'f_auto,q_auto:eco,vc_auto,w_720,du_30';
        request.fields['resource_type'] = 'video';
      } else {
        request.fields['resource_type'] = 'image';
      }
      
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      // ðŸš€ Enviar request con timeout
      final streamedResponse = await _client.send(request).timeout(timeout);
      final totalBytes = streamedResponse.contentLength ?? 0;
      var loadedBytes = 0;
      
      // âœ… CONSUMIR EL STREAM UNA SOLA VEZ + trackear progreso
      // ðŸŽ¯ FIX CRÃTICO: streamedResponse.stream solo se puede escuchar una vez
      final responseBytes = await streamedResponse.stream
          .map((chunk) {
            loadedBytes += chunk.length;
            // ðŸ“Š Reportar progreso en tiempo real
            if (onProgress != null && totalBytes > 0) {
              onProgress((loadedBytes / totalBytes).clamp(0.0, 1.0));
            }
            return chunk;
          })
          .toList(); // âš ï¸ Esperar a que termine TODO el stream
      
      // ðŸ“¦ Construir respuesta HTTP desde los bytes recolectados
      // âœ… FIX: http.Response.bytes ya no acepta isStreaming (API cambiada)
      final response = http.Response.bytes(
        responseBytes.expand((x) => x).toList(),
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
        request: request,
      );
      
      // âœ… Procesar respuesta Ãºnica y centralizada
      return _handleResponse(response, isVideo);
      
    } on TimeoutException {
      print('â° Timeout en upload de ${isVideo ? 'video' : 'imagen'}');
      throw Exception(isVideo 
          ? 'El video tardÃ³ demasiado en subirse. VerificÃ¡ tu conexiÃ³n.' 
          : 'La imagen tardÃ³ demasiado en subirse. IntentÃ¡ de nuevo.');
    } on SocketException {
      print('ðŸ”Œ Error de conexiÃ³n en upload');
      throw Exception('Sin conexiÃ³n. VerificÃ¡ tu internet e intentÃ¡ de nuevo.');
    } catch (e, stack) {
      print('âŒ ExcepciÃ³n en upload: $e\n$stack');
      throw Exception(isVideo 
          ? AppConstants.errorVideoUploadFailed 
          : AppConstants.errorUploadFailed);
    }
  }

  /// âœ… Manejo centralizado y seguro de respuesta JSON
  String _handleResponse(http.Response response, bool isVideo) {
    // ðŸŽ¯ Logging detallado para debugging en producciÃ³n
    if (response.statusCode != 200) {
      print('âŒ Cloudinary Error (${response.statusCode}):');
      print('   Body: ${response.body}');
      print('   Headers: ${response.headers}');
    }
    
    if (response.statusCode == 200) {
      try {
        final jsonResponse = json.decode(response.body);
        final secureUrl = jsonResponse['secure_url'] as String?;
        final publicId = jsonResponse['public_id'] as String?;
        final format = jsonResponse['format'] as String?;
        
        if (secureUrl == null) {
          throw FormatException('secure_url no encontrado en respuesta de Cloudinary');
        }
        
        print('âœ… ${isVideo ? 'Video' : 'Imagen'} subido: $secureUrl');
        
        // ðŸ“ Logging opcional para analytics
        _logUploadMetrics(publicId, format, jsonResponse['bytes']);
        
        return secureUrl;
        
      } on FormatException catch (e) {
        print('âŒ Error parseando respuesta JSON: $e');
        throw Exception('Respuesta invÃ¡lida del servidor de uploads');
      }
    } else {
      // ðŸš¨ Manejo de errores especÃ­ficos por cÃ³digo HTTP
      final errorMessage = _parseCloudinaryError(response.body);
      throw Exception(isVideo 
          ? 'Error al subir video: $errorMessage' 
          : 'Error al subir imagen: $errorMessage');
    }
  }
  
  /// âœ… Parser de errores de Cloudinary para mensajes user-friendly
  String _parseCloudinaryError(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      final message = json['error']?['message'] as String?;
      if (message != null) return message;
    } catch (_) {}
    return 'Error desconocido del servidor';
  }
  
  /// âœ… Logging opcional de mÃ©tricas de upload (para analytics)
  void _logUploadMetrics(String? publicId, String? format, dynamic bytes) {
    // TODO: Integrar con tu sistema de analytics
    // Analytics.logEvent('upload_complete', parameters: {
    //   'public_id': publicId,
    //   'format': format,
    //   'size_bytes': bytes,
    // });
    print('ðŸ“Š Upload metrics: id=$publicId, format=$format, size=$bytes bytes');
  }
  
  // ============================================================================
  // ðŸŽ¯ MÃ‰TODOS PÃšBLICOS CONVENIENTES
  // ============================================================================
  
  /// âœ… Upload de imagen con folder opcional
  Future<String> uploadImage(File imageFile, {String? folder}) async {
    return uploadFile(imageFile, isVideo: false, folder: folder);
  }

  /// âœ… Upload de video con progreso y userId para tracking
  Future<String> uploadVideo(File videoFile, {
    String? userId, 
    Function(double)? onProgress,
  }) async {
    // userId para logging/auditorÃ­a (no afecta el upload en sÃ­)
    if (userId != null) {
      print('ðŸ‘¤ Upload de video para user: $userId');
    }
    return uploadFile(videoFile, isVideo: true, onProgress: onProgress);
  }
  
  // ============================================================================
  // ðŸ” ALIASES PARA COMPATIBILIDAD CON CÃ“DIGO EXISTENTE
  // ============================================================================
  
  Future<String> uploadProfileImage(String filePath, {String? folder}) async {
    return uploadImage(File(filePath), folder: folder);
  }
  
  Future<String> uploadVideoFromPath(String filePath, {String? userId}) async {
    return uploadVideo(File(filePath), userId: userId);
  }
  
  // ============================================================================
  // ðŸŽ¬ OPTIMIZACIÃ“N DE URLs PARA REPRODUCCIÃ“N (CDN + Transformaciones)
  // ============================================================================
  
  /// âœ… Generar URL de video optimizada para streaming en mÃ³vil
  /// Aplica: f_auto (formato adaptativo), q_auto:eco (calidad/velocidad), 
  ///        vc_auto (codec Ã³ptimo), w_720 (ancho mÃ¡ximo), du_30 (duraciÃ³n mÃ¡x)
  String getOptimizedVideoUrl(String originalUrl) {
    if (!originalUrl.contains('res.cloudinary.com')) {
      print('âš ï¸ URL no es de Cloudinary: $originalUrl');
      return originalUrl;
    }
    
    // âœ… Si ya tiene transformaciones, no duplicar
    if (RegExp(r'/upload/[a-z_,0-9:\-]+/').hasMatch(originalUrl)) {
      return originalUrl;
    }
    
    // ðŸŽ¯ Transformaciones para reproducciÃ³n Ã³ptima en mÃ³vil
    return originalUrl.replaceFirst(
      '/upload/', 
      '/upload/f_auto,q_auto:eco,vc_auto,w_720,du_30/',
    );
  }
  
  /// âœ… Generar URL de thumbnail optimizado para carga instantÃ¡nea
  /// ðŸŽ¯ q_auto:low + f_jpg = carga casi inmediata (como Instagram)
  String getOptimizedThumbnailUrl(String originalUrl, {int width = 400}) {
    if (!originalUrl.contains('res.cloudinary.com')) return originalUrl;
    
    // Si ya tiene transformaciones, respetarlas
    if (RegExp(r'/upload/[a-z_,0-9:\-]+/').hasMatch(originalUrl)) {
      return originalUrl;
    }
    
    // ðŸš€ Transformaciones para thumbnail: baja calidad, carga rÃ¡pida
    return originalUrl.replaceFirst(
      '/upload/', 
      '/image/upload/f_jpg,q_auto:low,w_$width,c_fill,g_auto/',
    );
  }
  
  /// âœ… Generar URL de imagen para feed (calidad media, responsive)
  String getOptimizedImageUrl(String originalUrl, {int width = 720}) {
    if (!originalUrl.contains('res.cloudinary.com')) return originalUrl;
    
    if (RegExp(r'/upload/[a-z_,0-9:\-]+/').hasMatch(originalUrl)) {
      return originalUrl;
    }
    
    // âš–ï¸ Balance calidad/velocidad para imÃ¡genes en feed
    return originalUrl.replaceFirst(
      '/upload/', 
      '/image/upload/f_auto,q_auto:good,w_$width,c_limit/',
    );
  }
  
  // ============================================================================
  // ðŸ§¹ CLEANUP Y DISPOSAL
  // ============================================================================
  
  /// âœ… Cerrar cliente HTTP cuando la app se destruye
  void dispose() {
    _client.close();
    _isInitialized = false;
    print('ðŸ§¹ Cloudinary Service disposed');
  }
}
