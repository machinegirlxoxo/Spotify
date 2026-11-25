import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Tab switch: current tab fades out to black, next tab fades in.
/// (the horizontal/reverse flags are kept for API compatibility)
class AnimatedScreenTransition extends StatelessWidget {
  const AnimatedScreenTransition(
      {super.key,
      this.enabled = true,
      this.resverse = false,
      this.horizontalTransition = false,
      required this.child});
  final bool enabled;
  final bool resverse;
  final Widget child;
  final bool horizontalTransition;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) =>
          FadeThroughTransition(
        animation: primaryAnimation,
        secondaryAnimation: secondaryAnimation,
        fillColor: Colors.black,
        child: child,
      ),
      child: child,
    );
  }
}
