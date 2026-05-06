// lib/core/feed/feed_interaction_bridge.dart
// ===================================================================
// FEED INTERACTION BRIDGE v2.2 – LO_QUIERO & SHARE DEEP LINK FIX
// ===================================================================
// ✅ Puente de interacciones sociales
// ✅ Usa contextProvider dinámico (NO stale)
// ✅ Optimistic UI + rollback seguro (toggleLike)
// ✅ Interface abstracta para testing crítico
// ✅ FIX: registerInterest maneja éxito, analytics y errores sin romper UI
// ✅ FIX: shareReel incluye deep link al reel + fallback robusto
// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/core/supabase/supabase_api.dart';
import 'package:opole/core/utils/analytics.dart';
import 'package:postgrest/postgrest.dart';
import 'package:share_plus/share_plus.dart';

import 'feed_execution_context.dart';
import 'feed_state_updater.dart';

abstract class IInteractionBridge {
  Future<void> toggleLike(String reelId);
  Future<void> registerInterest(String reelId);
  Future<void> reportReel(String reelId, String motivo, {String? detalles});
  Future<void> shareReel(String reelId);
  void openUserProfile(String userId);
  void onCategorySelected(String category);
}

class FeedInteractionBridge implements IInteractionBridge {
  FeedInteractionBridge({
    required this.contextProvider,
    required this.stateUpdater,
    SupabaseApi? supabaseApi,
  }) : _supabaseApi = supabaseApi ?? SupabaseApi.instance;

  final FeedExecutionContext Function() contextProvider;
  final FeedStateUpdater stateUpdater;
  final SupabaseApi _supabaseApi;

  @override
  Future<void> toggleLike(String reelId) async {
    final ctx = contextProvider();
    final userId = ctx.userId;
    if (userId == null) return;

    final currentReel = stateUpdater.getReelById(reelId);
    if (currentReel == null) return;

    final currentLiked = currentReel.isLiked ?? false;
    final currentCount = currentReel.likesCount ?? 0;
    final expectedGen = ctx.generation;

    // 🔹 Optimistic UI inmediata
    stateUpdater.updateItem(
      reelId: reelId,
      expectedGeneration: expectedGen,
      transformer: (r) => r.copyWith(
        isLiked: !currentLiked,
        likesCount: currentLiked ? (currentCount - 1).clamp(0, 999999) : currentCount + 1,
      ),
    );

    try {
      final success = await _supabaseApi.toggleLike(reelId, userId);
      // 🔹 Rollback si falla o cambió la generación
      if (!success || ctx.generation != expectedGen) {
        if (ctx.generation == expectedGen) {
          stateUpdater.updateItem(
            reelId: reelId,
            expectedGeneration: expectedGen,
            transformer: (r) => r.copyWith(isLiked: currentLiked, likesCount: currentCount),
          );
        }
      }
    } catch (e) {
      if (ctx.generation == expectedGen) {
        stateUpdater.updateItem(
          reelId: reelId,
          expectedGeneration: expectedGen,
          transformer: (r) => r.copyWith(isLiked: currentLiked, likesCount: currentCount),
        );
      }
    }
  }

  @override
  Future<void> registerInterest(String reelId) async {
    final ctx = contextProvider();
    final userId = ctx.userId;
    if (userId == null) return;

    try {
      await _supabaseApi.darLoQuiero(reelId, userId);

      // ✅ Success logging & analytics
      if (kDebugMode) Get.log('✅ [LO_QUIERO] Registrado correctamente: reel=$reelId');
      Analytics.logEvent('lo_quiero_sent', parameters: {'reel_id': reelId});

    } on PostgrestException catch (e) {
      final msg = (e.message ?? '').toUpperCase();
      
      // 🔹 Caso especial: ya registrado. No es error, retornar silenciosamente.
      if (msg.contains('YA_DIO_LO_QUIERO')) {
        if (kDebugMode) Get.log('ℹ️ [LO_QUIERO] Ya registrado previamente: reel=$reelId');
        Analytics.logEvent('lo_quiero_already_sent', parameters: {'reel_id': reelId});
        return;
      }

      String mensaje = 'Error al registrar interés';
      if (msg.contains('LIMITE_DIARIO')) mensaje = 'Límite diario alcanzado';
      else if (msg.contains('REEL_NO_EXISTE')) mensaje = 'Reel no disponible';

      if (kDebugMode) Get.log('⚠️ [LO_QUIERO] $mensaje: ${e.message}');
      rethrow; // Dejar que la UI maneje el error si es necesario
    } catch (e) {
      if (kDebugMode) Get.log('❌ [LO_QUIERO] Error inesperado: $e');
      rethrow;
    }
  }

  @override
  Future<void> reportReel(String reelId, String motivo, {String? detalles}) async {
    final ctx = contextProvider();
    final userId = ctx.userId;
    if (userId == null) return;

    try {
      final success = await _supabaseApi.reportReel(
        reelId: reelId, motivo: motivo, detalles: detalles, userId: userId);
      if (success) {
        Analytics.logEvent('reel_reported', parameters: {'reel_id': reelId, 'motivo': motivo});
        stateUpdater.removeItem(reelId, expectedGeneration: ctx.generation);
        if (kDebugMode) Get.snackbar('Gracias', 'Tu denuncia fue enviada');
      }
    } catch (e) {
      if (kDebugMode) Get.snackbar('Error', 'No se pudo enviar la denuncia');
    }
  }

  // 🔥 FIX: shareReel con deep link + fallback robusto
  @override
  Future<void> shareReel(String reelId) async {
    final ctx = contextProvider();
    final userId = ctx.userId;
    if (userId == null) return;

    final reel = stateUpdater.getReelById(reelId);

    try {
      // 1️⃣ Registrar evento en backend
      await _supabaseApi.registrarCompartido(reelId, userId);

      // 2️⃣ Construir deep link a tu app
      final deepLink = 'opole://reel/$reelId';

      // 3️⃣ Construir mensaje de share
      final title = reel?.title?.isNotEmpty == true ? reel!.title! : 'Reel en Opole';
      final description = reel?.description?.isNotEmpty == true 
          ? '\n\n${reel!.description}' 
          : '';
      final linkText = '\n\n🔗 Ver en Opole: $deepLink';

      // 4️⃣ Share nativo
      await Share.share(
        '$title$description$linkText',
        subject: title,
      );

      // 5️⃣ Analytics
      Analytics.logEvent('reel_shared', parameters: {'reel_id': reelId, 'has_link': true});

    } catch (e) {
      // Fallback seguro si falla el share principal
      try {
        await Share.share('Mirá este reel en Opole: opole://reel/$reelId');
      } catch (_) {
        if (kDebugMode) debugPrint('❌ [SHARE] Error al abrir menú de compartir');
      }
    }
  }

  @override
  void openUserProfile(String userId) {
    if (userId.isEmpty) return;
    Analytics.logEvent('profile_viewed', parameters: {'target_user_id': userId, 'source': 'feed'});
    Get.toNamed('/profile', arguments: {'userId': userId, 'isOtherUser': true});
  }

  @override
  void onCategorySelected(String category) {
    Analytics.logEvent('category_tapped', parameters: {'category': category});
    Get.toNamed('/search', arguments: {'category': category.toLowerCase()});
  }

  void dispose() {}
}