import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/device_info.dart';
import '../utils/settings_util.dart';
import '../widgets/glass_container.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nicController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  final _forgotNicController = TextEditingController();
  final _forgotPhoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isBiometricEnabled = false;
  bool _obscurePassword = true;
  bool _obscureResetPassword = true;
  bool _obscureConfirmResetPassword = true;

  String _verificationId = '';
  String? _registeredPhone;
  bool _isDeviceVerification = false;

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _nicController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _forgotNicController.dispose();
    _forgotPhoneController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    final isEnabled = await SettingsUtil.isBiometricEnabled();
    setState(() {
      _isBiometricEnabled = isEnabled;
    });
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
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isError ? Colors.redAccent.withAlpha(100) : Colors.black.withAlpha(80),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withAlpha(70),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, spreadRadius: 1)
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(isError ? Icons.error_outline : Icons.info_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800.withAlpha(230),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withAlpha(70),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, spreadRadius: 1)
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (_nicController.text.trim().isEmpty) {
      _showToast('NIC Number is required', isError: true);
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showToast('Password is required', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final result = await AuthService.loginUser(
        _nicController.text.trim(),
        _passwordController.text.trim(),
        deviceId,
      );

      if (result['success'] == true && mounted) {
        final overlay = Navigator.of(context, rootNavigator: true).overlay;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );

        if (overlay != null) {
          _showGlobalSuccessToast(overlay, 'Login Successful!');
        }
      } else if (result['isDeviceMismatch'] == true && mounted) {
        _showToast('New device detected. Verification required.', isError: true);
        _registeredPhone = result['phone'];
        await _sendOTP(_registeredPhone!, isDeviceVerification: true);
      } else {
        if (mounted) {
          _showToast('Login Failed. Check credentials.', isError: true);
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('Login Failed. Check credentials or connection.', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendOTP(String phone, {required bool isDeviceVerification}) async {
    _isDeviceVerification = isDeviceVerification;
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (isDeviceVerification) {
          await _verifyNewDeviceBackend();
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          _showToast(e.message ?? 'Verification Failed', isError: true);
          setState(() => _isLoading = false);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
        });
        _showOTPDialog(phoneNumber: phone);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOTP() async {
    FocusScope.of(context).unfocus();

    if (_otpController.text.trim().isEmpty) {
      _showToast('Please enter the OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        Navigator.pop(context);
      }

      if (_isDeviceVerification) {
        await _verifyNewDeviceBackend();
      } else {
        setState(() => _isLoading = false);
        _showResetPasswordDialog();
      }
    } catch (e) {
      if (mounted) {
        _showToast('Invalid OTP', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyNewDeviceBackend() async {
    try {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final isVerified = await AuthService.verifyNewDevice(
          _nicController.text.trim(),
          deviceId
      );
      if (isVerified && mounted) {
        final overlay = Navigator.of(context, rootNavigator: true).overlay;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );

        if (overlay != null) {
          _showGlobalSuccessToast(overlay, 'Device verified successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('Backend Verification Failed', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPasswordCheck() async {
    FocusScope.of(context).unfocus();

    final nic = _forgotNicController.text.trim();
    final phoneDigits = _forgotPhoneController.text.trim();

    if (nic.isEmpty) {
      _showToast('NIC Number is required', isError: true);
      return;
    }
    if (phoneDigits.isEmpty || phoneDigits.length != 9) {
      _showToast('Please enter exactly 9 digits for the phone number.', isError: true);
      return;
    }
    final phone = '+94$phoneDigits';

    setState(() => _isLoading = true);
    try {
      final isValid = await AuthService.forgotPasswordCheck(nic, phone);
      if (isValid && mounted) {
        Navigator.pop(context);
        _isDeviceVerification = false;
        await _sendOTP(phone, isDeviceVerification: false);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Verification failed. Check NIC and Phone.', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    FocusScope.of(context).unfocus();

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmNewPasswordController.text.trim();

    if (newPassword.isEmpty) {
      _showToast('New Password is required', isError: true);
      return;
    }
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (!passwordRegex.hasMatch(newPassword)) {
      _showToast('Password must be at least 8 characters, contain uppercase, lowercase, number, and special character.', isError: true);
      return;
    }
    if (confirmPassword.isEmpty) {
      _showToast('Please confirm your new password.', isError: true);
      return;
    }
    if (newPassword != confirmPassword) {
      _showToast('New password and confirm password do not match.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await AuthService.resetPassword(
        _forgotNicController.text.trim(),
        '+94${_forgotPhoneController.text.trim()}',
        newPassword,
      );

      if (success && mounted) {
        Navigator.pop(context);

        final overlay = Navigator.of(context, rootNavigator: true).overlay;
        if (overlay != null) {
          _showGlobalSuccessToast(overlay, 'Password reset successfully! Please login.');
        }

        _forgotNicController.clear();
        _forgotPhoneController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showToast('Failed to reset password.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordInitialDialog() {
    _forgotPhoneController.clear();
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200),
      builder: (BuildContext context) {
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
                border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset, color: Colors.white, size: 40),
                  const SizedBox(height: 16),
                  const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Enter your details to receive an OTP', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _forgotNicController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'NIC Number',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withAlpha(20),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          border: Border.all(color: Colors.white.withAlpha(40)),
                        ),
                        child: const Text('+94', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _forgotPhoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 9,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Phone Number (9 digits)',
                            labelStyle: const TextStyle(color: Colors.white54),
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white.withAlpha(20),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.cyanAccent),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withAlpha(100), width: 1.5),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
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
                              side: BorderSide(color: Colors.white.withAlpha(150), width: 1.5),
                            ),
                          ),
                          onPressed: _handleForgotPasswordCheck,
                          child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
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
  }

  void _showOTPDialog({required String phoneNumber}) {
    _otpController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(200),
      builder: (BuildContext context) {
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
                border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isDeviceVerification ? Icons.phonelink_lock : Icons.message, color: Colors.white, size: 40),
                  const SizedBox(height: 15),
                  Text(_isDeviceVerification ? 'Device Verification' : 'Enter OTP',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Text(
                    _isDeviceVerification
                        ? 'A new device was detected. Enter the OTP sent to $phoneNumber.'
                        : 'Enter the OTP sent to $phoneNumber to reset your password.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 8),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withAlpha(20),
                      hintText: '••••••',
                      hintStyle: const TextStyle(color: Colors.white54, letterSpacing: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withAlpha(100), width: 1.5),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => _isLoading = false);
                          },
                          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
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
                              side: BorderSide(color: Colors.white.withAlpha(150), width: 1.5),
                            ),
                          ),
                          onPressed: _verifyOTP,
                          child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold)),
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
  }

  void _showResetPasswordDialog() {
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(200),
      builder: (BuildContext context) {
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
                    border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.password, color: Colors.white, size: 40),
                      const SizedBox(height: 16),
                      const Text('New Password', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: _obscureResetPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withAlpha(20),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyanAccent)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureResetPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _obscureResetPassword = !_obscureResetPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmNewPasswordController,
                        obscureText: _obscureConfirmResetPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withAlpha(20),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.cyanAccent)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmResetPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _obscureConfirmResetPassword = !_obscureConfirmResetPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(50),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withAlpha(150), width: 1.5),
                            ),
                          ),
                          onPressed: _handlePasswordReset,
                          child: const Text('Save Password', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _LoginBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(28.0),
                borderRadius: 24.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car, size: 60, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Auto-Ledger',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _nicController,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'NIC Number',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.badge, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withAlpha(20),
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withAlpha(20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordInitialDialog,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600),
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
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _handleLogin,
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_isBiometricEnabled) ...[
                      IconButton(
                        icon: const Icon(Icons.fingerprint, color: Colors.white, size: 45),
                        onPressed: () {
                          _showToast('Biometric Login Coming Soon!');
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'New Driver? ',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Register Here',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
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

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withAlpha(40),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withAlpha(60),
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