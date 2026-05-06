// lib/pages/feed_page/viewmodel/reel_view_model.dart

// ===================================================================

// REEL VIEW MODEL - FASE 1 (PRODUCCIÓN)

// ===================================================================

// ✅ SOLO estado local del reel (likes por ahora)

// ✅ SIN GetX, SIN backend, SIN lógica de negocio

// ✅ ValueNotifier para updates granulares (evita rebuilds innecesarios)

// ✅ Lectura atómica en toggle (evita race conditions en spam tap)

// ===================================================================

import 'package:flutter/foundation.dart';

class ReelViewModel {

  final String reelId;

  /// Estado reactivo: ¿el usuario dio like?

  final ValueNotifier<bool> isLiked;

  /// Estado reactivo: contador de likes visible

  final ValueNotifier<int> likesCount;

  ReelViewModel({

    required this.reelId,

    required bool initialLiked,

    required int initialLikes,

  })  : isLiked = ValueNotifier<bool>(initialLiked),

        likesCount = ValueNotifier<int>(initialLikes);

  /// 🔹 Cambia el estado de like LOCALMENTE

  /// ⚠️ FASE 1: SIN llamada a backend. FASE 2: InteractionController se encargará.

  /// ✅ Lectura atómica: captura el valor ANTES de mutar para evitar inconsistencias

  void toggleLike() {

    isLiked.value = !isLiked.value;

    

    // 🔥 Snapshot atómico para consistencia en spam tap

    final current = likesCount.value;

    likesCount.value = isLiked.value

        ? current + 1

        : (current - 1).clamp(0, 999999);

  }

  /// 🔹 Para sincronización con servidor (FASE 2+)

  /// Útil cuando el backend confirma/rechaza una acción

  /// ⚠️ Solo llama si el valor es diferente para evitar rebuilds innecesarios

  void syncFromServer({bool? liked, int? count}) {

    if (liked != null && isLiked.value != liked) {

      isLiked.value = liked;

    }

    if (count != null && likesCount.value != count) {

      likesCount.value = count.clamp(0, 999999);

    }

  }

  /// 🔹 Limpieza obligatoria para evitar memory leaks

  void dispose() {

    isLiked.dispose();

    likesCount.dispose();

  }

  @override

  String toString() => 'ReelViewModel(reelId: $reelId, isLiked: ${isLiked.value}, likes: ${likesCount.value})';

}