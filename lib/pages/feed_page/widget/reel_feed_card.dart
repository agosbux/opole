// lib/pages/feed_page/widget/reel_feed_card.dart
// ===================================================================
// REEL FEED CARD v1.1 - CACHEDNETWORKIMAGE OPTIMIZED
// ===================================================================
// ✅ Avatar con CachedNetworkImage widget (no Provider)
// ✅ useOldImageOnUrlChange: false + memCache 200x200
// ✅ Fallback seguro con ?? '' y CircleAvatar gris en error/placeholder
// ===================================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/core/feed/feed_item_model.dart';
import 'package:opole/core/supabase/models/reel_model.dart';
import 'package:opole/pages/feed_page/widget/reel_card_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReelFeedCard extends StatelessWidget {
  final FeedItem feedItem;
  final int index;
  final double mediaHeight;
  final VoidCallback? onQuestions;
  final VoidCallback? onLoQuiero;
  final VoidCallback? onLike;
  final void Function(String hashtag)? onHashtagSelected;
  final VoidCallback? onShare;

  ReelModel? get reel => feedItem is ReelFeedItem ? (feedItem as ReelFeedItem).reel : null;

  const ReelFeedCard({
    super.key,
    required this.feedItem,
    required this.index,
    required this.mediaHeight,
    this.onQuestions,
    this.onLoQuiero,
    this.onLike,
    this.onHashtagSelected,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final reel = this.reel;
    if (reel == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎬 Media section (altura fija para consistencia)
          SizedBox(
            height: mediaHeight,
            child: ReelCardWidget(
              feedItem: feedItem,
              index: index,
              viewType: ReelViewType.feed,
              screenHeight: mediaHeight,
              onQuestions: onQuestions,
              onLoQuiero: onLoQuiero,
              onLike: onLike,
              onHashtagSelected: onHashtagSelected,
              onShare: onShare,
              onWatchTimeUpdate: null,
              onVideoStart: null,
              onInteraction: null,
              onComplete: null,
              questionsCount: 0,
            ),
          ),

          // 📝 Info section (scrollable si el contenido es largo)
          _InfoSection(reel: reel, onHashtagSelected: onHashtagSelected),
        ],
      ),
    );
  }
}

// ===================================================================
// INFO SECTION - Descripción, precio, usuario, hashtags
// ===================================================================
class _InfoSection extends StatelessWidget {
  final ReelModel reel;
  final void Function(String hashtag)? onHashtagSelected;

  const _InfoSection({required this.reel, this.onHashtagSelected});

  String _translateCondition(String c) => switch (c?.toUpperCase()) {
    'NEW' => 'NUEVO',
    'USED' => 'USADO',
    _ => c ?? '',
  };

  Color _getConditionColor(String c) => switch (c.toUpperCase()) {
    'NEW' => Colors.lightGreenAccent,
    'USED' => Colors.orangeAccent,
    _ => Colors.white70,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 Usuario + condición
          Row(
            children: [
              // ✅ Avatar optimizado con CachedNetworkImage widget
              CachedNetworkImage(
                imageUrl: reel.userPhotoUrl ?? '',
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  radius: 16,
                  backgroundImage: imageProvider,
                  backgroundColor: Colors.grey[800],
                ),
                fit: BoxFit.cover,
                memCacheWidth: 200,
                memCacheHeight: 200,
                useOldImageOnUrlChange: false,
                placeholder: (context, url) => CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 18, color: Colors.white70),
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 18, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reel.userUsername != null ? '@${reel.userUsername}' : 'Usuario',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (reel.condition?.isNotEmpty == true)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _translateCondition(reel.condition!),
                          style: TextStyle(
                            color: _getConditionColor(reel.condition!),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // 📌 Título + precio
          const SizedBox(height: 10),
          if (reel.title?.isNotEmpty == true)
            Text(
              reel.title!,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (reel.price != null && reel.price! > 0) ...[
            const SizedBox(height: 4),
            Text(
              '\$ ${reel.price!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],

          // 📝 Descripción (expandible)
          if (reel.description?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              reel.description!,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // 🏷️ Hashtags
          if (reel.hashtags?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: reel.hashtags!.take(5).map((tag) => GestureDetector(
                onTap: () => onHashtagSelected?.call(tag),
                child: Text(
                  '#$tag',
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 13),
                ),
              )).toList(),
            ),
          ],

          // 📍 Ubicación (opcional)
          if (reel.locality?.isNotEmpty == true || reel.province?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  [reel.locality, reel.province].where((e) => e?.isNotEmpty == true).join(', '),
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}