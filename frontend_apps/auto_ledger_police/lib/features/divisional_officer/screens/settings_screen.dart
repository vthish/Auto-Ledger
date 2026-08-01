import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TokenStorage _tokenStorage = const TokenStorage();
  final AuthService _authService = AuthService();

  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  bool _isCheckingBiometric = true;
  bool _isUpdatingBiometric = false;
  int _autoLockMinutes = 1;

  PoliceSession? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _initBiometrics();
    _loadAutoLockSettings();
  }

  Future<void> _loadSession() async {
    final session = await _tokenStorage.getSession();
    if (mounted) {
      setState(() {
        _session = session;
      });
    }
  }

  Future<void> _loadAutoLockSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('auto_lock_minutes') ?? 1;
    if (mounted) {
      setState(() {
        _autoLockMinutes = saved;
      });
    }
  }

  Future<void> _initBiometrics() async {
    bool isDeviceSupported = false;
    bool canCheckBiometrics = false;
    List<BiometricType> availableBiometrics = const [];

    try {
      isDeviceSupported = await _localAuth.isDeviceSupported();
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      availableBiometrics = await _localAuth.getAvailableBiometrics();
    } catch (_) {
      isDeviceSupported = false;
      canCheckBiometrics = false;
      availableBiometrics = const [];
    }

    if (!mounted) return;

    final supported = isDeviceSupported &&
        canCheckBiometrics &&
        availableBiometrics.isNotEmpty;

    final savedEnabled = supported ? await _tokenStorage.getBiometricEnabled() : false;

    if (!mounted) return;
    setState(() {
      _biometricSupported = supported;
      _biometricEnabled = savedEnabled && supported;
      _isCheckingBiometric = false;
      if (!_biometricSupported) {
        _biometricEnabled = false;
      }
    });
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool isLoading = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final old = oldPasswordController.text.trim();
              final newP = newPasswordController.text.trim();
              final confirm = confirmPasswordController.text.trim();

              if (old.isEmpty || newP.isEmpty || confirm.isEmpty) {
                AppErrorHandler.showPopup(context, message: 'Please fill all fields');
                return;
              }
              if (newP.length < 6) {
                AppErrorHandler.showPopup(context, message: 'Password must be at least 6 characters');
                return;
              }
              if (old == newP) {
                AppErrorHandler.showPopup(context, message: 'New password must be different');
                return;
              }
              if (newP != confirm) {
                AppErrorHandler.showPopup(context, message: 'Passwords do not match');
                return;
              }

              setDialogState(() => isLoading = true);

              try {
                await _authService.changePassword(
                  oldPassword: old,
                  newPassword: newP,
                );
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                AppErrorHandler.showPopup(
                  context,
                  message: 'Password changed successfully',
                  isError: false,
                );
              } on ApiException catch (error) {
                AppErrorHandler.showPopup(context, message: error.message);
              } catch (_) {
                AppErrorHandler.showPopup(
                  context,
                  message: 'Unable to change password. Try again.',
                );
              } finally {
                if (context.mounted) {
                  setDialogState(() => isLoading = false);
                }
              }
            }

            InputDecoration glassDecoration(String label, String hint, IconData icon) {
              return InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon: Icon(icon, color: const Color(0xFF0B1A30)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.6),
                labelStyle: const TextStyle(
                  color: Color(0xFF0B1A30),
                  fontWeight: FontWeight.w600,
                ),
                hintStyle: TextStyle(
                  color: const Color(0xFF0B1A30).withValues(alpha: 0.35),
                  fontWeight: FontWeight.w400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(
                    color: Color(0xFF0B1A30),
                    width: 1.8,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0B1A30).withValues(alpha: 0.12),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0B1A30),
                                  Color(0xFF1E3A8A),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0B1A30)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Change Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF0B1A30),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Update the password for this session.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: oldPasswordController,
                            obscureText: obscureOld,
                            decoration: glassDecoration(
                              'Current Password',
                              'Enter current password',
                              Icons.lock_outline_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureOld ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: const Color(0xFF0B1A30),
                                ),
                                onPressed: () {
                                  setDialogState(() => obscureOld = !obscureOld);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: newPasswordController,
                            obscureText: obscureNew,
                            decoration: glassDecoration(
                              'New Password',
                              'Enter new password',
                              Icons.lock_reset_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: const Color(0xFF0B1A30),
                                ),
                                onPressed: () {
                                  setDialogState(() => obscureNew = !obscureNew);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirm,
                            decoration: glassDecoration(
                              'Confirm New Password',
                              'Repeat new password',
                              Icons.verified_user_outlined,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: const Color(0xFF0B1A30),
                                ),
                                onPressed: () {
                                  setDialogState(() => obscureConfirm = !obscureConfirm);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0B1A30),
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B1A30),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Update',
                                          style: TextStyle(fontWeight: FontWeight.w800),
                                        ),
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

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B1A30).withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.errorRed,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Log out?',
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
                      'You will need to sign in again to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0B1A30),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_isUpdatingBiometric) return;

    if (!value) {
      if (!_biometricSupported) return;

      setState(() => _isUpdatingBiometric = true);
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate with fingerprint to disable fingerprint login.',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );

        if (!mounted) return;

        if (authenticated) {
          setState(() {
            _biometricEnabled = false;
          });
          await _tokenStorage.saveBiometricEnabled(false);
          AppErrorHandler.showPopup(
            context,
            message: 'Fingerprint login disabled.',
            isError: false,
          );
        } else {
          AppErrorHandler.showPopup(
            context,
            message: 'Authentication required to disable fingerprint login.',
          );
        }
      } catch (_) {
        if (!mounted) return;
        AppErrorHandler.showPopup(
          context,
          message: 'Unable to verify fingerprint to disable.',
        );
      } finally {
        if (mounted) {
          setState(() => _isUpdatingBiometric = false);
        }
      }
      return;
    }

    if (_isCheckingBiometric) {
      AppErrorHandler.showPopup(
        context,
        message: 'Fingerprint support is still being checked.',
      );
      return;
    }

    if (!_biometricSupported) {
      AppErrorHandler.showPopup(
        context,
        message: 'This device does not currently support fingerprint login.',
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUpdatingBiometric = true;
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable fingerprint login.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _biometricEnabled = true;
        });
        await _tokenStorage.saveBiometricEnabled(true);
      } else {
        AppErrorHandler.showPopup(
          context,
          message: 'Fingerprint authentication was cancelled.',
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;

      String message = 'Unable to use fingerprint on this device right now.';
      switch (e.code) {
        case 'NotAvailable':
          message = 'Fingerprint is not available on this device.';
          break;
        case 'NotEnrolled':
          message = 'No fingerprint is enrolled.';
          break;
        case 'LockedOut':
          message = 'Fingerprint is locked temporarily.';
          break;
        case 'PermanentlyLockedOut':
          message = 'Fingerprint is permanently locked.';
          break;
        case 'PasscodeNotSet':
          message = 'Please set a device PIN or password.';
          break;
        default:
          message = 'Unable to use fingerprint on this device.';
      }
      AppErrorHandler.showPopup(
        context,
        message: message,
      );
    } catch (_) {
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to use fingerprint on this device right now.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingBiometric = false;
        });
      }
    }
  }

  String _biometricSubtitle() {
    if (_isCheckingBiometric) {
      return 'Checking device support...';
    }
    if (!_biometricSupported) {
      return 'Fingerprint login is blocked.';
    }
    return _biometricEnabled
        ? 'Fingerprint login is enabled.'
        : 'Fingerprint login is available.';
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(
                  color: Color(0xFF0B1A30),
                ),
                centerTitle: false,
                title: const Text(
                  'Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0B1A30),
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 24.0;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const _HeaderCard(),
                            const SizedBox(height: 16),
                            _ProfileHeader(session: session),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _SettingsTile(
                                    icon: Icons.fingerprint_rounded,
                                    title: 'Fingerprint Login',
                                    subtitle: _biometricSubtitle(),
                                    trailing: _isUpdatingBiometric
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF0B1A30),
                                            ),
                                          )
                                        : Switch.adaptive(
                                            value: _biometricEnabled,
                                            onChanged: _biometricSupported ? _toggleBiometric : null,
                                            activeColor: const Color(0xFF0B1A30),
                                            activeTrackColor: const Color(0xFF0B1A30).withValues(alpha: 0.3),
                                            inactiveThumbColor: Colors.white,
                                            inactiveTrackColor: const Color(0xFFE2E8F0),
                                          ),
                                    isBusy: _isUpdatingBiometric,
                                  ),
                                  if (_biometricEnabled) ...[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Divider(color: Color(0xFFF1F5F9), height: 1),
                                    ),
                                    Row(
                                      children: [
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0B1A30).withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: const Icon(
                                            Icons.timer_outlined,
                                            color: Color(0xFF0B1A30),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Auto-Lock Timeout',
                                                style: TextStyle(
                                                  color: Color(0xFF0B1A30),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Require fingerprint after closing',
                                                style: TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DropdownButton<int>(
                                          value: _autoLockMinutes,
                                          underline: const SizedBox(),
                                          icon: const Icon(
                                            Icons.arrow_drop_down_rounded,
                                            color: Color(0xFF0B1A30),
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF0B1A30),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 1,
                                              child: Text('1 min'),
                                            ),
                                            DropdownMenuItem(
                                              value: 5,
                                              child: Text('5 min'),
                                            ),
                                            DropdownMenuItem(
                                              value: 10,
                                              child: Text('10 min'),
                                            ),
                                          ],
                                          onChanged: (val) async {
                                            if (val != null) {
                                              setState(() {
                                                _autoLockMinutes = val;
                                              });
                                              final prefs = await SharedPreferences.getInstance();
                                              await prefs.setInt('auto_lock_minutes', val);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _SettingsTile(
                                icon: Icons.lock_reset_outlined,
                                title: 'Change Password',
                                subtitle: 'Update your login password securely',
                                onTap: _changePassword,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _SettingsTile(
                                icon: Icons.logout_rounded,
                                title: 'Logout',
                                subtitle: 'Sign out from this device',
                                onTap: _handleLogout,
                                isDanger: true,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1A30),
            Color(0xFF162A4A),
            Color(0xFF0F213C),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings & Security',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage account and security preferences',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.session,
  });

  final PoliceSession? session;

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'O';
    final parts = trimmed.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'O';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = session?.officerName.trim().isNotEmpty == true
        ? session!.officerName
        : 'Officer';
    final division = session?.districtId.trim().isNotEmpty == true
        ? session!.districtId
        : 'Division';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1A30).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0B1A30).withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getInitials(name),
                    style: const TextStyle(
                      color: Color(0xFF0B1A30),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Divisional Head',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0B1A30),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF0B1A30),
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Assigned Division',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  division,
                  style: const TextStyle(
                    color: Color(0xFF0B1A30),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.isDanger = false,
    this.isBusy = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDanger;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppTheme.errorRed : const Color(0xFF0B1A30);
    final bgColor = isDanger
        ? AppTheme.errorRed.withValues(alpha: 0.08)
        : const Color(0xFF0B1A30).withValues(alpha: 0.06);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF94A3B8),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}