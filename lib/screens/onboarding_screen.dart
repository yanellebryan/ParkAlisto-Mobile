import 'package:flutter/material.dart';
import '../widgets/car_placeholder.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_button.dart';
import '../widgets/dynamic_mesh_background.dart';
import '../theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: DynamicMeshBackground(
        child: Stack(
          children: [
            // Background Concentric Circles — dark tints visible on white bg
            Positioned(
              top: -size.width * 0.2,
              left: -size.width * 0.1,
              child: Container(
                width: size.width * 1.2,
                height: size.width * 1.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.015),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: size.width * 0.1,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.02),
                ),
              ),
            ),
            Positioned(
              top: size.width * 0.2,
              left: size.width * 0.25,
              child: Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.025),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          
                          // Application Logo
                          Center(
                            child: Image.asset(
                              'assets/icons/Logo_For_WhiteBG_PA.png',
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Car Asset scaled by screen height
                          Center(
                            child: Transform.rotate(
                              angle: -0.1, // slightly rotated — UNCHANGED
                              child: CarTopView(
                                width: size.width * 0.45,
                                height: size.width * 0.9,
                                baseColor: AppTheme.textPrimary.withOpacity(0.85),
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Glassmorphic Content Panel
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pick and book the best\nparking spot easily',
                                    style: theme.textTheme.headlineLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  // Next Button inside the glass
                                  GlassButton(
                                    isFullWidth: true,
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const MainShell(),
                                        ),
                                      );
                                    },
                                    child: const Text('Next'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
