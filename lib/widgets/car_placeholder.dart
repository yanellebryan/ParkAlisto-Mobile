import 'package:flutter/material.dart';

class CarTopView extends StatelessWidget {
  final double width;
  final double height;
  final Color baseColor;

  const CarTopView({
    Key? key,
    this.width = 40,
    this.height = 55,
    this.baseColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/icons/main_car.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        color: baseColor == Colors.white ? null : baseColor,
        colorBlendMode: baseColor == Colors.white ? null : BlendMode.modulate,
      ),
    );
  }
}
