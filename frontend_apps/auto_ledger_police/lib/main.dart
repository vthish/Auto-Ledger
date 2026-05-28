import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/divisional_officer/screens/do_dashboard_screen.dart';
import 'features/traffic_officer/screens/to_dashboard_screen.dart';

void main() {
  runApp(const AutoLedgerPoliceApp());
}

class AutoLedgerPoliceApp extends StatelessWidget {
  const AutoLedgerPoliceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto-Ledger Police',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const SessionGate(),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.divisionalDashboard: (_) => const DoDashboardScreen(),
        AppRoutes.trafficOfficerDashboard: (_) => const ToDashboardScreen(),
      },
    );
  }
}

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PoliceSession?>(
      future: const TokenStorage().getSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }

        final session = snapshot.data;

        if (session == null) {
          return const LoginScreen();
        }

        if (session.role == 'DIVISIONAL_HEAD') {
          return const DoDashboardScreen();
        }

        if (session.role == 'TRAFFIC_OFFICER') {
          return const ToDashboardScreen();
        }

        return const LoginScreen();
      },
    );
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