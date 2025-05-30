import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';

class AnimatedBg extends StatefulWidget {
  const AnimatedBg({super.key});

  @override
  State<AnimatedBg> createState() => _AnimatedBgState();
}

class _AnimatedBgState extends State<AnimatedBg> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      behaviour: RandomParticleBehaviour(
        options: ParticleOptions(
          baseColor: Colors.redAccent,
          spawnMinRadius: 10,
          spawnMaxRadius: 30,
          particleCount: 30,
          spawnMinSpeed: 10,
          spawnMaxSpeed: 30,
        ),
      ),
      vsync: this,
      child: Container(),
    );
  }
}