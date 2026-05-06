import 'package:get_storage/get_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:opole/utils/api.dart';
import 'package:opole/utils/utils.dart';

class PreviewNetworkImageUi extends StatelessWidget {
  const PreviewNetworkImageUi({
    super.key,
    this.image,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
  });

  final String? image;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (image == null || image!.isEmpty) {
      return placeholder ?? const Offstage();
    }

    final String fullUrl = Api.baseUrl + image!;

    // Verificar si la URL ya fue verificada y cacheada en GetStorage
    final cached = GetStorage().read(fullUrl);
    if (cached != null && cached is String) {
      return CachedNetworkImage(
        imageUrl: cached,
        fit: fit,
        placeholder: (context, url) => placeholder ?? const Offstage(),
        errorWidget: (context, url, error) =>
            errorWidget ?? placeholder ?? const Offstage(),
      );
    }

    // Verificar existencia de la imagen antes de mostrarla
    return FutureBuilder<bool>(
      future: _checkAndCacheImage(fullUrl),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ?? const Offstage();
        } else if (snapshot.hasError || snapshot.data != true) {
          return errorWidget ?? placeholder ?? const Offstage();
        } else {
          return CachedNetworkImage(
            imageUrl: fullUrl,
            fit: fit,
            placeholder: (context, url) => placeholder ?? const Offstage(),
            errorWidget: (context, url, error) =>
                errorWidget ?? placeholder ?? const Offstage(),
          );
        }
      },
    );
  }
}

/// Verifica si la imagen existe y la guarda en GetStorage si es exitoso.
Future<bool> _checkAndCacheImage(String imageUrl) async {
  try {
    final response = await http.head(Uri.parse(imageUrl));
    final exists = response.statusCode == 200;
    if (exists) {
      await GetStorage().write(imageUrl, imageUrl);
    }
    return exists;
  } catch (e) {
    Utils.showLog('Check Profile Image Failed !! => $e');
    return false;
  }
}