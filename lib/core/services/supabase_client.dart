// lib/core/services/supabase_client.dart
// ===================================================================
// APP SUPABASE CLIENT - Singleton Global (VERSIÃ“N CON DOTENV)
// ===================================================================
// â€¢ Wrapper para Supabase con alias para evitar conflictos
// â€¢ Acceso centralizado a Auth, Database, Storage, Realtime
// â€¢ MÃ©todos de negocio comunes
// â€¢ âœ… Carga credenciales desde .env usando flutter_dotenv
// ===================================================================

import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // â† âœ… AGREGADO: Para leer .env

class SupabaseClient {
  // Singleton
  static final SupabaseClient _instance = SupabaseClient._internal();
  factory SupabaseClient() => _instance;
  SupabaseClient._internal();

  // Cliente interno de Supabase (instancia oficial)
  static late sb.SupabaseClient _client;

  // Flag de inicializaciÃ³n
  static bool _isInitialized = false;

  /// Inicializa la conexiÃ³n con Supabase. Debe llamarse despuÃ©s de cargar .env.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // âœ… LEER CREDENCIALES DESDE .env (como en versiÃ³n 1.4 que funcionaba)
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://ihvbmppztoqkntifwvfa.supabase.co';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_V1IoZGuMp_24Pv1P_WVbdw_knNJx-XR';

      if (kDebugMode) {
        print('ðŸ”µ [SUPABASE] Inicializando con URL: ${supabaseUrl.substring(0, min(supabaseUrl.length, 30))}...');
        print('ðŸ”µ [SUPABASE] AnonKey presente: ${supabaseAnonKey.isNotEmpty ? "âœ… SÃ­" : "âŒ No"}');
      }

      await sb.Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
      
      _client = sb.Supabase.instance.client;
      _isInitialized = true;
      
      if (kDebugMode) print('âœ… Supabase inicializado correctamente');
      if (kDebugMode) print('ðŸ“ Supabase URL: $supabaseUrl');
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('âŒ ERROR inicializando Supabase: $e');
        print('Stack: $stack');
        print('ðŸ’¡ VerificÃ¡ que .env existe y tiene SUPABASE_URL y SUPABASE_ANON_KEY');
      }
      rethrow;
    }
  }

  // Helper para min() sin importar dart:math globalmente
  static int min(int a, int b) => a < b ? a : b;

  // ===================================================================
  // ðŸ”¹ ACCESOS RÃPIDOS
  // ===================================================================

  /// Cliente original de Supabase (por si se necesita acceso directo).
  static sb.SupabaseClient get rawClient => _client;

  /// MÃ³dulo de autenticaciÃ³n.
  static sb.GoTrueClient get auth => _client.auth;

  /// MÃ³dulo de storage.
  static sb.SupabaseStorageClient get storage => _client.storage;

  /// MÃ³dulo de realtime.
  static sb.RealtimeClient get realtime => _client.realtime;

  /// Usuario actualmente autenticado (null si no hay sesiÃ³n).
  static sb.User? get currentUser => _client.auth.currentUser;

  /// Stream de cambios en el estado de autenticaciÃ³n.
  static Stream<sb.AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Indica si hay un usuario autenticado.
  static bool get isLoggedIn => currentUser != null;

  /// ID del usuario actual (null si no hay sesiÃ³n).
  static String? get currentUserId => currentUser?.id;

  // ===================================================================
  // ðŸ”¹ GETTERS DE COMPATIBILIDAD
  // ===================================================================

  /// Obtiene la instancia singleton del wrapper.
  static SupabaseClient get instance => _instance;

  /// Expone el cliente original de Supabase.
  static sb.SupabaseClient get client => _client;

  // ===================================================================
  // ðŸ”¹ MÃ‰TODOS PARA CONSULTAS
  // ===================================================================

  /// Inicia una consulta sobre una tabla.
  static dynamic from(String table) => _client.from(table);

  /// Ejecuta una funciÃ³n RPC en Supabase.
  static Future<dynamic> rpc(String function, {Map<String, dynamic>? params}) {
    return _client.rpc(function, params: params);
  }

  // ===================================================================
  // ðŸ”¹ MÃ‰TODOS DE NEGOCIO
  // ===================================================================

  static Future<Map<String, dynamic>?> getPerfilCompleto() async {
    if (!isLoggedIn) return null;
    try {
      final response = await rpc('obtener_perfil_completo', params: {'p_user_id': currentUserId});
      return response is Map<String, dynamic> ? response : null;
    } catch (e) {
      if (kDebugMode) print('âŒ Error obteniendo perfil: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getFeed({
    String? locality,
    String? province,
    List<String>? interests,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await rpc('get_opole_feed', params: {
        'p_locality': locality,
        'p_province': province,
        'p_user_interests': interests,
        'p_limit': limit,
        'p_offset': offset,
        'p_exclude_user_id': currentUserId,
      });
      return response is List ? List<Map<String, dynamic>>.from(response) : [];
    } catch (e) {
      if (kDebugMode) print('âŒ Error obteniendo feed: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
    if (kDebugMode) print('âœ… SesiÃ³n cerrada');
  }

  static void reset() => _isInitialized = false;
  static bool get isInitialized => _isInitialized;
}
