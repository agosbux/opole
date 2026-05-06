// test_parsing.dart (SOLO PARA VALIDAR, luego borrar)
import 'dart:convert';
import 'package:opole/core/supabase/models/reel_model.dart';

void main() {
  // JSON simulando respuesta de Supabase con image_urls
  final json = {
    'id': 'cb6114d6-7ba6-4a9a-ad07-2c8834694600',
    'user_id': '1a003245-ef24-42e9-89d2-c765677928d3',
    'video_url': 'https://res.cloudinary.com/demo/video/sample.mp4',
    'thumbnail_url': 'https://picsum.photos/seed/thumb/400/700',
    'image_urls': [
      'https://picsum.photos/seed/reel1/400/700',
      'https://picsum.photos/seed/reel2/400/700',
      'https://picsum.photos/seed/reel3/400/700'
    ],
    'title': 'TEST_VERIFICAR_IMAGENES',
    'status': 'active',
    'created_at': DateTime.now().toIso8601String(),
  };

  try {
    final reel = ReelModel.fromJson(json);
    
    print('✅ Parsing exitoso');
    print('🆔 ID: ${reel.id}');
    print('🖼️ imageUrls: ${reel.imageUrls}');
    print('📊 Total imágenes: ${reel.imageUrls?.length ?? 0}');
    
    if (reel.imageUrls != null && reel.imageUrls!.length == 3) {
      print('🎉 VALIDACIÓN EXITOSA: imageUrls se parsea correctamente');
    } else {
      print('❌ ERROR: imageUrls no tiene el valor esperado');
    }
  } catch (e, stack) {
    print('❌ ERROR de parsing: $e');
    print(stack);
  }
}