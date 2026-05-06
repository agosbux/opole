// lib/pages/profile_page/profile_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_controller.dart';
import 'profile_model.dart'; // ✅ Import agregado para tipado seguro
import '../../shimmer/profile_shimmer_ui.dart';
import '../../utils/color.dart';
import '../../ui/preview_network_image_ui.dart';

class ProfileView extends GetView<ProfileController> {
  final String userId;

  const ProfileView({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(color: AppColor.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColor.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.black),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const ProfileShimmerUi();
          }

          final profile = controller.profile.value;
          if (profile == null) {
            return const Center(
              child: Text(
                'Usuario no encontrado',
                style: TextStyle(color: AppColor.black),
              ),
            );
          }

          final isOwner = profile.isOwner;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera: foto + @username + nombre
                _buildProfileHeader(profile, isOwner),
                const SizedBox(height: 24),

                // Métricas: Reels, Like, Lo quiero, Intenciones
                _buildMetricsRow(profile),
                const SizedBox(height: 24),

                // Nivel y barra de progreso
                _buildLevelSection(profile),
                const SizedBox(height: 24),

                // Botones principales (solo owner)
                if (isOwner) ...[
                  _buildPrimaryButton(
                    text: 'Editar perfil',
                    onPressed: () => controller.goToEditProfile(),
                    icon: Icons.edit_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildPrimaryButton(
                    text: 'Reclamar Boost Diario',
                    onPressed: controller.claimDailyBoost,
                    icon: Icons.rocket_launch_outlined,
                    isLoading: controller.isBoostClaiming,
                  ),
                  const SizedBox(height: 12),
                  _buildPrimaryButton(
                    text: 'Mis Reels',
                    onPressed: () => Get.toNamed('/my-reels'),
                    icon: Icons.video_library_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildPrimaryButton(
                    text: 'Configuración de la cuenta',
                    onPressed: () => Get.toNamed('/account-settings'),
                    icon: Icons.settings_outlined,
                  ),
                  const SizedBox(height: 24),
                ],

                // Botones legales (siempre visibles)
                _buildLegalButtonsRow(),
                const SizedBox(height: 24),

                // Privacidad de contacto (solo owner)
                if (isOwner) ...[
                  _buildContactPrivacySection(profile, context),
                  const SizedBox(height: 24),
                ],

                // Métricas personales (solo owner)
                if (isOwner) ...[
                  _buildPersonalStats(profile),
                  const SizedBox(height: 24),
                ],

                // Botón salir (solo owner)
                if (isOwner) _buildLogoutButton(),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 1. CABECERA DE PERFIL (FOTO + @USUARIO) - ✅ FIX: Tipado seguro + loading overlay
  // ----------------------------------------------------------------------
  Widget _buildProfileHeader(ProfileModel profile, bool isOwner) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Foto de perfil con selector de imagen (solo owner)
        GestureDetector(
          onTap: isOwner ? () => _showImagePickerOptions() : null,
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.colorOrange, width: 2.5),
                ),
                child: ClipOval(
                  child: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                      ? PreviewNetworkImageUi(
                          image: profile.photoUrl!, // ✅ Recibe URL con cache-buster automáticamente
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColor.colorGreyBg,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: AppColor.colorTextGrey,
                          ),
                        ),
                ),
              ),
              // ✅ Overlay de loading durante upload (UX feedback inmediato)
              if (isOwner && controller.isUploadingImage.value)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColor.white,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColor.colorOrange),
                      ),
                    ),
                  ),
                ),
              if (isOwner && !controller.isUploadingImage.value)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColor.colorOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColor.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColor.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Columna de texto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '@${profile.username}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColor.black,
                      ),
                    ),
                  ),
                  if (isOwner && !profile.profileCompleted) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showEditUsernameDialog(),
                      child: Icon(
                        Icons.edit,
                        size: 18,
                        color: AppColor.colorOrange,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              if (profile.fullName != null && profile.fullName!.isNotEmpty)
                Text(
                  profile.fullName!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColor.colorDarkGrey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // 2. MÉTRICAS (REELS, LIKE, LO QUIERO, INTENCIONES) - ✅ FIX: Tipado seguro
  // ----------------------------------------------------------------------
  Widget _buildMetricsRow(ProfileModel profile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColor.colorLightGreyBgContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _metricItem(
            icon: Icons.video_library_outlined,
            label: 'Reels',
            value: profile.reelsActivos,
            color: AppColor.colorOrange,
          ),
          _metricItem(
            icon: Icons.favorite_border,
            label: 'Like',
            value: profile.loQuieroReceived,
            color: AppColor.colorButtonPink,
          ),
          _metricItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Lo quiero',
            value: profile.loQuieroHoy,
            color: AppColor.colorDarkOrange,
          ),
          _metricItem(
            icon: Icons.star_border,
            label: 'Intenciones',
            value: profile.matchesCompletados,
            color: AppColor.colorWorkingOrange,
          ),
        ],
      ),
    );
  }

  Widget _metricItem({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColor.black,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColor.colorDarkGrey),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // 3. NIVEL Y BARRA DE PROGRESO - ✅ FIX: Tipado seguro
  // ----------------------------------------------------------------------
  Widget _buildLevelSection(ProfileModel profile) {
    final int currentLevel = profile.level;
    final int currentXp = profile.xp;
    final Map<String, dynamic>? progreso = profile.progresoSiguienteNivel;
    final int xpNeeded = progreso != null ? (progreso['xp_requerido'] ?? 100) : 100;
    final double progress = (currentXp / xpNeeded).clamp(0.0, 1.0);
    final int percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nivel actual (caja naranja)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColor.colorOrange,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Nivel $currentLevel',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColor.white,
                ),
              ),
              const Text(
                'Nivel actual',
                style: TextStyle(fontSize: 14, color: AppColor.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Barra de progreso con ícono
        Row(
          children: [
            const Icon(Icons.trending_up, color: AppColor.colorOrange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColor.colorLightGreyBgContainer,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColor.colorOrange),
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColor.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'XP: $currentXp / $xpNeeded para nivel ${currentLevel + 1}',
          style: const TextStyle(fontSize: 12, color: AppColor.colorDarkGrey),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // 4. BOTONES PRINCIPALES (NARANJA) - ✅ SIN CAMBIOS (ya tenía fix de reactividad)
  // ----------------------------------------------------------------------
  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    required IconData icon,
    RxBool? isLoading,
  }) {
    if (isLoading != null) {
      return Obx(() => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: isLoading.value ? null : onPressed,
          icon: isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColor.white,
                  ),
                )
              : Icon(icon, color: AppColor.white),
          label: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.colorOrange,
            foregroundColor: AppColor.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ));
    }
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColor.white),
        label: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.colorOrange,
          foregroundColor: AppColor.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 5. BOTONES LEGALES (TÉRMINOS / PRIVACIDAD) - ✅ SIN CAMBIOS
  // ----------------------------------------------------------------------
  Widget _buildLegalButtonsRow() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Get.toNamed('/terms'),
            style: TextButton.styleFrom(
              foregroundColor: AppColor.colorDarkGrey,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColor.colorBorderGrey),
              ),
            ),
            child: const Text('Términos y Condiciones'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            onPressed: () => Get.toNamed('/privacy-law'),
            style: TextButton.styleFrom(
              foregroundColor: AppColor.colorDarkGrey,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColor.colorBorderGrey),
              ),
            ),
            child: const Text('Privacidad Ley 25.326'),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // 6. PRIVACIDAD DE CONTACTO (CON ADVERTENCIAS) - ✅ FIX: Tipado seguro
  // ----------------------------------------------------------------------
  Widget _buildContactPrivacySection(ProfileModel profile, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.colorLightGreyBgContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacidad de contacto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColor.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildPrivacySwitch(
            title: 'Mostrar teléfono',
            value: profile.showPhone,
            onChanged: (newValue) => _handlePrivacyToggle(
              context,
              newValue,
              () => controller.updatePrivacy(showPhone: newValue),
            ),
          ),
          _buildPrivacySwitch(
            title: 'Mostrar email',
            value: profile.showEmail,
            onChanged: (newValue) => _handlePrivacyToggle(
              context,
              newValue,
              () => controller.updatePrivacy(showEmail: newValue),
            ),
          ),
          _buildPrivacySwitch(
            title: 'Mostrar nombre completo',
            value: profile.showFullName,
            onChanged: (newValue) => _handlePrivacyToggle(
              context,
              newValue,
              () => controller.updatePrivacy(showFullName: newValue),
            ),
          ),
          _buildPrivacySwitch(
            title: 'Mostrar ubicación',
            value: profile.showLocation,
            onChanged: (newValue) => _handlePrivacyToggle(
              context,
              newValue,
              () => controller.updatePrivacy(showLocation: newValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColor.colorOrange,
    );
  }

  Future<void> _handlePrivacyToggle(
    BuildContext context,
    bool newValue,
    Future<void> Function() updateAction,
  ) async {
    if (newValue) {
      final confirmed = await _showPrivacyWarnings(context);
      if (confirmed == true) {
        await updateAction();
      }
    } else {
      await updateAction();
    }
  }

  Future<bool?> _showPrivacyWarnings(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aviso importante'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('• Antes de continuar, te informamos que estás por compartir datos personales (nombre, teléfono, email y ubicación) conforme a la Ley 25.326 de Protección de Datos Personales.'),
              SizedBox(height: 12),
              Text('• Esta acción es voluntaria y queda bajo tu exclusiva responsabilidad. Nuestro servicio solo facilita el contacto entre usuarios con consentimiento mutuo.'),
              SizedBox(height: 12),
              Text('• Te recomendamos no compartir más información de la necesaria y priorizar interacciones con perfiles confiables.'),
              SizedBox(height: 12),
              Text('• Para más información, consultá nuestros Términos y Condiciones.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.colorOrange,
            ),
            child: const Text('Aceptar y continuar'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 7. MÉTRICAS PERSONALES (XP, PUNTOS BOOST, RESPUESTA TARDÍA) - ✅ FIX: Tipado seguro
  // ----------------------------------------------------------------------
  Widget _buildPersonalStats(ProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.colorLightGreyBgContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Métricas personales',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColor.black,
            ),
          ),
          const SizedBox(height: 12),
          _statRow('Experiencia XP', '${profile.xp} / ${_xpForNextLevel(profile)}'),
          const SizedBox(height: 8),
          _statRow('Puntos de Boost', '${profile.puntos}'),
          const SizedBox(height: 8),
          _statRow('Respuesta tardía', profile.indicadorRespuesta ?? 'No definido'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColor.colorDarkGrey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.black)),
      ],
    );
  }

  int _xpForNextLevel(ProfileModel profile) {
    final progreso = profile.progresoSiguienteNivel;
    return progreso != null ? (progreso['xp_requerido'] ?? 100) : 100;
  }

  // ----------------------------------------------------------------------
  // 8. BOTÓN SALIR - ✅ SIN CAMBIOS
  // ----------------------------------------------------------------------
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => controller.logout(),
        icon: const Icon(Icons.logout, color: AppColor.colorTextRed),
        label: const Text(
          'Salir de la cuenta',
          style: TextStyle(color: AppColor.colorTextRed),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColor.colorTextRed),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // FUNCIONES AUXILIARES (IMAGEN, USERNAME) - ✅ SIN CAMBIOS
  // ----------------------------------------------------------------------
  void _showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColor.colorOrange),
              title: const Text('Tomar foto'),
              onTap: () {
                Get.back();
                controller.updateProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColor.colorOrange),
              title: const Text('Elegir de galería'),
              onTap: () {
                Get.back();
                controller.updateProfileImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUsernameDialog() {
    final TextEditingController usernameController = TextEditingController();
    Get.defaultDialog(
      title: 'Editar @usuario',
      content: TextField(
        controller: usernameController,
        decoration: const InputDecoration(
          hintText: 'Nuevo nombre de usuario',
          prefixText: '@',
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          final newUsername = usernameController.text.trim();
          if (newUsername.isNotEmpty) {
            controller.updateUsername(newUsername);
            Get.back();
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: AppColor.colorOrange),
        child: const Text('Guardar'),
      ),
      cancel: TextButton(
        onPressed: Get.back,
        child: const Text('Cancelar'),
      ),
    );
  }
}