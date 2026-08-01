import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/api_service.dart';
import 'services/navigation_service.dart';
import 'services/session_service.dart';
import 'utils/secure_storage.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

Future<void> _handleSessionExpired() async {
  await SecureStorage.deleteToken();
  _redirectToLogin();
}

void _redirectToLogin() {
  final navigator = NavigationService.navigatorKey.currentState;
  if (navigator == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectToLogin();
    });
    return;
  }

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  SessionService.instance.configure(
    onSessionExpired: _handleSessionExpired,
  );

  final storedToken = await SecureStorage.getToken();
  final isStoredSessionValid = SessionService.instance.initialize(storedToken);
  if (!isStoredSessionValid && storedToken != null) {
    await SecureStorage.deleteToken();
  }

  ApiService.init();
  runApp(const AutoLedgerApp());
}

class AutoLedgerApp extends StatelessWidget {
  const AutoLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Ledger',
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A2980)),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0F19),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
