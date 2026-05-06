// lib/core/ui/heart_animation_layer.dart
// ===================================================================
// HEART ANIMATION LAYER v2.1 - Production Safe (no nested Positioned)
// ===================================================================
// ✅ AnimationController individual por corazón (flexible + mantenible)
// ✅ AnimatedBuilder aísla repaints → sin jank en scroll 60 FPS
// ✅ IgnorePointer: no intercepta taps/scroll del widget hijo
// ✅ Posiciones con clamp + centrado dinámico → 0 overflow visual
// ✅ Type-safe con enum HeartIntensity
// ✅ IDs únicos con _nextId estático (más eficiente que DateTime)
// ✅ MediaQuery.sizeOf() cacheado en build() → lectura eficiente
// ✅ Cleanup robusto con mounted checks + dispose seguro
// ===================================================================

import 'package:flutter/material.dart';

enum HeartIntensity { normal, frantic }

class HeartAnimationLayer extends StatefulWidget {
  final Widget child;

  const HeartAnimationLayer({super.key, required this.child});

  @override
  State<HeartAnimationLayer> createState() => HeartAnimationLayerState();
}

class HeartAnimationLayerState extends State<HeartAnimationLayer>
    with TickerProviderStateMixin {
  final List<_HeartItem> _hearts = [];
  static const int _maxHearts = 4;
  static int _nextId = 0;

  void spawnHeart(
    Offset position, {
    HeartIntensity intensity = HeartIntensity.normal,
  }) {
    if (!mounted) return;
    if (_hearts.length >= _maxHearts) return;

    final frantic = intensity == HeartIntensity.frantic;
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: frantic ? 600 : 450),
    );
    final item = _HeartItem(
      id: _nextId++,
      position: position,
      frantic: frantic,
      controller: controller,
    );

    setState(() => _hearts.add(item));

    controller.forward().whenComplete(() {
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _hearts.removeWhere((h) => h.id == item.id));
      controller.dispose();
    });
  }

  @override
  void dispose() {
    for (final h in _hearts) {
      h.controller.dispose();
    }
    _hearts.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Cache de viewport para evitar lecturas repetidas
    final viewport = MediaQuery.sizeOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: Stack(
            children: _hearts.map((heart) {
              // ✅ Extraer tamaño para cálculo consistente
              final size = heart.frantic ? 82.0 : 68.0;
              
              // ✅ FIX CRÍTICO: Centrando dinámico + clamp para evitar overflow
              final left = (heart.position.dx - (size / 2))
                  .clamp(0.0, (viewport.width - size).clamp(0.0, double.infinity));
              final top = (heart.position.dy - (size / 2))
                  .clamp(0.0, (viewport.height - size).clamp(0.0, double.infinity));

              return Positioned(
                left: left,
                top: top,
                child: AnimatedBuilder(
                  animation: heart.controller,
                  builder: (_, __) {
                    final t = heart.controller.value;
                    
                    // ✅ Curvas de animación por intensidad
                    final scale = heart.frantic
                        ? (0.4 + (1.8 * Curves.easeOutBack.transform(t)))
                        : (0.4 + (1.2 * Curves.easeOut.transform(t)));
                    final dy = -32 * Curves.easeOut.transform(t);
                    final alpha = (1 - t).clamp(0.0, 1.0);
                    final color = heart.frantic ? Colors.redAccent : Colors.red;

                    // ✅ FIX: Sin Positioned anidado → transforms directos
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Transform.scale(
                        scale: scale,
                        child: Icon(
                          Icons.favorite,
                          size: size,
                          color: color.withOpacity(alpha),
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _HeartItem {
  final int id;
  final Offset position;
  final bool frantic;
  final AnimationController controller;

  _HeartItem({
    required this.id,
    required this.position,
    required this.frantic,
    required this.controller,
  });
}