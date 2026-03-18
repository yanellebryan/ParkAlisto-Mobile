import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'services/app_state.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hlutfwclaoeqmoifneij.supabase.co',
    anonKey:
        'sb_publishable_QFE7BMgyVw2wpylRDWI-FA_Xh02joel',
  );

  runApp(const ParkAlistoApp());
}

/// Global accessor for the Supabase client
final supabase = Supabase.instance.client;

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
