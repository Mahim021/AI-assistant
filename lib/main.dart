import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const AIAssistantApp());
}

class AIAssistantApp extends StatefulWidget {
  const AIAssistantApp({super.key});

  @override
  State<AIAssistantApp> createState() => _AIAssistantAppState();
}

class _AIAssistantAppState extends State<AIAssistantApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: _AuthWrapper(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

/// Listens to Firebase auth state and routes to the appropriate screen.
class _AuthWrapper extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const _AuthWrapper({
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still waiting for the auth state to load
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        // Signed in — go to chat
        if (snapshot.hasData && snapshot.data != null) {
          return ChatScreen(
            onToggleTheme: onToggleTheme,
            isDarkMode: isDarkMode,
          );
        }

        // Not signed in — go to login
        return LoginScreen(
          onToggleTheme: onToggleTheme,
          isDarkMode: isDarkMode,
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlueDark,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
