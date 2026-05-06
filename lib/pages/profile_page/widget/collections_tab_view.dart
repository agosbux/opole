import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/profile_controller.dart';

class CollectionsTabView extends StatelessWidget {
  const CollectionsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    // TODO: Migrar a Supabase con realtime subscriptions
    // Por ahora, placeholder temporal para evitar errores de compilaciÃ³n
    return Container();

    // CÃ³digo original con Firebase (comentado)
    /*
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: controller.session.uid)
          .orderBy('DateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data!.docs;
        if (notifications.isEmpty) {
          return const Center(child: Text('No hay notificaciones'));
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index] as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(notif['senderPhoto'] ?? ''),
              ),
              title: Text(notif['message'] ?? ''),
              subtitle: Text(
                (notif['DateTime'] as DateTime).toDate().toString(),
              ),
            );
          },
        );
      },
    );
    */
  }
}
