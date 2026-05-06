import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:opole/routes/app_routes.dart';
import 'package:opole/utils/database.dart';
import 'package:opole/core/services/supabase_client.dart' as local;
import 'package:opole/core/services/auth_service.dart';

class SplashController extends GetxController {
  final RxBool isCheckingSession = true.obs;

  @override
  void onInit() {
    super.onInit();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      print('🔍 [SPLASH] Verificando sesión con Supabase...');
      await Future.delayed(const Duration(milliseconds: 500));

      final currentUser = local.SupabaseClient.currentUser;
      final currentSession = local.SupabaseClient.auth.currentSession;

      print('👤 [SPLASH] currentUser: ${currentUser?.email ?? "null"}');
      print('🔑 [SPLASH] currentSession: ${currentSession != null ? "activa" : "null"}');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentUser != null && currentSession != null) {
          print('✅ [SPLASH] Sesión válida - Redirigiendo a /bottom-bar');
          
          // ✅ Almacenar datos de autenticación usando helper async
          unawaited(_storeAuthData(currentUser.id, 2));
          unawaited(_loadUserProfile(currentUser.id));
          
          Get.offAllNamed(AppRoutes.bottomBarPage);
        } else {
          print('⚠️ [SPLASH] Sin sesión activa - Redirigiendo a /login');
          Get.offAllNamed(AppRoutes.loginPage);
        }
      });
    } catch (e, stack) {
      print('❌ [SPLASH] Error verificando sesión: $e');
      print('Stack: $stack');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.loginPage);
      });
    } finally {
      isCheckingSession.value = false;
    }
  }

  /// Almacena de forma asíncrona los datos de autenticación en GetStorage.
  Future<void> _storeAuthData(String userId, int loginType) async {
    await GetStorage().write("loginUserId", userId);
    await GetStorage().write("loginType", loginType);
    print('✅ [SPLASH] Datos de autenticación almacenados: userId=$userId, loginType=$loginType');
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      // ✅ CORRECCIÓN: La RPC espera dos parámetros (p_user_id, p_viewer_id)
      final response = await local.SupabaseClient.rpc(
        'obtener_perfil_completo',
        params: {
          'p_user_id': uid,
          'p_viewer_id': uid, // El viewer es el mismo usuario (perfil propio)
        },
      );
      if (response != null) {
        print('✅ [SPLASH] Perfil cargado: ${response['username']}');
      }
    } catch (e) {
      print('⚠️ [SPLASH] Error cargando perfil: $e');
    }
  }

  Future<void> forceLogout() async {
    try {
      final authService = Get.find<AuthService>();
      await authService.signOut();
      // ✅ Reutilizar helper para limpiar datos de autenticación
      await _storeAuthData('', 0);
      Get.offAllNamed(AppRoutes.loginPage);
      print('✅ [SPLASH] Logout completado');
    } catch (e) {
      print('❌ [SPLASH] Error en logout: $e');
    }
  }
}