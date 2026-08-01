import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({
    super.key,
    required this.nextScreen,
  });

  final Widget nextScreen;

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  late final AnimationController _pulseController;

  bool _isAuthenticating = true;
  String _statusText = 'Preparing secure authentication...';
  int _attemptCount = 0;
  bool _isWaitingForRetry = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Route _fadeRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => screen,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _fadeRoute(const LoginScreen()),
    );
  }

  Future<void> _goToNextScreen() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _fadeRoute(widget.nextScreen),
    );
  }

  void _resetAndRetry() {
    setState(() {
      _isWaitingForRetry = false;
      _statusText = 'Touch the fingerprint sensor to continue...';
      _isAuthenticating = true;
    });
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isProcessing) return;
    _isProcessing = true;

    setState(() {
      _isAuthenticating = true;
      _statusText = 'Checking device security...';
    });

    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (!mounted) return;

      if (!isDeviceSupported || !canCheckBiometrics || availableBiometrics.isEmpty) {
        setState(() {
          _statusText = 'Fingerprint is not ready on this device.';
        });
        await Future.delayed(const Duration(milliseconds: 700));
        _isProcessing = false;
        await _goToLogin();
        return;
      }

      setState(() {
        _statusText = 'Touch the fingerprint sensor to continue...';
        _isWaitingForRetry = false;
      });

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to continue to Auto-Ledger Police.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _statusText = 'Authentication successful...';
          _attemptCount = 0;
        });
        _isProcessing = false;
        await Future.delayed(const Duration(milliseconds: 300));
        await _goToNextScreen();
      } else {
        setState(() {
          _attemptCount++;
        });
        _isProcessing = false;
        await _handleFailedAttempt();
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _attemptCount++;
      });
      _isProcessing = false;
      await _handleFailedAttempt(e.code);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attemptCount++;
      });
      _isProcessing = false;
      await _handleFailedAttempt();
    }
  }

  Future<void> _handleFailedAttempt([String? errorCode]) async {
    if (_attemptCount >= 3) {
      setState(() {
        _statusText = 'Too many failed attempts. Please login with password.';
        _isAuthenticating = false;
        _isWaitingForRetry = false;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      await _goToLogin();
    } else {
      setState(() {
        _statusText = errorCode != null
            ? _messageForCode(errorCode)
            : 'Authentication cancelled. Please try again.';
        _isAuthenticating = false;
        _isWaitingForRetry = true;
      });
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'NotAvailable':
        return 'Fingerprint is not available on this device.';
      case 'NotEnrolled':
        return 'No fingerprint is enrolled on this device.';
      case 'LockedOut':
        return 'Fingerprint is locked temporarily. Try again later.';
      case 'PermanentlyLockedOut':
        return 'Fingerprint is permanently locked. Use device PIN or password.';
      case 'PasscodeNotSet':
        return 'Please set a device PIN, password, or pattern first.';
      case 'no_fragment_activity':
        return 'Authentication requires a FragmentActivity setup.';
      default:
        return 'Unable to use fingerprint right now.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F8FF),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FBFF),
                  Color(0xFFF0F6FF),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.56),
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.48),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 40,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                color: AppTheme.policeBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.local_police_rounded,
                                color: AppTheme.policeBlue,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Auto-Ledger Police',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.policeBlue,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Secure authentication portal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textGray,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.96,
                                end: 1.04,
                              ).animate(
                                CurvedAnimation(
                                  parent: _pulseController,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: AppTheme.policeBlue.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.policeBlue.withValues(alpha: 0.16),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.fingerprint_rounded,
                                  color: AppTheme.policeBlue,
                                  size: 46,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _statusText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textGray,
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (_isAuthenticating) ...[
                              SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppTheme.policeBlue.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Authenticating...',
                                style: TextStyle(
                                  color: AppTheme.textGray,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ] else if (_isWaitingForRetry) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _resetAndRetry,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.policeBlue,
                                        side: BorderSide(
                                          color: AppTheme.policeBlue.withValues(alpha: 0.3),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.refresh_rounded, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Try Again',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _goToLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.policeBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${3 - _attemptCount} attempts remaining',
                                style: const TextStyle(
                                  color: AppTheme.textGray,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}