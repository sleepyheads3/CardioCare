import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';

class AnimatedBackgroundWidget extends StatefulWidget {
  final Widget child;
  const AnimatedBackgroundWidget({required this.child, Key? key}) : super(key: key);

  @override
  State<AnimatedBackgroundWidget> createState() => _AnimatedBackgroundWidgetState();
}

class _AnimatedBackgroundWidgetState extends State<AnimatedBackgroundWidget>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      behaviour: RandomParticleBehaviour(
        options: ParticleOptions(
          baseColor: Colors.redAccent.withOpacity(0.7),
          spawnMinSpeed: 10,
          spawnMaxSpeed: 30,
          particleCount: 40,
          minOpacity: 0.3,
          maxOpacity: 0.8,
          // Remove image: ... if icon asset not working!
        ),
      ),
      vsync: this,
      child: widget.child,
    );
  }
}