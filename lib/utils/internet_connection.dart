// lib/utils/internet_connection.dart
// ===================================================================
// INTERNET CONNECTION - Compatible con connectivity_plus ^6.0.3
// ===================================================================
// â€¢ API actualizada: onConnectivityChanged emite List<ConnectivityResult>
// â€¢ checkConnectivity() ahora retorna List<ConnectivityResult>
// â€¢ Mantiene compatibilidad con RxBool para cÃ³digo existente
// â€¢ âœ… Imports corregidos + typo fix
// ===================================================================

// âœ… FIX: Imports faltantes
import 'dart:async'; // â† Para StreamSubscription
import 'package:flutter/foundation.dart' show kDebugMode; // â† Para kDebugMode

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class InternetConnection {
  static final Connectivity _connectivity = Connectivity();
  
  // âœ… RxBool para compatibilidad con cÃ³digo existente (UI bindings, etc.)
  static final RxBool isConnect = false.obs;

  // ===================================================================
  // ðŸ”¹ INICIALIZACIÃ“N (opcional, para escuchar cambios automÃ¡ticamente)
  // ===================================================================
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  static Future<void> init() async {
    // Chequear estado inicial
    await _checkAndUpdateConnection();
    
    // Suscribirse a cambios
    _startListening();
  }
  
  static void _startListening() {
    _subscription?.cancel();
    
    // âœ… FIX: onConnectivityChanged ahora emite List<ConnectivityResult>
    _subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionFromList(results);
    });
  }
  
  static void _updateConnectionFromList(List<ConnectivityResult> results) {
    final connected = _isConnectedList(results);
    isConnect.value = connected;
    
    if (kDebugMode) {
      Get.log('ðŸ”„ [INTERNET] Connection changed: ${results.map((r) => r.name).join(', ')} â†’ ${connected ? "âœ… Connected" : "âŒ Disconnected"}');
    }
  }
  
  static Future<void> _checkAndUpdateConnection() async {
    try {
      // âœ… FIX: checkConnectivity() ahora retorna List<ConnectivityResult>
      final results = await _connectivity.checkConnectivity();
      final connected = _isConnectedList(results);
      isConnect.value = connected;
      
      if (kDebugMode) {
        Get.log('âœ… [INTERNET] Initial check: ${results.map((r) => r.name).join(', ')} â†’ ${connected ? "âœ… Connected" : "âŒ Disconnected"}');
      }
    } catch (e) {
      Get.log('âš ï¸ [INTERNET] Error checking connection: $e');
      isConnect.value = false;
    }
  }
  
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ===================================================================
  // ðŸ”¹ STREAM DE CAMBIOS (API PÃšBLICA - retorna Stream<bool>)
  // ===================================================================
  
  // âœ… Stream que emite true/false segÃºn si hay conexiÃ³n
  static Stream<bool> get onConnectionChanged {
    // âœ… FIX: Mapear List<ConnectivityResult> â†’ bool
    return _connectivity.onConnectivityChanged.map((List<ConnectivityResult> results) {
      return _isConnectedList(results);
    });
  }

  // ===================================================================
  // ðŸ”¹ CHEQUEO DE CONEXIÃ“N (API PÃšBLICA)
  // ===================================================================
  
  // âœ… Chequeo asÃ­ncrono del estado actual
  static Future<bool> get isConnected async {
    try {
      // âœ… FIX: checkConnectivity() retorna List<ConnectivityResult>
      final results = await _connectivity.checkConnectivity();
      return _isConnectedList(results);
    } catch (e) {
      if (kDebugMode) Get.log('âš ï¸ [INTERNET] Error checking connection: $e');
      return false;
    }
  }

  // ===================================================================
  // ðŸ”¹ HELPERS PRIVADOS
  // ===================================================================
  
  // âœ… Helper para evaluar una LISTA de resultados (nueva API)
  static bool _isConnectedList(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    // Hay conexiÃ³n si AL MENOS UNO de los resultados indica conexiÃ³n activa
    return results.any((result) => _isConnectedSingle(result));
  }
  
  // âœ… Helper para evaluar un resultado INDIVIDUAL (compatibilidad interna)
  static bool _isConnectedSingle(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.none:
        return false;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
      case ConnectivityResult.mobile:
      case ConnectivityResult.vpn:
      case ConnectivityResult.other:
        return true;
      default:
        return false;
    }
  }

  // ===================================================================
  // ðŸ”¹ UTILIDADES ADICIONALES (para analytics o UI avanzada)
  // ===================================================================
  
  // âœ… Obtener tipos de conexiÃ³n activos actualmente
  static Future<List<ConnectivityResult>> getConnectionTypes() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      if (kDebugMode) Get.log('âš ï¸ [INTERNET] Error getting connection types: $e');
      return [ConnectivityResult.none];
    }
  }
  
  // âœ… Mensaje amigable segÃºn la lista de resultados
  static String getConnectionMessage(List<ConnectivityResult> results) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return 'Sin conexiÃ³n a internet';
    }
    
    // Priorizar tipos de conexiÃ³n en orden de preferencia
    if (results.contains(ConnectivityResult.wifi)) return 'Conectado vÃ­a Wi-Fi';
    if (results.contains(ConnectivityResult.ethernet)) return 'Conectado vÃ­a Ethernet';
    if (results.contains(ConnectivityResult.mobile)) return 'Conectado vÃ­a datos mÃ³viles';
    if (results.contains(ConnectivityResult.vpn)) return 'Conectado vÃ­a VPN';
    if (results.contains(ConnectivityResult.bluetooth)) return 'Conectado vÃ­a Bluetooth';
    
    return 'Conectado';
  }
  
  // âœ… VersiÃ³n simplificada para uso rÃ¡pido (evalÃºa el "mejor" resultado)
  // âœ… FIX: isConnect (no _isConnect)
  static String getSimpleConnectionMessage() {
    return isConnect.value 
      ? 'âœ… Conectado' 
      : 'âŒ Sin conexiÃ³n';
  }
}
