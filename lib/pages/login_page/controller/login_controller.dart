import 'dart:math';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opole/ui/loading_ui.dart';
import 'package:opole/routes/app_routes.dart';
import 'package:opole/utils/database.dart';
import 'package:opole/utils/enums.dart';
import 'package:flutter/services.dart';
import 'package:opole/utils/internet_connection.dart';
import 'package:opole/utils/utils.dart';
import 'package:opole/core/services/auth_service.dart';
import 'package:opole/core/services/supabase_client.dart' as local;
import 'package:get_storage/get_storage.dart';

class LoginController extends GetxController {
  List<String> randomNames = [
    "Emily Johnson", "Liam Smith", "Isabella Martinez", "Noah Brown",
    "Sofia Davis", "Oliver Wilson", "Mia Anderson", "James Thomas",
    "Ava Robinson", "Benjamin Lee", "Charlotte Miller", "Lucas Garcia",
    "Amelia White", "Ethan Harris", "Harper Clark", "Alexander Lewis",
    "Evelyn Walker", "Daniel Hall", "Grace Young", "Michael Allen",
  ];

  String onGetRandomName() {
    Random random = Random();
    int index = random.nextInt(randomNames.length);
    return randomNames[index];
  }

  // ðŸ”¹ MÃ‰TODO MIGRADO A SUPABASE
  Future<void> createUserIfNotExists(User supabaseUser) async {
    print('ðŸ“ [SUPABASE] Sincronizando usuario...');

    try {
      await local.SupabaseClient.from('users').update({
        'last_active_at': DateTime.now().toIso8601String(),
        'photo_url': supabaseUser.userMetadata?['avatar_url'],
        'username': supabaseUser.userMetadata?['full_name'] ?? onGetRandomName(),
      }).eq('id', supabaseUser.id);

      print("âœ… Usuario sincronizado: ${supabaseUser.id}");

      await GetStorage().write("loginUserId", supabaseUser.id);
      await GetStorage().write("loginType", 2);

      await loadUserDataFromSupabase(supabaseUser.id);
    } catch (e, stack) {
      print('âŒ Error en createUserIfNotExists: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  // ðŸ”¹ NUEVO MÃ‰TODO PARA CARGAR PERFIL DESDE SUPABASE
  Future<void> loadUserDataFromSupabase(String uid) async {
    try {
      final response = await local.SupabaseClient.rpc('obtener_perfil_completo', params: {
        'p_user_id': uid,
      });

      if (response != null) {
        print('âœ… Perfil cargado desde Supabase: ${response['username']}');
      }
    } catch (e) {
      print('âŒ Error cargando perfil desde Supabase: $e');
    }
  }

  // ðŸ”¹âœ… MÃ‰TODO MIGRADO A SUPABASE + CORRECCIÃ“N DE INTERNET CHECK
  Future<void> onGoogleLogin() async {
    // ðŸš¨ LOGS INICIALES DE DEBUG
    print('ðŸ”µ [CONTROLLER] === onGoogleLogin INICIADO ===');
    print('ðŸ”µ [CONTROLLER] DateTime: ${DateTime.now()}');

    // ðŸ”¹ âœ… CORRECCIÃ“N CRÃTICA: 
    // Removida verificaciÃ³n de InternetConnection.isConnect.value 
    // porque da falso positivo cuando la app va a "inactive" al abrir Google picker.
    // Google Sign-In y Supabase ya manejan sus propios errores de red.
    
    // Si querÃ©s mantener un check bÃ¡sico, usÃ¡ una verificaciÃ³n async en el momento:
    // final hasInternet = await InternetConnection.isConnected;
    // if (!hasInternet) {
    //   Utils.showToast(EnumLocal.txtConnectionLost.name.tr);
    //   return;
    // }

    try {
      print('ðŸ”µ [CONTROLLER] Mostrando LoadingUi...');
      Get.dialog(const LoadingUi(), barrierDismissible: false);

      // ðŸ” DEBUG: Verificar que AuthService estÃ¡ disponible
      print('ðŸ” [CONTROLLER] Get.isRegistered<AuthService>: ${Get.isRegistered<AuthService>()}');
      
      final authService = Get.find<AuthService>();
      print('ðŸ” [CONTROLLER] authService.hashCode: ${authService.hashCode}');
      print('ðŸ” [CONTROLLER] authService.runtimeType: ${authService.runtimeType}');
      print('ðŸ” [CONTROLLER] Llamando a authService.signInWithGoogle()...');
      
      // â±ï¸ Medir tiempo de ejecuciÃ³n
      final stopwatch = Stopwatch()..start();
      
      final response = await authService.signInWithGoogle();
      
      print('âœ… [CONTROLLER] signInWithGoogle retornÃ³ en ${stopwatch.elapsedMilliseconds}ms');
      print('âœ… [CONTROLLER] response: ${response != null ? "âœ… User: ${response.user?.email}" : "âŒ NULL"}');

      if (response?.user != null) {
        final supabaseUser = response!.user!;
        print('âœ… [CONTROLLER] Usuario autenticado: ${supabaseUser.email}');
        print('âœ… [CONTROLLER] User ID: ${supabaseUser.id}');

        await createUserIfNotExists(supabaseUser);

        Get.back(); // Cerrar loading
        Utils.showToast('Bienvenido ${supabaseUser.userMetadata?['full_name'] ?? ""}');
        print('ðŸ”„ [CONTROLLER] Navegando a ${AppRoutes.bottomBarPage}...');
        Get.offAllNamed(AppRoutes.bottomBarPage);
      } else {
        print('âš ï¸ [CONTROLLER] Login cancelado o fallÃ³ (response.user == null)');
        Get.back();
        Utils.showToast('Login cancelado');
      }
    } catch (e, stack) {
      print('âŒ [CONTROLLER] ERROR en onGoogleLogin: $e');
      print('âŒ [CONTROLLER] Type: ${e.runtimeType}');
      print('âŒ [CONTROLLER] Stack trace: $stack');
      
      Get.back(); // Cerrar loading siempre

      // Manejo inteligente de errores
      if (e is AuthException) {
        print('âŒ [CONTROLLER] AuthException detectada');
        final message = _mapSupabaseAuthError(e);
        Utils.showToast(message);
      } else if (e is PlatformException) {
        print('âŒ [CONTROLLER] PlatformException: code=${e.code}, message=${e.message}');
        Utils.showToast('Error de plataforma: ${e.message ?? e.code}');
      } else if (e.toString().contains('SocketException') || 
                 e.toString().toLowerCase().contains('connection')) {
        print('âŒ [CONTROLLER] Error de conexiÃ³n detectado');
        Utils.showToast('Error de conexiÃ³n. Verifica tu internet.');
      } else {
        print('âŒ [CONTROLLER] Error genÃ©rico');
        Utils.showToast('Error en Google Login. Intenta de nuevo.');
      }
    } finally {
      print('ðŸ”µ [CONTROLLER] === onGoogleLogin FINALIZADO ===');
    }
  }

  // ðŸ”¹ Helper para mapear errores de Supabase a mensajes amigables
  String _mapSupabaseAuthError(AuthException error) {
    final msg = error.message?.toLowerCase() ?? '';
    if (msg.contains('invalid credentials') || msg.contains('invalid login')) {
      return 'Credenciales invÃ¡lidas. Verifica tu cuenta.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirma tu email para continuar.';
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Demasiados intentos. Espera unos minutos.';
    }
    if (msg.contains('unacceptable audience')) {
      return 'ConfiguraciÃ³n de OAuth incorrecta. Contacta al soporte.';
    }
    if (msg.contains('provider not enabled')) {
      return 'Google Sign-In no estÃ¡ configurado. Contacta al soporte.';
    }
    return 'Error de autenticaciÃ³n: ${error.message}';
  }

  // ðŸ”¹ MÃ‰TODO SIN CAMBIOS (SOLO NAVEGACIÃ“N)
  Future<void> onQuickLogin() async {
    print('âš¡ Quick Login iniciado...');

    if (!InternetConnection.isConnect.value) {
      Utils.showToast(EnumLocal.txtConnectionLost.name.tr);
      Utils.showLog("Internet Connection Lost !!");
      return;
    }

    try {
      Get.dialog(const LoadingUi(), barrierDismissible: false);
      Get.back();
      Get.offAllNamed(AppRoutes.bottomBarPage);
    } catch (e, stack) {
      print('âŒ ERROR en Quick Login: $e');
      print('Stack trace: $stack');
      Get.back();
      Utils.showToast('Modo demo activado');
      Get.offAllNamed(AppRoutes.bottomBarPage);
    }
  }

  // ðŸ”¹ MÃ‰TODO DE EMERGENCIA: Modo demo directo
  void onDemoMode() {
    print('ðŸŽ® Activando modo demo...');
    Utils.showToast('Modo demo activado');
    Get.offAllNamed(AppRoutes.bottomBarPage);
  }
}
