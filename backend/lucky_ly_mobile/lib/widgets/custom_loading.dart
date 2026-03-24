import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoading extends StatelessWidget {
  final double size;
  const CustomLoading({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animations/Loading.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}
