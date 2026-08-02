// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/device_info.dart';
import '../widgets/glass_container.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nicController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Map<String, dynamic>? _registeredData;

  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _overlayEntry?.remove();
    _nicController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final topPadding = MediaQuery.of(context).padding.top;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -(1 - value) * 20),
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isError
                        ? Colors.redAccent.withAlpha(100)
                        : Colors.black.withAlpha(80),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withAlpha(70),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 10,
                          spreadRadius: 1)
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(isError ? Icons.error_outline : Icons.info_outline,
                          color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(message,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Navigator.of(context, rootNavigator: true).overlay?.insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 3), () {
      if (_overlayEntry != null && _overlayEntry!.mounted) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    });
  }

  void _showGlobalSuccessToast(OverlayState overlay, String message) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 120.0,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 20),
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800.withAlpha(230),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withAlpha(70),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 10,
                          spreadRadius: 1)
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(message,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 1), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  bool _validateInputs() {
    FocusScope.of(context).unfocus();

    final nic = _nicController.text.trim();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (nic.isEmpty) {
      _showToast('NIC Number is required', isError: true);
      return false;
    }

    final nicRegex = RegExp(r'^(?:\d{9}[VvXx]|\d{12})$');
    if (!nicRegex.hasMatch(nic)) {
      _showToast(
        'NIC must contain 9 digits followed by V/X or exactly 12 digits.',
        isError: true,
      );
      return false;
    }

    if (name.isEmpty) {
      _showToast('Full Name is required', isError: true);
      return false;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showToast('Please enter a valid email address.', isError: true);
      return false;
    }
    if (password.isEmpty) {
      _showToast('Password is required', isError: true);
      return false;
    }
    final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      _showToast(
          'Password must be at least 8 characters, contain uppercase, lowercase, number, and special character.',
          isError: true);
      return false;
    }
    if (confirmPassword.isEmpty) {
      _showToast('Please confirm your password.', isError: true);
      return false;
    }
    if (password != confirmPassword) {
      _showToast('Passwords do not match.', isError: true);
      return false;
    }
    return true;
  }

  Future<void> _handleRegister() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final nic = _nicController.text.trim();

      _registeredData = {
        'nicNo': nic,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'deviceId': deviceId,
      };

      final result = await AuthService.registerUser(_registeredData!);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showOTPDialog();
        return;
      }

      _showToast(
        result['message']?.toString() ??
            'Registration failed. Please check your NIC and email.',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showToast(
        'Registration failed. Please try again.',
        isError: true,
      );
    }
  }

  void _showOTPDialog() {
    _otpController.clear();
    bool isResending = false;
    bool isVerifying = false;
    String? errorMsg;
    String? successMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(200),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withAlpha(50), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.message, color: Colors.white, size: 40),
                      const SizedBox(height: 15),
                      const Text('Enter OTP',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Text(
                        'We sent an OTP to ${_emailController.text.trim()}. Please enter it to complete registration.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 8),
                        textAlign: TextAlign.center,
                        onChanged: (val) {
                          if (errorMsg != null || successMsg != null) {
                            setModalState(() {
                              errorMsg = null;
                              successMsg = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withAlpha(20),
                          hintText: '••••••',
                          hintStyle: const TextStyle(
                              color: Colors.white54, letterSpacing: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                        ),
                      ),

                      if (errorMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(errorMsg!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                      if (successMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(successMsg!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),

                      const SizedBox(height: 16),
                      // Resend Button
                      TextButton(
                        onPressed: isResending || isVerifying
                            ? null
                            : () async {
                                FocusScope.of(dialogContext).unfocus();
                                setModalState(() {
                                  isResending = true;
                                  errorMsg = null;
                                  successMsg = null;
                                });
                                try {
                                  final success =
                                      await AuthService.resendRegistrationOtp(
                                              _registeredData!['nicNo'])
                                          .timeout(const Duration(seconds: 15));

                                  if (dialogContext.mounted) {
                                    if (success) {
                                      setModalState(() => successMsg =
                                          'OTP resent successfully!');
                                    } else {
                                      setModalState(() =>
                                          errorMsg = 'Failed to resend OTP.');
                                    }
                                  }
                                } catch (e) {
                                  if (dialogContext.mounted) {
                                    setModalState(() =>
                                        errorMsg = 'Failed to resend OTP.');
                                  }
                                } finally {
                                  if (dialogContext.mounted) {
                                    setModalState(() => isResending = false);
                                  }
                                }
                              },
                        child: Text(
                          isResending ? 'Sending...' : 'Resend OTP',
                          style: TextStyle(
                            color: isResending
                                ? Colors.white54
                                : Colors.cyanAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: Colors.white.withAlpha(100),
                                      width: 1.5),
                                ),
                              ),
                              onPressed: () {
                                FocusScope.of(dialogContext).unfocus();
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                                setState(() => _isLoading = false);
                              },
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(50),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: Colors.white.withAlpha(150),
                                      width: 1.5),
                                ),
                              ),
                              onPressed: isVerifying || isResending
                                  ? null
                                  : () async {
                                      FocusScope.of(dialogContext).unfocus();
                                      final otp = _otpController.text.trim();

                                      if (otp.isEmpty) {
                                        setModalState(() =>
                                            errorMsg = 'Please enter the OTP');
                                        return;
                                      }

                                      setModalState(() {
                                        isVerifying = true;
                                        errorMsg = null;
                                        successMsg = null;
                                      });

                                      try {
                                        final verificationResult =
                                            await AuthService
                                                .verifyRegistration(
                                          _registeredData!['nicNo'],
                                          otp,
                                        ).timeout(
                                          const Duration(seconds: 15),
                                        );

                                        if (!dialogContext.mounted) return;

                                        if (verificationResult['success'] ==
                                            true) {
                                          Navigator.pop(dialogContext);

                                          if (!this.context.mounted) return;

                                          final overlay = Navigator.of(
                                            this.context,
                                            rootNavigator: true,
                                          ).overlay;

                                          Navigator.pushReplacement(
                                            this.context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginScreen(),
                                            ),
                                          );

                                          if (overlay != null) {
                                            _showGlobalSuccessToast(
                                              overlay,
                                              verificationResult['message']
                                                      ?.toString() ??
                                                  'Registration Successful! Please login.',
                                            );
                                          }
                                        } else {
                                          setModalState(
                                            () => errorMsg = verificationResult[
                                                        'message']
                                                    ?.toString() ??
                                                'Invalid OTP. Please try again.',
                                          );
                                        }
                                      } catch (e) {
                                        if (dialogContext.mounted) {
                                          setModalState(() => errorMsg =
                                              'OTP Verification Failed.');
                                        }
                                      } finally {
                                        if (dialogContext.mounted) {
                                          setModalState(
                                              () => isVerifying = false);
                                        }
                                      }
                                    },
                              child: Text(
                                  isVerifying ? 'Verifying...' : 'Verify',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: isEmail ? TextInputType.emailAddress : keyboardType,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withAlpha(20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withAlpha(40)),
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _RegisterBackground(),
          Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(28.0),
                borderRadius: 24.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Register Driver',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                        controller: _nicController,
                        labelText: 'NIC Number',
                        icon: Icons.badge),
                    _buildTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        icon: Icons.person),
                    _buildTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        icon: Icons.email,
                        isEmail: true),
                    _buildTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        icon: Icons.lock,
                        isPassword: true),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withAlpha(20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white.withAlpha(40)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.cyanAccent, width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const CircularProgressIndicator(color: Colors.cyanAccent)
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F2027),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _handleRegister,
                          child: const Text('REGISTER',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5)),
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 13),
                            ),
                          ],
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
  }
}

class _RegisterBackground extends StatelessWidget {
  const _RegisterBackground();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.tealAccent.withAlpha(40),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withAlpha(50),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}
