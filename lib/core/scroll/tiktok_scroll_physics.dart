// lib/core/scroll/tiktok_scroll_physics.dart
// ===================================================================
// TIKTOK SCROLL PHYSICS v2.0 - FIX SNAP LOGIC
// ===================================================================
// ✅ FIX: targetPage usa currentPage (fraccionaria) no nearestPage
// ✅ FIX: minFlingVelocity reducido a 150 (scroll natural sin esfuerzo)
// ✅ FIX: snap back usa currentPage.round() no nearestPage
// ✅ Spring stiffness aumentado para snap más snappy
// ===================================================================

import 'dart:math' as math;
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

const double _kSpringStiffness = 150.0; // era 120, más snappy
const double _kSpringDamping = 20.0;    // era 18
const double _kMinSnapBackVelocity = 200.0;

class TikTokScrollPhysics extends ScrollPhysics {
  final double minFlingVelocity;

  const TikTokScrollPhysics({
    super.parent,
    this.minFlingVelocity = 150.0, // era 400 default, 300 en uso → ahora 150
  });

  @override
  TikTokScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TikTokScrollPhysics(
      parent: buildParent(ancestor),
      minFlingVelocity: minFlingVelocity,
    );
  }

  double _getPageFromPixels(ScrollMetrics position) {
    final double pageSize = position.viewportDimension;
    if (pageSize == 0) return 0;
    return position.pixels / pageSize;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double pageSize = position.viewportDimension;
    if (pageSize == 0) return null;

    // ✅ FIX: usar página fraccionaria real, no redondeada
    final double currentPage = _getPageFromPixels(position);

    double targetPage;

    if (velocity.abs() >= minFlingVelocity) {
      // Velocidad suficiente → avanzar en dirección del fling
      // ✅ FIX: floor/ceil sobre currentPage (no sobre nearestPage±1)
      if (velocity > 0) {
        targetPage = currentPage.ceilToDouble();
        // Si ya estamos exactamente en una página entera, ir a la siguiente
        if (targetPage == currentPage) targetPage += 1;
      } else {
        targetPage = currentPage.floorToDouble();
        // Si ya estamos exactamente en una página entera, ir a la anterior
        if (targetPage == currentPage) targetPage -= 1;
      }
    } else {
      // Velocidad insuficiente → snap back a la página más cercana
      targetPage = currentPage.roundToDouble();
    }

    // Clamp al rango válido
    targetPage = targetPage.clamp(
      position.minScrollExtent / pageSize,
      position.maxScrollExtent / pageSize,
    );

    final double targetPixels = targetPage * pageSize;

    if ((targetPixels - position.pixels).abs() < toleranceFor(position).distance) {
      return null;
    }

    final SpringDescription spring = SpringDescription(
      mass: 1.0,
      stiffness: _kSpringStiffness,
      damping: _kSpringDamping,
    );

    double springVelocity;
    if (targetPixels == position.pixels) {
      springVelocity = 0.0;
    } else if (targetPixels > position.pixels) {
      springVelocity = math.max(velocity, _kMinSnapBackVelocity);
    } else {
      springVelocity = math.min(velocity, -_kMinSnapBackVelocity);
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      springVelocity,
      tolerance: toleranceFor(position),
    );
  }

  @override
  bool get allowImplicitScrolling => false;

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    if (position.maxScrollExtent <= position.pixels &&
        position.pixels < value) {
      return value - position.pixels;
    }
    return 0.0;
  }

  @override
  Tolerance toleranceFor(ScrollMetrics metrics) {
    return const Tolerance(
      velocity: 1.0,
      distance: 0.5,
    );
  }
}

extension TikTokPageControllerX on PageController {
  Future<void> animateToTikTok(
    int page, {
    Duration duration = const Duration(milliseconds: 300), // era 350
    Curve curve = Curves.easeOutCubic,
  }) {
    return animateToPage(page, duration: duration, curve: curve);
  }

  void jumpToTikTok(int page) => jumpToPage(page);
}