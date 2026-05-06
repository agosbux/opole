// lib/core/supabase/repositories/user_content_profile_repository.dart
// ===================================================================
// USER CONTENT PROFILE REPOSITORY - FASE 4
// ===================================================================
// ✅ Persiste el perfil de preferencias en Supabase (jsonb)
// ✅ Carga inicial al arrancar el feed
// ✅ Sync diferido: solo cuando needsSync == true (máx 1 vez cada 5min)
// ✅ Fallback silencioso: si falla, el perfil en memoria sigue funcionando
// ===================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opole/core/engagement/user_content_profile.dart';

class UserContentProfileRepository {
  final SupabaseClient _client;

  UserContentProfileRepository(this._client);

  /// Carga el perfil guardado. Retorna perfil vacío si no existe aún.
  Future<UserContentProfile> load(String userId) async {
    try {
      final res = await _client
          .from('user_content_profiles')
          .select('profile_data')
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) {
        if (kDebugMode) print('📊 [PROFILE] No existe perfil previo para $userId, iniciando vacío');
        return UserContentProfile(userId: userId);
      }

      final profile = UserContentProfile.fromJson(
        res['profile_data'] as Map<String, dynamic>,
      );
      if (kDebugMode) print('📊 [PROFILE] Cargado: $profile');
      return profile;
    } catch (e) {
      if (kDebugMode) print('⚠️ [PROFILE] Error cargando perfil: $e — usando vacío');
      return UserContentProfile(userId: userId);
    }
  }

  /// Persiste el perfil. Llamar solo cuando profile.needsSync == true.
  Future<void> save(UserContentProfile profile) async {
    try {
      await _client.from('user_content_profiles').upsert({
        'user_id': profile.userId,
        'profile_data': profile.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      profile.markSynced();
      if (kDebugMode) print('✅ [PROFILE] Guardado: top=${profile.topInterests}');
    } catch (e) {
      if (kDebugMode) print('⚠️ [PROFILE] Error guardando perfil: $e');
      // No relanzar: el perfil en memoria sigue siendo válido
    }
  }
}