import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'providers/hunter_provider.dart';
import 'screens/hunter_auth_screen.dart';
import 'screens/hunter_hub_screen.dart';
import 'theme/hunter_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization notice: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HunterProvider()..initialize(),
        ),
      ],
      child: const HunterSystemApp(),
    ),
  );
}

class HunterSystemApp extends StatelessWidget {
  const HunterSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hunter System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF060912),
        primaryColor: HunterTheme.cyan,
        colorScheme: const ColorScheme.dark(
          primary: HunterTheme.cyan,
          secondary: HunterTheme.purple,
          surface: Color(0xFF0e1322),
        ),
        textTheme: GoogleFonts.rajdhaniTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0b0f1d),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HunterRootRouter(),
    );
  }
}

class HunterRootRouter extends StatelessWidget {
  const HunterRootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final hunter = Provider.of<HunterProvider>(context);

    if (hunter.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF060912),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: HunterTheme.cyan,
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                'INITIALIZING HUNTER SYSTEM...',
                style: TextStyle(
                  color: HunterTheme.cyan,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If the user is already logged in & has their hunter profile, launch directly into Hunter Hub!
    // The login/signup page is shown only the first time a user downloads/opens the app (or if they log out).
    if (hunter.isOnboarded) {
      return const HunterHubScreen();
    }

    return const HunterAuthScreen();
  }
}
