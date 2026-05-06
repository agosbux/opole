import 'package:flutter/material.dart';
import 'package:opole/utils/color.dart';
import 'package:opole/utils/utils.dart';

class ViewContact extends StatefulWidget {
  final String reelId;
  final String currentUserId;

  const ViewContact({
    Key? key,
    required this.reelId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ViewContact> createState() => _ViewContactState();
}

class _ViewContactState extends State<ViewContact> {
  final ReelService _reelService = ReelService();
  
  bool _isLoading = true;
  bool _hasAccess = false;
  Map<String, dynamic>? _reelData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateAccess();
  }

  /// ============================================================
  /// VALIDAR ACCESO AL CONTACTO
  /// ============================================================
  Future<void> _validateAccess() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1ï¸âƒ£ Obtener datos del reel
      final reelData = await _reelService.getReelById(widget.reelId);
      
      if (reelData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Reel no encontrado";
        });
        return;
      }

      // 2ï¸âƒ£ Verificar si el contacto fue compartido con el usuario actual
      final contactSharedWith = reelData['contactSharedWith'] as String?;
      
      if (contactSharedWith != widget.currentUserId) {
        setState(() {
          _isLoading = false;
          _hasAccess = false;
          _errorMessage = "No tienes acceso al contacto de este reel";
        });
        return;
      }

      // 3ï¸âƒ£ Verificar que exista la informaciÃ³n de contacto
      if (reelData['ownerPhone'] == null && reelData['ownerEmail'] == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "InformaciÃ³n de contacto no disponible";
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _hasAccess = true;
        _reelData = reelData;
      });

    } catch (e) {
      Utils.showLog("âŒ Error validando acceso: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Error al cargar la informaciÃ³n";
      });
    }
  }

  /// ============================================================
  /// OBTENER CONTACTO DESDE LOS DATOS DEL REEL
  /// ============================================================
  Map<String, String> _getContactInfo() {
    return {
      'name': _reelData?['userName'] ?? 'Usuario',
      'phone': _reelData?['ownerPhone'] ?? 'No disponible',
      'email': _reelData?['ownerEmail'] ?? 'No disponible',
      'whatsapp': _reelData?['ownerWhatsapp'] ?? 'https://wa.me/',
    };
  }

  /// ============================================================
  /// ABRIR WHATSAPP
  /// ============================================================
  void _openWhatsApp(String phone) {
    // Limpiar el nÃºmero (quitar espacios, guiones, etc.)
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isNotEmpty) {
      final whatsappUrl = 'https://wa.me/$cleanPhone';
      Utils.showLog("ðŸ’¬ Abrir WhatsApp: $whatsappUrl");
      // AquÃ­ irÃ­a la navegaciÃ³n real
      // await launchUrl(Uri.parse(whatsappUrl));
    }
  }

  /// ============================================================
  /// LLAMAR POR TELÃ‰FONO
  /// ============================================================
  void _makePhoneCall(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isNotEmpty) {
      Utils.showLog("ðŸ“ž Llamar a: $cleanPhone");
      // AquÃ­ irÃ­a la navegaciÃ³n real
      // await launchUrl(Uri.parse('tel:$cleanPhone'));
    }
  }

  /// ============================================================
  /// ENVIAR EMAIL
  /// ============================================================
  void _sendEmail(String email) {
    if (email.isNotEmpty && email != 'No disponible') {
      Utils.showLog("ðŸ“§ Enviar email a: $email");
      // AquÃ­ irÃ­a la navegaciÃ³n real
      // await launchUrl(Uri.parse('mailto:$email'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColor.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Contacto",
          style: TextStyle(
            color: AppColor.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColor.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (!_hasAccess) {
      return _buildAccessDenied();
    }

    return _buildContactInfo();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColor.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColor.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _validateAccess,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Reintentar",
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColor.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 60,
                color: AppColor.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Acceso Restringido",
              style: TextStyle(
                color: AppColor.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Solo la persona que ganÃ³ este reel puede ver la informaciÃ³n de contacto.",
                style: TextStyle(
                  color: AppColor.white.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.white,
                side: BorderSide(color: AppColor.white.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Volver"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    final contact = _getContactInfo();
    final hasPhone = contact['phone'] != 'No disponible';
    final hasEmail = contact['email'] != 'No disponible';
    final hasWhatsapp = contact['whatsapp'] != 'https://wa.me/';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar o Ã­cono
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColor.primary, AppColor.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColor.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 60,
              color: AppColor.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Nombre
          Text(
            contact['name']!,
            style: const TextStyle(
              color: AppColor.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Badge de "Ganador"
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColor.primary,
                width: 1,
              ),
            ),
            child: const Text(
              "ðŸŽ‰ Â¡Ganaste!",
              style: TextStyle(
                color: AppColor.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Tarjetas de contacto (solo mostrar si estÃ¡n disponibles)
          if (hasPhone) ...[
            _buildContactCard(
              icon: Icons.phone,
              title: "TelÃ©fono",
              value: contact['phone']!,
              onTap: () => _makePhoneCall(contact['phone']!),
            ),
            const SizedBox(height: 12),
          ],
          
          if (hasEmail) ...[
            _buildContactCard(
              icon: Icons.email,
              title: "Email",
              value: contact['email']!,
              onTap: () => _sendEmail(contact['email']!),
            ),
            const SizedBox(height: 12),
          ],
          
          if (hasWhatsapp) ...[
            _buildContactCard(
              icon: Icons.message,
              title: "WhatsApp",
              value: "Enviar mensaje",
              onTap: () => _openWhatsApp(contact['phone']!),
            ),
            const SizedBox(height: 12),
          ],
          
          // Mensaje si no hay contactos disponibles
          if (!hasPhone && !hasEmail && !hasWhatsapp)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.contact_phone_outlined,
                    size: 50,
                    color: AppColor.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No hay informaciÃ³n de contacto disponible",
                    style: TextStyle(
                      color: AppColor.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 30),
          
          // BotÃ³n de reportar
          TextButton.icon(
            onPressed: _showReportDialog,
            icon: const Icon(
              Icons.flag_outline,
              color: Colors.red,
              size: 20,
            ),
            label: const Text(
              "Reportar problema",
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColor.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColor.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: AppColor.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColor.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.black,
        title: const Text(
          "Reportar",
          style: TextStyle(color: AppColor.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Â¿Hay algÃºn problema con este contacto?",
          style: TextStyle(color: AppColor.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: AppColor.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Utils.showLog("ðŸš© Reporte enviado para reel: ${widget.reelId}");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Reporte enviado"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Reportar"),
          ),
        ],
      ),
    );
  }
}

