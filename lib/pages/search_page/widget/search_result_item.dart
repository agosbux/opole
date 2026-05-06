import 'package:flutter/material.dart';
import 'package:opole/pages/reels_page/model/fetch_reels_model.dart' as reels;  // <-- IMPORTAR CON ALIAS
import 'package:opole/ui/preview_network_image_ui.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/font_style.dart';

class SearchResultItem extends StatelessWidget {
  final reels.Data reel;  // <-- CORREGIDO: usar el alias
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.reel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.colorBorderGrey),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: AppColor.colorGreyBg,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PreviewNetworkImageUi(image: reel.videoImage ?? ''),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              AppAsset.icView,
                              width: 12,
                              color: AppColor.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${reel.totalLikes ?? 0}',
                              style: AppFontStyle.styleW500(AppColor.white, 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reel.caption ?? 'Sin tÃ­tulo',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFontStyle.styleW600(AppColor.black, 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          width: 20,
                          height: 20,
                          color: AppColor.colorGreyBg,
                          child: PreviewNetworkImageUi(image: reel.userImage ?? ''),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reel.name ?? 'Usuario',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFontStyle.styleW400(AppColor.colorTextGrey, 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (reel.hashTag != null && reel.hashTag!.isNotEmpty)
                    Text(
                      reel.hashTag!.take(2).join(' Â· '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFontStyle.styleW400(AppColor.colorTextGrey, 10),
                    ),
                ],
              ),
            ),
            
            // Icono
            Image.asset(
              AppAsset.icPlay,
              width: 24,
              color: AppColor.primary,
            ),
          ],
        ),
      ),
    );
  }
}

