import 'dart:math' as math;
import 'package:flutter/material.dart';

class DynamicMeshBackground extends StatefulWidget {
  final Widget child;

  const DynamicMeshBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<DynamicMeshBackground> createState() => _DynamicMeshBackgroundState();
}

class _DynamicMeshBackgroundState extends State<DynamicMeshBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 20-second slow drifting animation loop — UNCHANGED
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pure white background
        Container(color: const Color(0xFFFFFFFF)),
        
        // Blobs with animation
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            // Ethereal drift using sine waves — UNCHANGED motion
            final dx1 = math.sin(t * math.pi * 2) * 50;
            final dy1 = math.cos(t * math.pi * 2) * 50;

            final dx2 = math.cos(t * math.pi * 2 + math.pi) * 60;
            final dy2 = math.sin(t * math.pi * 2 + math.pi) * 60;

            final dx3 = math.sin(t * math.pi * 2 + math.pi/2) * 40;
            final dy3 = math.cos(t * math.pi * 2 - math.pi/2) * 40;

            final dx4 = math.cos(t * math.pi * 2 + math.pi/3) * 45;
            final dy4 = math.sin(t * math.pi * 2 + math.pi/3) * 55;

            final dx5 = math.sin(t * math.pi * 2 - math.pi/4) * 35;
            final dy5 = math.cos(t * math.pi * 2 + math.pi/4) * 45;

            final screenH = MediaQuery.of(context).size.height;
            final screenW = MediaQuery.of(context).size.width;

            return Stack(
              children: [
                // Top-left — Soft mint green (brand tint)
                Positioned(
                  top: -100 + dy1,
                  left: -50 + dx1,
                  child: _buildBlob(const Color(0xFFD4F5E2), 350),
                ),
                // Center-right — Very light green wash
                Positioned(
                  top: screenH * 0.4 + dy2,
                  left: screenW * 0.5 + dx2,
                  child: _buildBlob(const Color(0xFFEAF9F0), 300),
                ),
                // Bottom-left — Pale sage
                Positioned(
                  top: screenH * 0.7 + dy3,
                  left: -100 + dx3,
                  child: _buildBlob(const Color(0xFFDFF2EB), 400),
                ),
                // Top-right — Near-white green tint
                Positioned(
                  top: screenH * 0.15 + dy4,
                  left: screenW * 0.6 + dx4,
                  child: _buildBlob(const Color(0xFFF0FBF5), 280),
                ),
                // Bottom-center — Soft sky blue (neutral accent)
                Positioned(
                  top: screenH * 0.55 + dy5,
                  left: screenW * 0.2 + dx5,
                  child: _buildBlob(const Color(0xFFE8F5FF), 320),
                ),
              ],
            );
          },
        ),
        
        // Ensure child content overlays the background
        widget.child,
      ],
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // High blur for barely-there color whisper on white canvas
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: size * 0.8,  // sigma 60–80 range
            spreadRadius: size * 0.15,
          ),
        ],
      ),
    );
  }
}
