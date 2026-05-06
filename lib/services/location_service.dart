// lib/services/location_service.dart
// ===================================================================
// LOCATION SERVICE - VersiÃ³n Supabase (sin Firebase)
// ===================================================================

import 'package:get/get.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService();

  final RxMap<String, String> locations = <String, String>{}.obs;

  Future<void> loadLocations() async {
    // ðŸ”¹ Cargar desde Supabase en lugar de Firestore
    try {
      // Ejemplo: await SupabaseClient.from('locations').select();
      // Por ahora, datos mock para que compile:
      locations.addAll({
        'AR': 'Argentina',
        'US': 'United States',
        'ES': 'EspaÃ±a',
        'MX': 'MÃ©xico',
        'CO': 'Colombia',
      });
      Get.log('âœ… Ubicaciones cargadas: ${locations.length}');
    } catch (e) {
      Get.log('âŒ Error cargando ubicaciones: $e');
    }
  }

  String? getCountryName(String countryCode) => locations[countryCode];
}
