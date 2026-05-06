// lib/pages/wishlist_page/view/wishlist_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    print('ðŸ›ï¸ [WISHLIST] Renderizando vista "Mis Lo Quiero"');

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ãcono de bolsa de compras
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 24),
              
              // TÃ­tulo
              Text(
                'Mis Lo Quiero',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // SubtÃ­tulo
              Text(
                'PrÃ³ximamente',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              // DescripciÃ³n
              Text(
                'AquÃ­ verÃ¡s todos los productos\nque te interesaron',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              
              // BotÃ³n opcional para volver al feed
              ElevatedButton.icon(
                onPressed: () {
                  print('ðŸ”™ [WISHLIST] Volviendo al feed');
                  // Opcional: navegar de vuelta al tab 0
                },
                icon: const Icon(Icons.home),
                label: const Text('Explorar reels'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
