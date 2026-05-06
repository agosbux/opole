// lib/utils/constants.dart

class AppConstants {
  // Cloudinary - ConfiguraciÃ³n verificada âœ“
  static const String cloudinaryCloudName = 'TU_CLOUD_NAME'; // âš ï¸ REEMPLAZAR
  static const String cloudinaryUploadPreset = 'opolepreset'; // âœ“ UNSIGNED verificada
  
  // âœ… NUEVA FUNCIÃ“N DINÃMICA (Sustituye a la anterior)
  static String getCloudinaryUploadUrl({required bool isVideo}) {
    final type = isVideo ? 'video' : 'image';
    return 'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/$type/upload';
  }
  
  // Firebase Collections
  static const String usersCollection = 'users';
  
  // Validaciones de imagen
  static const int maxImageSizeMB = 5;
  static const int maxImageSizeBytes = 5 * 1024 * 1024;
  
  // Validaciones de video - NUEVAS CONSTANTES
  static const int maxVideoSizeMB = 50; // LÃ­mite de 50MB para videos
  static const int maxVideoSizeBytes = maxVideoSizeMB * 1024 * 1024;
  
  // Argentina - Datos fijos
  static const String countryCode = 'AR';
  static const String countryName = 'Argentina';
  static const String countryFlag = 'ðŸ‡¦ðŸ‡·';
  
  // Mensajes
  static const String errorNoInternet = 'Sin conexiÃ³n a internet';
  static const String errorImageTooLarge = 'La imagen no debe superar los 5MB';
  static const String errorVideoTooLarge = 'El video no debe superar los 50MB';
  static const String errorUploadFailed = 'Error al subir la imagen';
  static const String errorVideoUploadFailed = 'Error al subir el video a la nube'; // âœ… NUEVO MENSAJE
  static const String errorSaveFailed = 'Error al guardar los cambios';
  static const String successProfileUpdated = 'âœ… Â¡Perfil actualizado con Ã©xito!';
  
  // URLs de Cloudinary
  static String getProfileImageUrl(String publicId) {
    return 'https://res.cloudinary.com/$cloudinaryCloudName/image/upload/v1/$publicId';
  }
  
  static String getVideoUrl(String publicId) {
    return 'https://res.cloudinary.com/$cloudinaryCloudName/video/upload/v1/$publicId';
  }
}

