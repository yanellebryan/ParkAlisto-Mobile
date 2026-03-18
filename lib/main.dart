import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'services/app_state.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const ParkAlistoApp());
}

class ParkAlistoApp extends StatelessWidget {
  const ParkAlistoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Park Alisto',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const OnboardingScreen(),
      ),
    );
  }
}
