import 'package:flutter/services.dart'; // â† âœ… AGREGADO: Para PlatformException
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:opole/core/services/supabase_client.dart' as local;

class AuthService extends GetxService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService();

  final Rx<User?> currentUser = Rx<User?>(null);

  Stream<AuthState> get authStateChanges =>
      local.SupabaseClient.auth.onAuthStateChange;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = local.SupabaseClient.currentUser;
    authStateChanges.listen((state) {
      currentUser.value = state.session?.user;
      print('ðŸ”„ [AUTH] Auth state changed: ${state.event}');
    });
  }

  // ðŸ”¹âœ… MÃ‰TODO FINAL CON LOGGING + FIXES APLICADOS
  Future<AuthResponse?> signInWithGoogle() async {
    // ðŸš¨ðŸš¨ðŸš¨ MARKER #1: ENTRY POINT
    print('ðŸš¨ðŸš¨ðŸš¨ [AUTH] signInWithGoogle() ENTRY REACHED: ${DateTime.now().millisecond} ðŸš¨ðŸš¨ðŸš¨');
    
    // ðŸ’£ðŸ’£ðŸ’£ MARKER #2: START
    print('ðŸ’£ðŸ’£ðŸ’£ [MARKER] signInWithGoogle START: ${DateTime.now().millisecond} ðŸ’£ðŸ’£ðŸ’£');
    
    try {
      print('ðŸ”µ [AUTH] === INICIO signInWithGoogle ===');
      print('ðŸ”µ [AUTH] Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      print('ðŸ”µ [AUTH] Supabase initialized: ${local.SupabaseClient != null}');
      print('ðŸ”µ [AUTH] This hashCode: ${this.hashCode}');

      // âœ… RESTAURADO: Web Client ID configurado en Supabase Dashboard
      const String webClientId =
          '643602636807-ptlcj6gnjo8pa8ntteue9pj7jqt3kdro.apps.googleusercontent.com';

      print('ðŸ”µ [AUTH] Usando clientId: ${webClientId.substring(0, 30)}...');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: webClientId, // â† âœ… CLAVE: restaurar esta lÃ­nea
      );

      print('ðŸ”µ [AUTH] GoogleSignIn instance created');

      // ðŸ“± Paso 1: Iniciar flujo de Google
      print('ðŸ”µ [AUTH] Llamando a googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        print('âš ï¸ [AUTH] Usuario cancelÃ³ Google Sign-In');
        print('ðŸ’£ðŸ’£ðŸ’£ [MARKER] signInWithGoogle END: CANCELLED ðŸ’£ðŸ’£ðŸ’£');
        return null;
      }
      print('âœ… [AUTH] Google user obtenido: ${googleUser.email}');
      print('âœ… [AUTH] Google user ID: ${googleUser.id}');

      // ðŸ“± Paso 2: Obtener tokens
      print('ðŸ”µ [AUTH] Obteniendo authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      print('ðŸ”‘ [AUTH] idToken: ${idToken != null ? "âœ… SÃ­ (${idToken.length} chars)" : "âŒ NULL"}');
      print('ðŸ”‘ [AUTH] accessToken: ${accessToken != null ? "âœ… SÃ­" : "âŒ NULL"}');

      // ðŸš¨ ValidaciÃ³n crÃ­tica
      if (idToken == null) {
        print('âŒ [AUTH] ERROR CRÃTICO: idToken es null');
        print('âŒ [AUTH] Posibles causas:');
        print('   1. SHA-1 no registrado en Google Cloud Console');
        print('   2. Package name incorrecto en google-services.json');
        print('   3. clientId no coincide con configuraciÃ³n');
        print('ðŸ’£ðŸ’£ðŸ’£ [MARKER] signInWithGoogle END: IDTOKEN_NULL ðŸ’£ðŸ’£ðŸ’£');
        throw Exception('No se pudo obtener el ID Token. Revisa configuraciÃ³n de Google.');
      }

      // ðŸ“± Paso 3: Enviar token a Supabase
      print('ðŸ”µ [AUTH] Enviando token a Supabase (signInWithIdToken)...');
      print('ðŸ”µ [AUTH] Provider: OAuthProvider.google');
      
      final response = await local.SupabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      print('âœ… [AUTH] Supabase Auth exitoso!');
      print('âœ… [AUTH] User email: ${response.user?.email}');
      print('âœ… [AUTH] User ID: ${response.user?.id}');
      print('âœ… [AUTH] Session: ${response.session != null ? "âœ… Activa" : "âŒ Null"}');
      print('ðŸ’£ðŸ’£ðŸ’£ [MARKER] signInWithGoogle END: SUCCESS ðŸ’£ðŸ’£ðŸ’£');
      print('ðŸ”µ [AUTH] === FIN signInWithGoogle (Ã‰XITO) ===');
      
      return response;

    } on AuthException catch (e) {
      print('âŒ [AUTH] AuthException: ${e.message}');
      print('âŒ [AUTH] StatusCode: ${e.statusCode}');
      print('âŒ [AUTH] === FIN signInWithGoogle (ERROR AUTH) ===');
      
      if (e.message?.toLowerCase().contains('unacceptable audience') == true) {
        print('ðŸ’¡ [AUTH] HINT: El clientId en cÃ³digo debe coincidir EXACTAMENTE con Supabase Dashboard');
        print('ðŸ’¡ [AUTH] Web Client ID esperado: 643602636807-ptlcj6gnjo8pa8ntteue9pj7jqt3kdro...');
      }
      print('ðŸ’£ðŸ’£ðŸ’£ [MARKER] signInWithGoogle END: AUTH_EXCEPTION ðŸ’£ðŸ’£ðŸ’£');
      rethrow;

    } on PlatformException catch (e) {
      print('âŒ [AUTH] PlatformException: ${e.message}');
      print('âŒ [AUTH] Code: ${e.code}');
      print('âŒ [AUTH] === FIN signInWithGoogle (ERROR PLATFORM) ===');
      
      if (e.code == '10' || e.message?.toLowerCase().contains('developer_error') == true) {
        print('ðŸ’¡ [AUTH] DEVELOPER_ERROR - VerificÃ¡:');
        print('   1. SHA-1 en Firebase Console: 5F:38:74:05:1C:A2:4D:C8:79:B9:F3:44:04:9B:61:18:C5:49:99:65');
        print('   2. Package name: com.opole.app');
        print('   3. google-services.json actualizado en android/app/');
      }
      print('ðŸ’£ðŸ’£ðŸ’£ [MARKER] signInWithGoogle END: PLATFORM_EXCEPTION ðŸ’£ðŸ’£ðŸ’£');
      rethrow;

    } catch (e, stack) {
      print('âŒ [AUTH] Error inesperado: $e');
      print('âŒ [AUTH] Type: ${e.runtimeType}');
      print('âŒ [AUTH] Stack trace: $stack');
      print('âŒ [AUTH] === FIN signInWithGoogle (ERROR GENÃ‰RICO) ===');
      print('ðŸ’£ðŸ’£ðŸ’£ [MARKER] signInWithGoogle END: GENERIC_ERROR ðŸ’£ðŸ’£ðŸ’£');
      rethrow;
    }
  }

  // ðŸ”¹ Email/Password Sign In
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await local.SupabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ðŸ”¹âœ… Email/Password Sign Up - FIX: parÃ¡metro 'data' como named parameter
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password, {
    Map<String, dynamic>? userMetadata,
  }) async {
    // âœ… FIX: 'data' debe ser named parameter en supabase_flutter ^2.8.0
    return await local.SupabaseClient.auth.signUp(
      email: email,
      password: password,
      data: userMetadata, // â† âœ… Named parameter (NO positional)
    );
  }

  // ðŸ”¹ Sign Out
  Future<void> signOut() async {
    await local.SupabaseClient.auth.signOut();
    await GoogleSignIn().signOut(); // Limpia sesiÃ³n del plugin
    currentUser.value = null;
    print('âœ… [AUTH] SesiÃ³n cerrada correctamente');
  }

  // ðŸ”¹ Getters
  bool get isLoggedIn => currentUser.value != null;
  String? get currentUserId => currentUser.value?.id;
  String? get currentUserEmail => currentUser.value?.email;
  Map<String, dynamic>? get currentUserMetadata => currentUser.value?.userMetadata;

  // ðŸ”¹ Refresh Session
  Future<AuthResponse> refreshSession() async {
    return await local.SupabaseClient.auth.refreshSession();
  }
}
