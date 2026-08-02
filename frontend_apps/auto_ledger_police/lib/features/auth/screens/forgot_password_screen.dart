import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isStepOne = true;
  bool _isLoading = false;
  bool _isPasswordHidden = true;

  @override
  void dispose() {
    _loginIdController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      try {
        await _authService.requestHeadForgotPasswordOtp(
          username: _loginIdController.text.trim(),
          email: _emailController.text.trim(),
        );
      } catch (_) {
        await _authService.requestForgotPasswordOtp(
          badgeNo: _loginIdController.text.trim(),
          email: _emailController.text.trim(),
        );
      }

      if (!mounted) return;

      setState(() {
        _isStepOne = false;
        _isLoading = false;
      });

      AppErrorHandler.showPopup(
        context,
        message: 'OTP sent to your email. Please check your inbox.',
        isError: false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppErrorHandler.showPopup(context, message: error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to send OTP. Please try again.',
      );
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      AppErrorHandler.showPopup(
        context,
        message: 'Passwords do not match.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      try {
        await _authService.resetHeadForgottenPassword(
          username: _loginIdController.text.trim(),
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
        );
      } catch (_) {
        await _authService.resetForgottenPassword(
          badgeNo: _loginIdController.text.trim(),
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
        );
      }

      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: 'Password reset successfully! Please login.',
        isError: false,
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.of(context).pop();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      AppErrorHandler.showPopup(context, message: error.message);
    } catch (_) {
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to reset password. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          title: Text(
            _isStepOne ? 'Forgot Password' : 'Reset Password',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 380 ? 24.0 : 32.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 80,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Sri Lanka Police Logo - White Background
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Image.asset(
                                  'assets/images/sl_police_logo.png',
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      _isStepOne
                                          ? Icons.lock_reset_rounded
                                          : Icons.verified_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              _isStepOne ? 'Forgot Password?' : 'Create New Password',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isStepOne
                                    ? 'Enter your ID and registered email'
                                    : 'Enter OTP and your new password',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ===== LIGHT WHITE LIQUID GLASS CONTAINER =====
                            ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                                child: Container(
                                  padding: const EdgeInsets.all(22),
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
                                      if (_isStepOne) ...[
                                        TextFormField(
                                          controller: _loginIdController,
                                          textInputAction: TextInputAction.next,
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
                                          validator: (v) =>
                                              v?.trim().isEmpty == true
                                                  ? 'Required'
                                                  : null,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _emailController,
                                          textInputAction: TextInputAction.done,
                                          keyboardType: TextInputType.emailAddress,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(
                                              Icons.email_outlined,
                                              color: Colors.white70,
                                            ),
                                            labelText: 'Email Address',
                                            hintText: 'Enter your registered email',
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
                                          validator: (v) {
                                            if (v?.trim().isEmpty == true) {
                                              return 'Email is required';
                                            }
                                            if (!v!.contains('@')) {
                                              return 'Enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                      if (!_isStepOne) ...[
                                        TextFormField(
                                          controller: _otpController,
                                          textInputAction: TextInputAction.next,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(
                                              Icons.pin_outlined,
                                              color: Colors.white70,
                                            ),
                                            labelText: 'OTP Code',
                                            hintText: 'Enter 6-digit OTP',
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
                                          validator: (v) {
                                            if (v?.trim().isEmpty == true) {
                                              return 'OTP is required';
                                            }
                                            if (v!.trim().length != 6) {
                                              return 'Enter a valid 6-digit OTP';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _newPasswordController,
                                          obscureText: _isPasswordHidden,
                                          textInputAction: TextInputAction.next,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(
                                              Icons.lock_reset_rounded,
                                              color: Colors.white70,
                                            ),
                                            labelText: 'New Password',
                                            hintText: 'Create a new password',
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
                                                () => _isPasswordHidden =
                                                    !_isPasswordHidden,
                                              ),
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
                                          validator: (v) {
                                            if (v?.trim().isEmpty == true) {
                                              return 'Password is required';
                                            }
                                            if (v!.trim().length < 6) {
                                              return 'Must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _confirmPasswordController,
                                          obscureText: _isPasswordHidden,
                                          textInputAction: TextInputAction.done,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(
                                              Icons.verified_rounded,
                                              color: Colors.white70,
                                            ),
                                            labelText: 'Confirm Password',
                                            hintText: 'Re-enter your password',
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
                                          validator: (v) {
                                            if (v?.trim().isEmpty == true) {
                                              return 'Confirm password is required';
                                            }
                                            if (v!.trim() !=
                                                _newPasswordController.text
                                                    .trim()) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                      const SizedBox(height: 22),
                                      // ===== BLUE LIQUID GLASS BUTTON =====
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : (_isStepOne
                                                      ? _handleRequestOtp
                                                      : _handleResetPassword),
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
                                                      width: 22,
                                                      height: 22,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : Text(
                                                      _isStepOne
                                                          ? 'Send OTP'
                                                          : 'Reset Password',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 16,
                                                        letterSpacing: 0.3,
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
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Back to Login',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
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