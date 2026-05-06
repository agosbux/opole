// lib/pages/bottom_bar_page/view/bottom_bar_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/pages/bottom_bar_page/controller/bottom_bar_controller.dart';
import 'package:opole/pages/feed_page/view/feed_view.dart';
import 'package:opole/pages/search_page/view/search_view.dart';
import 'package:opole/pages/notifications/view/notifications_view.dart';
import 'package:opole/pages/profile_page/profile_view.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/constant.dart';
import 'package:badges/badges.dart' as badges;
import 'package:opole/controllers/session_controller.dart';

class BottomBarView extends GetView<BottomBarController> {
  const BottomBarView({Key? key}) : super(key: key);

  // Color naranja personalizado para la barra
  static const Color orangeAccent = Color(0xFFFF6B00);

  @override
  Widget build(BuildContext context) {
    Get.log('🎨 [BOTTOM BAR] Build - índice actual: ${controller.currentIndex.value}');

    // Obtener el userId de la sesión para el perfil propio
    final session = Get.find<SessionController>();
    final currentUserId = session.uid.isNotEmpty ? session.uid : '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: [
          // 0: Feed
          _KeepAliveWrapper(child: FeedView()),

          // 1: Buscar
          SearchView(),

          // 2: Publicar (placeholder)
          _buildBrandedPlaceholder('Publicar', Icons.add_circle_outline),

          // 3: Notificaciones
          _KeepAliveWrapper(child: NotificationsView()),

          // 4: Perfil
          _KeepAliveWrapper(
            child: currentUserId.isNotEmpty
                ? ProfileView(userId: currentUserId)
                : _buildLoginPlaceholder(),
          ),
        ],
      )),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return GetBuilder<BottomBarController>(
      id: "onChangeBottomBar",
      builder: (logic) {
        return Container(
          height: AppConstant.bottomBarSize.toDouble(),
          decoration: const BoxDecoration(
            color: Colors.black,
            border: Border(
              top: BorderSide(
                color: Colors.white12,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Índice 0: Feed
              _buildTabIcon(
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
              ),
              // Índice 1: Buscar
              _buildTabIcon(
                index: 1,
                icon: Icons.search_outlined,
                selectedIcon: Icons.search,
              ),
              // Índice 2: Crear
              _buildTabIcon(
                index: 2,
                icon: Icons.add_box_outlined,
                selectedIcon: Icons.add_box,
              ),
              // Índice 3: Notificaciones
              _buildTabIcon(
                index: 3,
                icon: Icons.notifications_outlined,
                selectedIcon: Icons.notifications,
              ),
              // Índice 4: Perfil
              _buildTabIcon(
                index: 4,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabIcon({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Get.log('👆 [TAB] Tocaste: índice $index');
          controller.changeTab(index);
        },
        child: InkWell(
          onTap: () => controller.changeTab(index),
          splashColor: orangeAccent.withOpacity(0.2),
          highlightColor: orangeAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: AppColor.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() {
                  final isSelected = controller.currentIndex.value == index;
                  final iconWidget = _buildIconWithAnimation(
                    icon: isSelected ? selectedIcon : icon,
                    isSelected: isSelected,
                  );

                  // Badge solo para el tab de notificaciones (índice 3)
                  if (index == 3) {
                    return badges.Badge(
                      showBadge: controller.hasUnreadNotifications,
                      badgeContent: Text(
                        controller.notificationBadgeText,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: Colors.white,
                        padding: EdgeInsets.all(6),
                      ),
                      child: iconWidget,
                    );
                  }
                  return iconWidget;
                }),
                const SizedBox(height: 4),
                // Indicador de pestaña activa (línea blanca)
                Obx(() {
                  final isSelected = controller.currentIndex.value == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 30 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconWithAnimation({
    required IconData icon,
    required bool isSelected,
  }) {
    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Icon(
        icon,
        size: 28,
        color: isSelected ? orangeAccent : Colors.white70,
      ),
    );
  }

  Widget _buildBrandedPlaceholder(String label, IconData icon) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: orangeAccent.withOpacity(0.3)),
              ),
              child: Icon(icon, size: 48, color: orangeAccent),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Próximamente',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: orangeAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: orangeAccent.withOpacity(0.5)),
              ),
              child: const Text(
                '🚀 En desarrollo',
                style: TextStyle(
                  color: orangeAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Inicia sesión para ver tu perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accede a todas las funciones de Opole',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Get.toNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper para mantener el estado de las pestañas
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}