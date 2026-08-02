// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../utils/device_info.dart';
import '../utils/settings_util.dart';
import '../utils/secure_storage.dart';
import '../widgets/glass_container.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _nicController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotNicController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  final _resetOtpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  final BiometricService _biometricService = BiometricService();
  bool _isBiometricAvailable = false;

  bool _isLoading = false;
  bool _isBiometricEnabled = false;
  bool _obscurePassword = true;
  bool _isAuthenticating = false;

  OverlayEntry? _overlayEntry;

  bool _prevBiometricAvailable = false;
  bool _prevBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeBiometricState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlayEntry?.remove();
    _nicController.dispose();
    _passwordController.dispose();
    _forgotNicController.dispose();
    _forgotEmailController.dispose();
    _resetOtpController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshBiometricState();
    }
  }

  Future<bool> _resolveBiometricEnabled() async {
    try {
      final isEnabled = await SettingsUtil.isBiometricEnabled();
      if (!isEnabled) return false;

      final savedNic = await SecureStorage.getNic();
      if (savedNic == null || savedNic.trim().isEmpty) {
        await SettingsUtil.setBiometricEnabled(false);
        return false;
      }

      return true;
    } catch (_) {
      try {
        await SettingsUtil.setBiometricEnabled(false);
      } catch (_) {}
      try {
        await SecureStorage.deleteNic();
      } catch (_) {}
      return false;
    }
  }

  Future<void> _initializeBiometricState() async {
    final isEnabled = await _resolveBiometricEnabled();
    final available = await _biometricService.checkBiometricsAvailable();

    if (!mounted) return;

    _prevBiometricEnabled = isEnabled;
    _prevBiometricAvailable = available;
    setState(() {
      _isBiometricEnabled = isEnabled;
      _isBiometricAvailable = available;
    });
  }

  Future<void> _refreshBiometricState() async {
    final isEnabled = await _resolveBiometricEnabled();
    final available = await _biometricService.checkBiometricsAvailable();

    if (!mounted) return;

    if (_prevBiometricEnabled != isEnabled ||
        _prevBiometricAvailable != available) {
      _prevBiometricEnabled = isEnabled;
      _prevBiometricAvailable = available;
      setState(() {
        _isBiometricEnabled = isEnabled;
        _isBiometricAvailable = available;
      });
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;

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

    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay != null) {
      overlay.insert(_overlayEntry!);
      Future.delayed(const Duration(seconds: 3), () {
        if (_overlayEntry != null && _overlayEntry!.mounted) {
          _overlayEntry!.remove();
          _overlayEntry = null;
        }
      });
    }
  }

  void _showGlassySuccessToast(OverlayState overlay, String message) {
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
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(100),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
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

  Future<void> _disableBiometricForDeviceMismatch() async {
    try {
      await SettingsUtil.setBiometricEnabled(false);
    } catch (_) {}
    try {
      await SecureStorage.deleteNic();
    } catch (_) {}

    if (!mounted) return;

    _prevBiometricEnabled = false;
    setState(() {
      _isBiometricEnabled = false;
      _isAuthenticating = false;
    });
  }

  Future<void> _handleBiometricLogin() async {
    if (_isAuthenticating) return;
    if (!mounted) return;

    final isEnabled = await _resolveBiometricEnabled();
    if (!isEnabled) {
      if (mounted && _isBiometricEnabled) {
        _prevBiometricEnabled = false;
        setState(() => _isBiometricEnabled = false);
      }
      _showToast('Biometric login is not enabled in settings.', isError: true);
      return;
    }

    if (!_isBiometricAvailable) {
      _showToast('Biometric hardware not available.', isError: true);
      return;
    }

    final String? savedNic = await SecureStorage.getNic();

    if (savedNic == null || savedNic.isEmpty) {
      _showToast('Please login once with NIC to save for biometric login.',
          isError: true);
      return;
    }

    _isAuthenticating = true;
    final authenticated = await _biometricService.authenticate();

    if (!authenticated) {
      _isAuthenticating = false;
      _showToast('Authentication failed.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final result = await AuthService.biometricLogin(savedNic, deviceId);

      if (!context.mounted) return;

      if (result['success'] == true) {
        final overlay = Navigator.of(context, rootNavigator: true).overlay;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        if (overlay != null) {
          _showGlassySuccessToast(overlay, 'Biometric Login Successful!');
        }
      } else if (result['isDeviceMismatch'] == true) {
        await _disableBiometricForDeviceMismatch();
        final String email = result['email'] ?? '';
        if (email.isNotEmpty) {
          _showDeviceVerificationDialog(email, savedNic);
        } else {
          _showToast('Device verification required. Check your email.',
              isError: true);
        }
      } else {
        _showToast('Biometric login failed. Please try again.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showToast('An error occurred during biometric login.', isError: true);
      }
    } finally {
      _isAuthenticating = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!mounted || _isLoading) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final nic = _nicController.text.trim();
    final password = _passwordController.text.trim();

    if (nic.isEmpty) {
      _showToast('NIC Number is required', isError: true);
      return;
    }
    if (password.isEmpty) {
      _showToast('Password is required', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final result = await AuthService.loginUser(nic, password, deviceId);

      if (!context.mounted) return;

      if (result['success'] == true) {
        await SecureStorage.saveNic(nic);

        if (!context.mounted) return;
        final overlay = Navigator.of(context, rootNavigator: true).overlay;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        if (overlay != null) {
          _showGlassySuccessToast(overlay, 'Login Successful!');
        }
      } else if (result['isDeviceMismatch'] == true) {
        await _disableBiometricForDeviceMismatch();
        final String email = result['email'] ?? '';
        if (email.isNotEmpty) {
          _showDeviceVerificationDialog(email, nic);
        } else {
          _showToast('Device verification required. Check your email.',
              isError: true);
        }
        setState(() => _isLoading = false);
      } else {
        _showToast('Login Failed. Check credentials.', isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Login Failed. Check credentials or connection.',
            isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeviceVerificationDialog(String email, String nic) {
    final localOtpController = TextEditingController();

    bool isResending = false;
    bool isVerifying = false;
    bool isSuccess = false;
    String? errorMsg;
    String? successMsg;

    AuthService.resendDeviceOtp(nic, email).catchError((_) => false);

    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) {
        localOtpController.dispose();
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withAlpha(200),
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    insetPadding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: isSuccess
                          ? Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: Colors.white.withAlpha(50),
                                    width: 1.5),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withAlpha(30),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color:
                                              Colors.greenAccent.withAlpha(80),
                                          width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.greenAccent,
                                      size: 50,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Device Verified!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Redirecting to Login...',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(25),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: Colors.white.withAlpha(50),
                                      width: 1.5),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phonelink_lock,
                                        color: Colors.white, size: 40),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Device Verification',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'A new device is detected. Enter the OTP sent to your email:',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      email,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: localOtpController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          letterSpacing: 8),
                                      textAlign: TextAlign.center,
                                      onChanged: (val) {
                                        if (errorMsg != null ||
                                            successMsg != null) {
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
                                            color: Colors.white54,
                                            letterSpacing: 8),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    if (errorMsg != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          errorMsg!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    if (successMsg != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          successMsg!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: isResending || isVerifying
                                          ? null
                                          : () async {
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                              setModalState(() {
                                                isResending = true;
                                                errorMsg = null;
                                                successMsg = null;
                                              });
                                              try {
                                                final success =
                                                    await AuthService
                                                            .resendDeviceOtp(
                                                                nic, email)
                                                        .timeout(const Duration(
                                                            seconds: 15));
                                                if (dialogContext.mounted) {
                                                  if (success) {
                                                    setModalState(() => successMsg =
                                                        'OTP resent successfully!');
                                                  } else {
                                                    setModalState(() => errorMsg =
                                                        'Failed to resend OTP.');
                                                  }
                                                }
                                              } catch (e) {
                                                if (dialogContext.mounted) {
                                                  setModalState(() => errorMsg =
                                                      'Failed to resend OTP.');
                                                }
                                              } finally {
                                                if (dialogContext.mounted) {
                                                  setModalState(() =>
                                                      isResending = false);
                                                }
                                              }
                                            },
                                      child: Text(
                                        isResending
                                            ? 'Sending...'
                                            : 'Resend OTP',
                                        style: TextStyle(
                                          color: isResending
                                              ? Colors.white54
                                              : Colors.cyanAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: BorderSide(
                                                    color: Colors.white
                                                        .withAlpha(100),
                                                    width: 1.5),
                                              ),
                                            ),
                                            onPressed: () {
                                              if (dialogContext.mounted) {
                                                Navigator.pop(dialogContext);
                                              }
                                              if (mounted) {
                                                setState(
                                                    () => _isLoading = false);
                                              }
                                            },
                                            child: const Text('Cancel',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.white.withAlpha(50),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: BorderSide(
                                                    color: Colors.white
                                                        .withAlpha(150),
                                                    width: 1.5),
                                              ),
                                            ),
                                            onPressed: isVerifying ||
                                                    isResending
                                                ? null
                                                : () async {
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();
                                                    final otp =
                                                        localOtpController.text
                                                            .trim();
                                                    if (otp.isEmpty) {
                                                      setModalState(() => errorMsg =
                                                          'Please enter the OTP');
                                                      return;
                                                    }

                                                    setModalState(() {
                                                      isVerifying = true;
                                                      errorMsg = null;
                                                      successMsg = null;
                                                    });

                                                    try {
                                                      final deviceId =
                                                          await DeviceInfoUtil
                                                              .getDeviceId();
                                                      final result =
                                                          await AuthService
                                                                  .verifyNewDevice(
                                                                      nic,
                                                                      deviceId,
                                                                      otp)
                                                              .timeout(
                                                                  const Duration(
                                                                      seconds:
                                                                          15));

                                                      if (!dialogContext
                                                          .mounted) return;

                                                      if (result['success'] ==
                                                          true) {
                                                        await SettingsUtil
                                                            .setBiometricEnabled(
                                                                false);

                                                        if (mounted) {
                                                          TextInput
                                                              .finishAutofillContext(
                                                                  shouldSave:
                                                                      false);
                                                          _nicController
                                                              .clear();
                                                          _passwordController
                                                              .clear();
                                                          setState(() {
                                                            _obscurePassword =
                                                                true;
                                                          });
                                                        }

                                                        setModalState(() {
                                                          isSuccess = true;
                                                          isVerifying = false;
                                                        });

                                                        Timer(
                                                            const Duration(
                                                                seconds: 2),
                                                            () {
                                                          if (dialogContext
                                                              .mounted) {
                                                            Navigator.pop(
                                                                dialogContext);
                                                          }
                                                          if (!mounted) {
                                                            return;
                                                          }
                                                          _prevBiometricEnabled =
                                                              false;
                                                          setState(() {
                                                            _isBiometricEnabled =
                                                                false;
                                                          });
                                                          _showToast(
                                                              'Device verified successfully! Please login again.',
                                                              isError: false);
                                                        });
                                                      } else {
                                                        setModalState(() =>
                                                            errorMsg = result[
                                                                    'message'] ??
                                                                'Invalid OTP. Please try again.');
                                                      }
                                                    } catch (e) {
                                                      if (dialogContext
                                                          .mounted) {
                                                        setModalState(() =>
                                                            errorMsg =
                                                                'Verification failed. Please try again.');
                                                      }
                                                    } finally {
                                                      if (dialogContext
                                                          .mounted) {
                                                        setModalState(() =>
                                                            isVerifying =
                                                                false);
                                                      }
                                                    }
                                                  },
                                            child: Text(
                                                isVerifying
                                                    ? 'Verifying...'
                                                    : 'Verify Device',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ).then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          localOtpController.dispose();
        });
      });
    });
  }

  void _showForgotPasswordInitialDialog() {
    _forgotNicController.clear();
    _forgotEmailController.clear();
    bool isChecking = false;
    String? errorMsg;

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setModalState) {
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: SingleChildScrollView(
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
                        const Icon(Icons.lock_reset,
                            color: Colors.white, size: 40),
                        const SizedBox(height: 16),
                        const Text('Reset Password',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                            'Enter your details to receive an OTP via email',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _forgotNicController,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            if (errorMsg != null) {
                              setModalState(() => errorMsg = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'NIC Number',
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white.withAlpha(20),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.cyanAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _forgotEmailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            if (errorMsg != null) {
                              setModalState(() => errorMsg = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white.withAlpha(20),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.cyanAccent),
                            ),
                          ),
                        ),
                        if (errorMsg != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(errorMsg!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(height: 24),
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
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
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
                                onPressed: isChecking
                                    ? null
                                    : () async {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        final nic =
                                            _forgotNicController.text.trim();
                                        final email =
                                            _forgotEmailController.text.trim();

                                        if (nic.isEmpty ||
                                            email.isEmpty ||
                                            !email.contains('@')) {
                                          setModalState(() => errorMsg =
                                              'Please enter a valid NIC and Email.');
                                          return;
                                        }

                                        setModalState(() {
                                          isChecking = true;
                                          errorMsg = null;
                                        });

                                        try {
                                          final isValid = await AuthService
                                              .forgotPasswordCheck(nic, email);
                                          if (isValid) {
                                            if (dialogContext.mounted) {
                                              Navigator.pop(dialogContext);
                                            }
                                            _showForgotPasswordOTPDialog(
                                                nic, email);
                                          } else {
                                            setModalState(() => errorMsg =
                                                'Verification failed. Check NIC and Email.');
                                          }
                                        } catch (e) {
                                          setModalState(() => errorMsg =
                                              'Verification failed. Check NIC and Email.');
                                        } finally {
                                          if (dialogContext.mounted) {
                                            setModalState(
                                                () => isChecking = false);
                                          }
                                        }
                                      },
                                child: Text(isChecking ? 'Checking...' : 'Next',
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
              ),
            ),
          );
        });
      },
    );
  }

  void _showForgotPasswordOTPDialog(String nic, String email) {
    _resetOtpController.clear();
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
            return ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: SingleChildScrollView(
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
                          const Icon(Icons.message,
                              color: Colors.white, size: 40),
                          const SizedBox(height: 15),
                          const Text('Enter OTP',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          Text(
                            'Enter the OTP sent to your email: $email',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _resetOtpController,
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
                                borderSide: BorderSide.none,
                              ),
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
                          TextButton(
                            onPressed: isResending || isVerifying
                                ? null
                                : () async {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    setModalState(() {
                                      isResending = true;
                                      errorMsg = null;
                                      successMsg = null;
                                    });
                                    try {
                                      final success = await AuthService
                                              .resendResetOtp(nic, email)
                                          .timeout(const Duration(seconds: 15));
                                      if (dialogContext.mounted) {
                                        if (success) {
                                          setModalState(() => successMsg =
                                              'OTP resent successfully!');
                                        } else {
                                          setModalState(() => errorMsg =
                                              'Failed to resend OTP.');
                                        }
                                      }
                                    } catch (e) {
                                      if (dialogContext.mounted) {
                                        setModalState(() =>
                                            errorMsg = 'Failed to resend OTP.');
                                      }
                                    } finally {
                                      if (dialogContext.mounted) {
                                        setModalState(
                                            () => isResending = false);
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
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
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
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          final otp =
                                              _resetOtpController.text.trim();

                                          if (otp.isEmpty) {
                                            setModalState(() => errorMsg =
                                                'Please enter the OTP');
                                            return;
                                          }

                                          setModalState(() {
                                            isVerifying = true;
                                            errorMsg = null;
                                            successMsg = null;
                                          });

                                          try {
                                            final isVerified = await AuthService
                                                    .verifyResetOtp(
                                                        nic, email, otp)
                                                .timeout(const Duration(
                                                    seconds: 15));

                                            if (!dialogContext.mounted) return;

                                            if (isVerified) {
                                              if (dialogContext.mounted) {
                                                Navigator.pop(dialogContext);
                                              }
                                              _showResetPasswordDialog(
                                                  nic, email, otp);
                                            } else {
                                              setModalState(() => errorMsg =
                                                  'Invalid OTP. Please try again.');
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showResetPasswordDialog(String nic, String email, String otp) {
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();
    bool isSaving = false;
    String? errorMsg;
    bool obscureReset = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(200),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: SingleChildScrollView(
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
                          const Icon(Icons.password,
                              color: Colors.white, size: 40),
                          const SizedBox(height: 16),
                          const Text('New Password',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: obscureReset,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (val) {
                              if (errorMsg != null) {
                                setModalState(() => errorMsg = null);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              labelStyle:
                                  const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withAlpha(20),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.cyanAccent),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureReset
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    obscureReset = !obscureReset;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmNewPasswordController,
                            obscureText: obscureConfirm,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (val) {
                              if (errorMsg != null) {
                                setModalState(() => errorMsg = null);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              labelStyle:
                                  const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withAlpha(20),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Colors.cyanAccent),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    obscureConfirm = !obscureConfirm;
                                  });
                                },
                              ),
                            ),
                          ),
                          if (errorMsg != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(errorMsg!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(height: 24),
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
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
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
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          final newPassword =
                                              _newPasswordController.text
                                                  .trim();
                                          final confirmPassword =
                                              _confirmNewPasswordController.text
                                                  .trim();

                                          if (newPassword.isEmpty) {
                                            setModalState(() => errorMsg =
                                                'New Password is required');
                                            return;
                                          }
                                          final passwordRegex = RegExp(
                                              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
                                          if (!passwordRegex
                                              .hasMatch(newPassword)) {
                                            setModalState(() => errorMsg =
                                                'Password must be at least 8 chars, with uppercase, lowercase, number, and special char.');
                                            return;
                                          }
                                          if (confirmPassword.isEmpty) {
                                            setModalState(() => errorMsg =
                                                'Please confirm your new password.');
                                            return;
                                          }
                                          if (newPassword != confirmPassword) {
                                            setModalState(() => errorMsg =
                                                'Passwords do not match.');
                                            return;
                                          }

                                          setModalState(() {
                                            isSaving = true;
                                            errorMsg = null;
                                          });

                                          try {
                                            final success =
                                                await AuthService.resetPassword(
                                              nic,
                                              email,
                                              otp,
                                              newPassword,
                                            );

                                            if (!dialogContext.mounted) return;

                                            if (success) {
                                              if (dialogContext.mounted) {
                                                Navigator.pop(dialogContext);
                                              }
                                              if (!this.context.mounted) return;
                                              final overlay = Navigator.of(
                                                      this.context,
                                                      rootNavigator: true)
                                                  .overlay;
                                              if (overlay != null) {
                                                _showGlassySuccessToast(overlay,
                                                    'Password reset successfully! Please login.');
                                              }
                                            } else {
                                              setModalState(() => errorMsg =
                                                  'Failed to save password. Try again.');
                                            }
                                          } catch (e) {
                                            if (dialogContext.mounted) {
                                              setModalState(() => errorMsg =
                                                  'Failed to reset password. Try again.');
                                            }
                                          } finally {
                                            if (dialogContext.mounted) {
                                              setModalState(
                                                  () => isSaving = false);
                                            }
                                          }
                                        },
                                  child: Text(isSaving ? 'Saving...' : 'Save',
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
    return RepaintBoundary(
      child: Scaffold(
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
                      const Icon(Icons.directions_car,
                          size: 60, color: Colors.white),
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
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'NIC Number',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon:
                              const Icon(Icons.badge, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withAlpha(20),
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon:
                              const Icon(Icons.lock, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withAlpha(20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordInitialDialog,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const CircularProgressIndicator(
                            color: Colors.cyanAccent)
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
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (_isBiometricEnabled && _isBiometricAvailable) ...[
                        IconButton(
                          icon: const Icon(Icons.fingerprint,
                              color: Colors.white, size: 45),
                          onPressed: _isLoading ? null : _handleBiometricLogin,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: 'New Driver? ',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Register Here',
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
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: const SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
