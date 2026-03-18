import 'package:flutter/material.dart';

class CarTopView extends StatelessWidget {
  final double width;
  final double height;
  final Color baseColor;

  const CarTopView({
    Key? key,
    this.width = 60,
    this.height = 120,
    this.baseColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadows could go here
          // Main Body
          Container(
            width: width * 0.85,
            height: height * 0.95,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(width * 0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
          ),
          // Front Windshield
          Positioned(
            top: height * 0.2,
            child: Container(
              width: width * 0.7,
              height: height * 0.15,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(width * 0.1),
                  topRight: Radius.circular(width * 0.1),
                  bottomLeft: Radius.circular(width * 0.05),
                  bottomRight: Radius.circular(width * 0.05),
                ),
              ),
            ),
          ),
          // Rear Windshield
          Positioned(
            bottom: height * 0.15,
            child: Container(
              width: width * 0.65,
              height: height * 0.1,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(width * 0.1),
                  bottomRight: Radius.circular(width * 0.1),
                  topLeft: Radius.circular(width * 0.05),
                  topRight: Radius.circular(width * 0.05),
                ),
              ),
            ),
          ),
          // Side Windows
          Positioned(
            top: height * 0.38,
            bottom: height * 0.28,
            left: width * 0.1,
            right: width * 0.1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: width * 0.08,
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                  ),
                ),
                Container(
                  width: width * 0.08,
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Roof
          Positioned(
            top: height * 0.35,
            child: Container(
              width: width * 0.65,
              height: height * 0.3,
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(width * 0.05),
              ),
            ),
          ),
          // Side Mirrors
          Positioned(
            top: height * 0.3,
            left: 0,
            child: Container(
              width: width * 0.12,
              height: height * 0.08,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(width * 0.05),
              ),
            ),
          ),
          Positioned(
            top: height * 0.3,
            right: 0,
            child: Container(
              width: width * 0.12,
              height: height * 0.08,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(width * 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
