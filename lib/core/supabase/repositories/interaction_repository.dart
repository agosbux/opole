// lib/core/supabase/repositories/interaction_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class LikeResult {
  final bool isLiked;
  final int likesCount;
  const LikeResult({required this.isLiked, required this.likesCount});
}

class InteractionRepository {
  final SupabaseClient _client;
  InteractionRepository(this._client);

  Future<LikeResult> toggleLike(String reelId) async {
    // ✅ Ya NO enviamos user_id. Supabase lo extrae del JWT automáticamente.
    final isLiked = await _client.rpc('toggle_like', params: {
      'p_reel_id': reelId,
    }) as bool;

    final res = await _client
        .from('reels')
        .select('like_count')
        .eq('id', reelId)
        .single();

    return LikeResult(
      isLiked: isLiked,
      likesCount: res['like_count'] as int,
    );
  }

  Future<String> sendLoQuiero(String reelId) async {
    return await _client.rpc('dar_lo_quiero', params: {
      'p_reel_id': reelId,
    }) as String;
  }

  Future<bool> reportReel(String reelId, String reason, {String? details, String? ip}) async {
    return await _client.rpc('denunciar_reel', params: {
      'p_reel_id': reelId,
      'p_motivo': reason,
      'p_detalles': details ?? '',
      'p_ip': ip,
    }) as bool;
  }
}