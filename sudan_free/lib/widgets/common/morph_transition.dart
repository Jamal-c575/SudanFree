import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class MorphTransition extends StatelessWidget {
  final Widget Function(BuildContext context, VoidCallback openContainer) closedBuilder;
  final Widget openScreen;
  final Duration transitionDuration;
  final bool tappable;

  const MorphTransition({
    super.key,
    required this.closedBuilder,
    required this.openScreen,
    this.transitionDuration = const Duration(milliseconds: 700),
    this.tappable = true,
  });

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionDuration: transitionDuration,
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0,
      closedColor: Colors.transparent,
      middleColor: Colors.transparent,
      openElevation: 0,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      tappable: tappable,
      openBuilder: (context, _) => openScreen,
      closedBuilder: closedBuilder,
    );
  }
}
