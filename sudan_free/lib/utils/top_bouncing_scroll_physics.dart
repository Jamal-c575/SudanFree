import 'package:flutter/widgets.dart';
import 'package:flutter/physics.dart';

class TopBouncingScrollPhysics extends BouncingScrollPhysics {
  const TopBouncingScrollPhysics({super.parent});

  @override
  TopBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TopBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Top overscroll -> let BouncingScrollPhysics handle it (returns 0.0)
    if (value < position.pixels && position.pixels <= position.minScrollExtent) {
      return 0.0;
    }
    if (value < position.minScrollExtent && position.minScrollExtent < position.pixels) {
      return 0.0;
    }

    // Bottom overscroll -> CLAMP it
    if (value > position.pixels && position.pixels >= position.maxScrollExtent) {
      return value - position.maxScrollExtent;
    }
    if (position.maxScrollExtent < value && position.pixels < position.maxScrollExtent) {
      return value - position.maxScrollExtent;
    }

    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // If flinging towards the bottom (velocity > 0) and at/past the bottom boundary,
    // prevent the bounce simulation.
    if (velocity > 0.0 && position.pixels >= position.maxScrollExtent) {
      return null;
    }
    // If out of range at the bottom, prevent bouncing back
    if (position.outOfRange && position.pixels >= position.maxScrollExtent) {
      return null;
    }

    // For all other cases (including top bounce), use default BouncingScrollPhysics behavior
    return super.createBallisticSimulation(position, velocity);
  }
}
