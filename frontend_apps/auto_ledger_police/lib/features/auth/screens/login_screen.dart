import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isPasswordHidden = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  String? _loginIdError;
  String? _passwordError;
  Timer? _loginIdErrorTimer;
  Timer? _passwordErrorTimer;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  @override
  void dispose() {
    _loginIdErrorTimer?.cancel();
    _passwordErrorTimer?.cancel();
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
    if (_rememberMe) {
      _loginIdController.text = prefs.getString('savedLoginId') ?? '';
      _passwordController.text = prefs.getString('savedPassword') ?? '';
    }
  }

  Future<void> _saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
    if (value) {
      await prefs.setString('savedLoginId', _loginIdController.text.trim());
      await prefs.setString('savedPassword', _passwordController.text.trim());
    } else {
      await prefs.remove('savedLoginId');
      await prefs.remove('savedPassword');
    }
  }

  void _setLoginIdError(String? error) {
    _loginIdErrorTimer?.cancel();
    setState(() => _loginIdError = error);
    if (error != null) {
      _loginIdErrorTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _loginIdError = null);
      });
    }
  }

  void _setPasswordError(String? error) {
    _passwordErrorTimer?.cancel();
    setState(() => _passwordError = error);
    if (error != null) {
      _passwordErrorTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _passwordError = null);
      });
    }
  }

  String? _validateLoginId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your ID or Badge';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final loginIdError = _validateLoginId(_loginIdController.text);
    final passwordError = _validatePassword(_passwordController.text);

    if (loginIdError != null || passwordError != null) {
      _setLoginIdError(loginIdError);
      _setPasswordError(passwordError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.smartLogin(
        loginId: _loginIdController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      await _saveRememberMe(_rememberMe);

      final role = response.officer.role.toUpperCase();

      if (role == 'DIVISIONAL_HEAD') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.divisionalDashboard,
          (route) => false,
        );
        return;
      }

      if (role == 'TRAFFIC_OFFICER') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.trafficOfficerDashboard,
          (route) => false,
        );
        return;
      }

      AppErrorHandler.showPopup(
        context,
        message: 'Unsupported officer role: $role',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to login. Please check your connection.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToForgotPassword() {
    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1A30),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxHeight < 680;
              final horizontalPadding = constraints.maxWidth < 380 ? 24.0 : 32.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    blurRadius: 35,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  'assets/images/sl_police_logo.png',
                                  width: 66,
                                  height: 66,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.local_police_rounded,
                                      color: Colors.white,
                                      size: 52,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Auto-Ledger Police Portal',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                '🇱🇰 Sri Lanka Police',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.28),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 40,
                                        offset: const Offset(0, 18),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                              TextFormField(
                                        controller: _loginIdController,
                                        textInputAction: TextInputAction.next,
                                        keyboardType: TextInputType.text,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                            Icons.person_outline_rounded,
                                            color: Colors.white70,
                                          ),
                                          labelText: 'User ID / Badge Number',
                                          hintText: 'Enter your username or badge',
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.4),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withValues(alpha: 0.08),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              width: 1.2,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              width: 1.2,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: const BorderSide(
                                              color: Colors.white,
                                              width: 2.0,
                                            ),
                                          ),
                                          errorText: _loginIdError,
                                          errorStyle: TextStyle(
                                            color: const Color(0xFFFF6B6B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFFF6B6B),
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFFF6B6B),
                                              width: 2.0,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 18,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          if (_loginIdError != null) {
                                            _setLoginIdError(null);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 18),
                                              TextFormField(
                                        controller: _passwordController,
                                        obscureText: _isPasswordHidden,
                                        textInputAction: TextInputAction.done,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                            Icons.lock_outline_rounded,
                                            color: Colors.white70,
                                          ),
                                          labelText: 'Password',
                                          hintText: 'Enter your password',
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.4),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withValues(alpha: 0.08),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordHidden
                                                  ? Icons.visibility_off_rounded
                                                  : Icons.visibility_rounded,
                                              color: Colors.white70,
                                            ),
                                            onPressed: () => setState(
                                              () => _isPasswordHidden = !_isPasswordHidden,
                                            ),
                                          ),
                                          errorText: _passwordError,
                                          errorStyle: TextStyle(
                                            color: const Color(0xFFFF6B6B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              width: 1.2,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              width: 1.2,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: const BorderSide(
                                              color: Colors.white,
                                              width: 2.0,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFFF6B6B),
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(25),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFFF6B6B),
                                              width: 2.0,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 18,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          if (_passwordError != null) {
                                            _setPasswordError(null);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: Checkbox(
                                                  value: _rememberMe,
                                                  onChanged: (value) =>
                                                      setState(() => _rememberMe = value ?? false),
                                                  activeColor: Colors.white,
                                                  checkColor: const Color(0xFF0B1A30),
                                                  side: const BorderSide(
                                                    color: Colors.white54,
                                                    width: 1.5,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Remember me',
                                                style: TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: _goToForgotPassword,
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Forgot password?',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 22),
                                                ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _handleLogin,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.policeBlue,
                                                foregroundColor: Colors.white,
                                                disabledBackgroundColor: Colors.white
                                                    .withValues(alpha: 0.15),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(25),
                                                ),
                                                elevation: 0,
                                                side: BorderSide(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Sign In',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 20 : 36),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}