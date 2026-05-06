import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/profile_controller.dart';
import '../widget/reels_tab_view.dart';
import '../widget/feeds_tab_view.dart';
import '../widget/collections_tab_view.dart';
import '../../../shimmer/profile_shimmer_ui.dart';
import '../../../ui/preview_network_image_ui.dart';
import '../../../utils/color.dart';
import '../../../utils/font_style.dart';
import '../../../utils/asset.dart';
import '../../../utils/utils.dart';
import '../../../controllers/session_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Regresar al home si se intenta salir
        // Get.find<BottomBarController>().onChangeBottomBar(0);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColor.white,
          automaticallyImplyLeading: false,
          shadowColor: AppColor.black.withValues(alpha: 0.4),
          surfaceTintColor: AppColor.transparent,
          flexibleSpace: Center(child: ProfileAppBarUi()), // âœ… CORREGIDO: quitado const
        ),
        body: RefreshIndicator(
          onRefresh: controller.refreshData,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColor.white,
                  expandedHeight: 650,
                  surfaceTintColor: AppColor.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Obx(() {
                      if (controller.isLoading.value) {
                        return const ProfileShimmerUi();
                      }

                      final user = controller.user.value;
                      if (user == null) return const SizedBox();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Foto de perfil
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColor.primaryLinearGradient,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  // Navegar a ediciÃ³n de perfil
                                },
                                child: Container(
                                  height: 124,
                                  width: 124,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColor.white, width: 1.5),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        height: 124,
                                        width: 124,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: const BoxDecoration(shape: BoxShape.circle),
                                        child: Image.asset(AppAsset.icProfilePlaceHolder, fit: BoxFit.cover),
                                      ),
                                      PreviewNetworkImageUi(image: controller.photoUrl),
                                      Container(
                                        height: 36,
                                        width: 36,
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: AppColor.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColor.colorBorder, width: 1.5),
                                        ),
                                        alignment: Alignment.center,
                                        child: Image.asset(AppAsset.icEdit),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            10.height,

                            // Nombre
                            Text(
                              controller.name,
                              style: AppFontStyle.styleW700(AppColor.black, 18),
                            ),

                            // Username
                            Text(
                              '@${controller.username}',
                              style: AppFontStyle.styleW400(AppColor.colorGreyHasTagText, 13),
                            ),
                            10.height,

                            // PaÃ­s y gÃ©nero
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${controller.country} â€¢ ${controller.zone}',
                                  style: AppFontStyle.styleW400(AppColor.coloGreyText, 13),
                                ),
                                if (controller.gender != null) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColor.secondary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          controller.gender!.toLowerCase() == 'male'
                                              ? AppAsset.icMale
                                              : AppAsset.icFemale,
                                          width: 14,
                                          color: AppColor.white,
                                        ),
                                        5.width,
                                        Text(
                                          controller.gender!.toLowerCase() == 'male' ? 'Hombre' : 'Mujer',
                                          style: AppFontStyle.styleW600(AppColor.white, 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // EstadÃ­sticas
                            Container(
                              height: 75,
                              width: Get.width,
                              color: AppColor.white,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${controller.totalReels.value}',
                                          style: AppFontStyle.styleW700(AppColor.black, 18),
                                        ),
                                        2.height,
                                        Text(
                                          'Reels',
                                          style: AppFontStyle.styleW400(AppColor.coloGreyText, 12), // âœ… CORREGIDO: quitado const
                                        ),
                                      ],
                                    ),
                                  ),
                                  VerticalDivider(
                                    indent: 20,
                                    endIndent: 20,
                                    thickness: 2,
                                    color: AppColor.coloGreyText.withValues(alpha: 0.2),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        // Navegar a "Los quiero dados"
                                      },
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${controller.loQuieroGiven}',
                                            style: AppFontStyle.styleW700(AppColor.black, 18),
                                          ),
                                          2.height,
                                          Text(
                                            'Los quiero',
                                            style: AppFontStyle.styleW400(AppColor.coloGreyText, 12), // âœ… CORREGIDO: quitado const
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  VerticalDivider(
                                    indent: 20,
                                    endIndent: 20,
                                    thickness: 2,
                                    color: AppColor.coloGreyText.withValues(alpha: 0.2),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        // Navegar a "Recibidos"
                                      },
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${controller.loQuieroReceived}',
                                            style: AppFontStyle.styleW700(AppColor.black, 18),
                                          ),
                                          2.height,
                                          Text(
                                            'Recibidos',
                                            style: AppFontStyle.styleW400(AppColor.coloGreyText, 12), // âœ… CORREGIDO: quitado const
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),

                            // Nivel actual
                            Container(
                              height: 80,
                              width: Get.width,
                              decoration: BoxDecoration(
                                gradient: AppColor.primaryLinearGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Nivel ${controller.level}',
                                      style: AppFontStyle.styleW700(AppColor.white, 28),
                                    ),
                                    Text(
                                      'Nivel actual',
                                      style: AppFontStyle.styleW400(AppColor.white, 14), // âœ… CORREGIDO: quitado const
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),

                            // SecciÃ³n de Boost
                            _buildBoostSection(),
                            const SizedBox(height: 5),

                            // Privacidad
                            _buildPrivacySection(),
                          ],
                        ),
                      );
                    }),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(75),
                    child: Container(
                      color: AppColor.white,
                      child: TabBar(
                        controller: controller.tabController,
                        labelColor: AppColor.colorTabBar,
                        labelStyle: AppFontStyle.styleW600(AppColor.black.withValues(alpha: 0.8), 13),
                        unselectedLabelColor: AppColor.colorUnselectedIcon,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorWeight: 2,
                        indicatorPadding: const EdgeInsets.only(top: 72, right: 10, left: 10),
                        indicator: const BoxDecoration(
                          gradient: AppColor.primaryLinearGradient,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        tabs: const [
                          Tab(icon: ImageIcon(AssetImage(AppAsset.icReels)), text: 'Reels'),
                          Tab(icon: ImageIcon(AssetImage(AppAsset.icFeeds)), text: 'Lo quiero'),
                          Tab(icon: ImageIcon(AssetImage(AppAsset.icCollections)), text: 'Notificaciones'),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: controller.tabController,
              children: const [
                ReelsTabView(),
                FeedsTabView(),
                CollectionsTabView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // SecciÃ³n de Boost
  Widget _buildBoostSection() {
    final session = Get.find<SessionController>();

    return Obx(() {
      final boostCount = session.availableBoost.value;
      final canClaim = session.canClaimDailyBoost;
      final timeRemaining = session.timeUntilNextDailyBoost;

      return Container(
        width: Get.width,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber[800], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Boost disponibles: $boostCount',
                  style: AppFontStyle.styleW700(AppColor.black, 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (canClaim)
              ElevatedButton(
                onPressed: () => session.claimDailyBoost(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Reclamar boost diario',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'PrÃ³ximo boost en: ${_formatDuration(timeRemaining)}',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Widget _buildPrivacySection() {
    return Obx(() {
      final user = controller.user.value;
      if (user == null) return const SizedBox();

      return Container(
        width: Get.width,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacidad de contacto',
              style: AppFontStyle.styleW600(AppColor.black, 16), // âœ… CORREGIDO: quitado const
            ),
            const SizedBox(height: 15),

            _buildSwitch(
              icon: Icons.phone,
              label: 'Mostrar telÃ©fono',
              value: user.showPhone,
              onChanged: (value) =>
                  Get.find<SessionController>().updatePrivacy(showPhone: value),
            ),

            const Divider(height: 20),

            _buildSwitch(
              icon: Icons.email,
              label: 'Mostrar email',
              value: user.showEmail,
              onChanged: (value) =>
                  Get.find<SessionController>().updatePrivacy(showEmail: value),
            ),

            const Divider(height: 20),

            _buildSwitch(
              icon: Icons.location_on,
              label: 'Mostrar ubicaciÃ³n',
              value: user.showLocation,
              onChanged: (value) =>
                  Get.find<SessionController>().updatePrivacy(showLocation: value),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSwitch({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: AppColor.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppFontStyle.styleW500(AppColor.black, 14), // âœ… CORREGIDO: quitado const
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColor.primary,
        ),
      ],
    );
  }
}

// Widget auxiliar para el AppBar (asumiendo que existe)
class ProfileAppBarUi extends StatelessWidget {
  const ProfileAppBarUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Perfil',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // Navegar a configuraciÃ³n
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
