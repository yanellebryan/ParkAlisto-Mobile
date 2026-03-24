import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final Border? border;

  const GlassContainer({
    Key? key,
    required this.child,
    this.blur = 28.0, // Apple Liquid Glass standard blur — UNCHANGED
    this.opacity = 0.55,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(20);

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: br,
        // Light-mode shadows — warmer and more visible on white
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 48,
            offset: const Offset(0, 20),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), // UNCHANGED
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // Strong specular sheen gradient for light mode
              gradient: LinearGradient(
                begin: gradientBegin,
                end: gradientEnd,
                colors: [
                  Colors.white.withOpacity(0.90), // Inner highlight / specular top
                  Colors.white.withOpacity(opacity),
                ],
                stops: const [0.0, 0.4],
              ),
              borderRadius: br,
              // Crisp white border for light mode — customizable
              border: border ?? Border.all(
                color: Colors.white.withOpacity(0.80),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
