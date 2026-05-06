import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:opole/custom/custom_dot_indicator.dart';
import 'package:opole/main.dart';
import 'package:opole/pages/profile_page/controller/profile_controller.dart';
import 'package:opole/routes/app_routes.dart';
import 'package:opole/ui/preview_network_image_ui.dart';
import 'package:opole/utils/asset.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/utils.dart';

class PreviewImageUi extends StatefulWidget {
  const PreviewImageUi({ // AÃ±adido const aquÃ­
    super.key,
    this.id,
    required this.name,
    required this.userName,
    required this.userImage,
    required this.images,
    this.caption,
    this.selectedIndex,
  });

  final String? id;
  final String name;
  final String userName;
  final String userImage;
  final String? caption; // CAMBIO: Ahora es final (Arregla el warning principal)
  final List images;
  final int? selectedIndex;

  @override
  State<PreviewImageUi> createState() => _PreviewImageUiState();
}

class _PreviewImageUiState extends State<PreviewImageUi> {
  static RxInt currentIndex = 0.obs;

  final profileController = Get.find<ProfileController>();

  @override
  void initState() {
    // Inicializar el Ã­ndice si se pasa por argumentos
    if (widget.selectedIndex != null) {
      currentIndex.value = widget.selectedIndex!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(
      const Duration(milliseconds: 200),
      () {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            systemNavigationBarColor: AppColor.black,
            statusBarColor: AppColor.black,
            statusBarBrightness: Brightness.light,
          ),
        );
      },
    );
    return Scaffold(
      backgroundColor: AppColor.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColor.black,
          surfaceTintColor: AppColor.transparent,
          shadowColor: AppColor.black.withValues(alpha: 0.4), // Actualizado a withValues
          flexibleSpace: SafeArea(
            bottom: false,
            child: Container(
              color: AppColor.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: const BoxDecoration(
                          color: AppColor.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Image.asset(AppAsset.icBack, color: AppColor.white, width: 25)),
                      ),
                    ),
                    const Spacer(),
                    Visibility(
                      visible: widget.id != null,
                      child: GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.editPostPage, arguments: {
                            "images": widget.images,
                            "isEdit": true,
                            "caption": widget.caption ?? "",
                            "postId": widget.id
                          });
                        },
                        child: BlurryContainer(
                          height: 38,
                          width: 38,
                          padding: EdgeInsets.zero,
                          color: AppColor.white.withValues(alpha: 0.2), // Actualizado
                          blur: 5,
                          borderRadius: BorderRadius.circular(100),
                          child: Center(
                            child: Image.asset(
                              AppAsset.icEditPen,
                              color: AppColor.white,
                              width: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    15.width,
                    Visibility(
                      visible: widget.id != null,
                      child: GestureDetector(
                        onTap: () {
                          profileController.onClickDeletePost(postId: widget.id ?? "");
                        },
                        child: BlurryContainer(
                          height: 38,
                          width: 38,
                          padding: EdgeInsets.zero,
                          color: AppColor.white.withValues(alpha: 0.2), // Actualizado
                          blur: 5,
                          borderRadius: BorderRadius.circular(100),
                          child: Center(
                            child: Image.asset(
                              AppAsset.icDelete,
                              color: AppColor.colorRedContainer,
                              width: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    15.width,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => Get.back(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: Get.height,
              width: Get.width,
              child: PageView.builder(
                itemCount: widget.images.length,
                controller: PageController(initialPage: currentIndex.value),
                onPageChanged: (value) => currentIndex.value = value,
                itemBuilder: (context, index) => Stack(
                  alignment: Alignment.center,
                  children: [
                    PreviewNetworkImageUi(image: widget.images[index]),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: Get.height / 6,
                        width: Get.width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColor.transparent, AppColor.black.withValues(alpha: 0.8)], // Actualizado
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              child: Visibility(
                visible: widget.images.length > 1,
                child: Obx(() => CustomDotIndicator(index: currentIndex.value, length: widget.images.length)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

