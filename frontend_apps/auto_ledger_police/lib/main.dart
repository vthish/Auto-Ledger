import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_routes.dart';
import 'core/navigation/app_route_observer.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/biometric_auth_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/divisional_officer/screens/do_dashboard_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/traffic_officer/screens/to_dashboard_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setSystemUIOverlayStyle(
     const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
     ),
  );
  runApp(const AutoLedgerPoliceApp());
}
class AutoLedgerPoliceApp extends StatefulWidget {
  const AutoLedgerPoliceApp({super.key});
  @override
  State<AutoLedgerPoliceApp> createState() => _AutoLedgerPoliceAppState();
}
class _AutoLedgerPoliceAppState extends State<AutoLedgerPoliceApp>
     with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final TokenStorage _tokenStorage = const TokenStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  DateTime? _pausedAt;
  bool _isLockOverlayShowing = false;
  @override
  void initState() {
     super.initState();
     WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final pausedTime = _pausedAt!;
        _pausedAt = null;
        _checkAndTriggerLock(pausedTime);
      }
    }
  }
  Future<void> _checkAndTriggerLock(DateTime pausedTime) async {
    if (_isLockOverlayShowing) return;
    final biometricEnabled = await _tokenStorage.getBiometricEnabled();
    if (!biometricEnabled) return;
    final session = await _tokenStorage.getSession();
    if (session == null) return;
    final prefs = await SharedPreferences.getInstance();
    final autoLockMinutes = prefs.getInt('auto_lock_minutes') ?? 1;
    final elapsedSeconds = DateTime.now().difference(pausedTime).inSeconds;
    if (elapsedSeconds >= autoLockMinutes * 60) {
      _showBlurLockOverlay();
    }
  }
  void _showBlurLockOverlay() {
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;
    setState(() {
      _isLockOverlayShowing = true;
    });
    showDialog(
      context: navContext,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Stack(
            children: [
              Positioned.fill(
                 child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                       color: const Color(0xFF0B1A30).withValues(alpha: 0.25),
                    ),
                 ),
              ),
              Center(
                 child: Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                       padding: const EdgeInsets.all(24),
                       decoration: BoxDecoration(
                         color: Colors.white.withValues(alpha: 0.88),
                         borderRadius: BorderRadius.circular(28),
                         border: Border.all(
                           color: Colors.white.withValues(alpha: 0.8),

                          width: 1.5,
                       ),
                       boxShadow: [
                          BoxShadow(
                             color: const Color(0xFF0B1A30).withValues(alpha: 0.2),
                             blurRadius: 36,
                             offset: const Offset(0, 16),
                          ),
                       ],
                     ),
                     child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                             width: 64,
                             height: 64,
                             decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                   begin: Alignment.topLeft,
                                   end: Alignment.bottomRight,
                                   colors: [
                                      Color(0xFF0B1A30),
                                      Color(0xFF162A4A),
                                   ],
                                ),
                                borderRadius: BorderRadius.circular(22),
                             ),
                             child: const Icon(
                                Icons.fingerprint_rounded,
                                color: Colors.white,
                                size: 34,
                             ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                             'App Locked',
                             textAlign: TextAlign.center,
                             style: TextStyle(
                                color: Color(0xFF0B1A30),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                             ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                             'Authenticate to access your active police session.',
                             textAlign: TextAlign.center,
                             style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                             ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                             onPressed: () async {
                                try {
                                   final authenticated =
                                        await _localAuth.authenticate(
                                      localizedReason:
                                          'Unlock your police active session',
                                      options: const AuthenticationOptions(
                                        biometricOnly: true,

                                      stickyAuth: true,
                                      useErrorDialogs: true,
                                     ),
                                  );
                                  if (authenticated && dialogContext.mounted) {
                                     Navigator.of(dialogContext).pop();
                                  }
                                } catch (_) {}
                              },
                              style: ElevatedButton.styleFrom(
                                 backgroundColor: const Color(0xFF0B1A30),
                                 foregroundColor: Colors.white,
                                 elevation: 0,
                                 shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                 ),
                                 minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                 'Unlock Session',
                                 style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                 ),
                              ),
                           ),
                         ],
                      ),
                    ),
                 ),
               ),
            ],
          ),
         );
      },
    ).then((_) {
      if (mounted) {
         setState(() {
            _isLockOverlayShowing = false;
         });
      }
    });
    _triggerPromptDirectly();
  }
  Future<void> _triggerPromptDirectly() async {
    try {
      final authenticated = await _localAuth.authenticate(
         localizedReason: 'Unlock your police active session',
         options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
            useErrorDialogs: true,
         ),
      );
      final navContext = _navigatorKey.currentContext;
      if (authenticated && navContext != null && _isLockOverlayShowing) {
         Navigator.of(navContext, rootNavigator: true).pop();
      }
    } catch (_) {}
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      navigatorObservers: [appRouteObserver],
      title: 'Auto-Ledger Police',

        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const SessionGate(),
        routes: {
           AppRoutes.login: (_) => const LoginScreen(),
           AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
           AppRoutes.divisionalDashboard: (_) => const DoDashboardScreen(),
           AppRoutes.trafficOfficerDashboard: (_) => const ToDashboardScreen(),
        },
      );
  }
}
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});
  @override
  State<SessionGate> createState() => _SessionGateState();
}
class _SessionGateState extends State<SessionGate> {
  final TokenStorage _tokenStorage = const TokenStorage();
  bool _isLoading = true;
  Widget _screen = const LoginScreen();
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }
  Widget _dashboardForRole(String role) {
    if (role == 'DIVISIONAL_HEAD') {
      return const DoDashboardScreen();
    }
    if (role == 'TRAFFIC_OFFICER') {
      return const ToDashboardScreen();
    }
    return const LoginScreen();
  }
  Future<void> _bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;
      if (!hasSeenTutorial && mounted) {
        setState(() {
          _screen = const OnboardingScreen();
          _isLoading = false;
        });
        return;
      }
      final session = await _tokenStorage.getSession();
      if (!mounted) return;
      if (session == null) {
        setState(() {
          _screen = const LoginScreen();
          _isLoading = false;
        });
        return;
      }
      final targetScreen = _dashboardForRole(session.role);
      final biometricEnabled = await _tokenStorage.getBiometricEnabled();
      if (!mounted) return;
      if (biometricEnabled) {
        setState(() {
          _screen = BiometricAuthScreen(nextScreen: targetScreen);
          _isLoading = false;
        });

        return;
      }
      setState(() {
        _screen = targetScreen;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _screen = const LoginScreen();
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _SplashScreen();
    }
    return _screen;
  }
}
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
       backgroundColor: AppTheme.backgroundWhite,
       body: Center(
          child: CircularProgressIndicator(
             color: AppTheme.primaryBlack,
          ),
       ),
    );
  }
}
