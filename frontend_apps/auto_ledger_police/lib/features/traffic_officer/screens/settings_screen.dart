import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/about_dialog.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/liquid_nav_bar.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<int> _lockOptions = [1, 5, 10];

  final LocalAuthentication _localAuth = LocalAuthentication();
  final TokenStorage _tokenStorage = const TokenStorage();
  final AuthService _authService = AuthService();

  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  bool _isCheckingBiometric = true;
  bool _isUpdatingBiometric = false;
  bool _isNavigating = false;
  bool _isLoggingOut = false;
  int _autoLockMinutes = 1;
  final int _selectedNavIndex = 2;

  @override
  void initState() {
    super.initState();
    _initBiometricsAndSettings();
  }

  Future<void> _initBiometricsAndSettings() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      final supported = isDeviceSupported &&
          canCheckBiometrics &&
          availableBiometrics.isNotEmpty;

      final savedEnabled = supported
          ? await _tokenStorage.getBiometricEnabled()
          : false;

      if (!mounted) {
        return;
      }

      setState(() {
        _biometricSupported = supported;
        _biometricEnabled = savedEnabled && supported;
        _isCheckingBiometric = false;
      });
    } on PlatformException {
      if (!mounted) {
        return;
      }

      setState(() {
        _biometricSupported = false;
        _biometricEnabled = false;
        _isCheckingBiometric = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _biometricSupported = false;
        _biometricEnabled = false;
        _isCheckingBiometric = false;
      });
    }
  }

  Future<void> _onNavTap(int index) async {
    if (_isNavigating || index == 2) {
      return;
    }

    _isNavigating = true;

    try {
      if (index == 1) {
        final navigator = Navigator.of(context);

        if (navigator.canPop()) {
          navigator.pop();
        }

        return;
      }

      if (index == 0) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
          ),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _openChangePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (_) => const ChangePasswordDialog(),
    );

    if (changed == true && mounted) {
      AppErrorHandler.showPopup(
        context,
        message: 'Password changed successfully.',
        isError: false,
      );
    }
  }

  Future<void> _openAbout() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (_) => const AppAboutDialog(),
    );
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (dialogContext) {
        return GlassDialogShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GlassDialogIcon(
                icon: Icons.logout_rounded,
                backgroundColor: Color(0x1A142C5C),
                iconColor: AppTheme.policeBlue,
              ),
              const SizedBox(height: 14),
              const Text(
                'Log out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will need to sign in again to continue using the Traffic Officer portal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GlassDialogAction(
                      text: 'Cancel',
                      onPressed: () {
                        Navigator.of(dialogContext).pop(false);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassDialogAction(
                      text: 'Logout',
                      isPrimary: true,
                      onPressed: () {
                        Navigator.of(dialogContext).pop(true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    _isLoggingOut = true;

    try {
      await _authService.logout();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_isUpdatingBiometric) {
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
        message:
            'This device does not currently support fingerprint login. Please add a fingerprint in device settings and try again.',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdatingBiometric = true;
    });

    final reason = value
        ? 'Authenticate to enable fingerprint login.'
        : 'Authenticate to disable fingerprint login.';

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) {
        return;
      }

      if (!authenticated) {
        AppErrorHandler.showPopup(
          context,
          message: 'Fingerprint authentication was cancelled.',
        );
        return;
      }

      await _tokenStorage.saveBiometricEnabled(value);

      if (!mounted) {
        return;
      }

      setState(() {
        _biometricEnabled = value;
      });
    } on PlatformException catch (e) {
      if (!mounted) {
        return;
      }

      var message =
          'Unable to use fingerprint on this device right now.';

      switch (e.code) {
        case 'NotAvailable':
          message = 'Fingerprint is not available on this device.';
          break;
        case 'NotEnrolled':
          message =
              'No fingerprint is enrolled. Please add one in device settings first.';
          break;
        case 'LockedOut':
          message =
              'Fingerprint is locked temporarily. Please try again after a while.';
          break;
        case 'PermanentlyLockedOut':
          message =
              'Fingerprint is permanently locked. Use device PIN or password, then try again.';
          break;
        case 'PasscodeNotSet':
          message =
              'Please set a device PIN, password, or pattern before using fingerprint login.';
          break;
      }

      AppErrorHandler.showPopup(
        context,
        message: message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      AppErrorHandler.showPopup(
        context,
        message:
            'Unable to use fingerprint on this device right now.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingBiometric = false;
        });
      }
    }
  }

  void _updateAutoLockTime(int minutes) {
    if (_autoLockMinutes == minutes) {
      return;
    }

    setState(() {
      _autoLockMinutes = minutes;
    });
  }

  String _biometricSubtitle() {
    if (_isCheckingBiometric) {
      return 'Checking device support...';
    }

    if (!_biometricSupported) {
      return 'Fingerprint login is blocked on this device.';
    }

    return _biometricEnabled
        ? 'Fingerprint login is enabled on this device.'
        : 'Fingerprint login is available but turned off.';
  }

  String _getLockTimeLabel(int minutes) {
    if (minutes == 1) {
      return '1 Minute';
    }

    return '$minutes Minutes';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FF),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FBFF),
                  Color(0xFFF1F6FF),
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth < 380 ? 16.0 : 20.0;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PageHeader(),
                      const SizedBox(height: 18),
                      if (_isCheckingBiometric)
                        const SizedBox(
                          height: 150,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.policeBlue,
                            ),
                          ),
                        )
                      else ...[
                        _BiometricCard(
                          isChecking: _isCheckingBiometric,
                          supported: _biometricSupported,
                          enabled: _biometricEnabled,
                          updating: _isUpdatingBiometric,
                          subtitle: _biometricSubtitle(),
                          onToggle: _toggleBiometric,
                          autoLockMinutes: _autoLockMinutes,
                          lockOptions: _lockOptions,
                          onLockTimeChanged: _updateAutoLockTime,
                          getLockTimeLabel: _getLockTimeLabel,
                        ),
                        const SizedBox(height: 14),
                        GlassCard(
                          borderRadius: 30,
                          padding: EdgeInsets.zero,
                          color: Colors.white.withValues(alpha: 0.85),
                          borderColor:
                              Colors.white.withValues(alpha: 0.25),
                          shadowColor: Colors.black,
                          child: _SettingsTile(
                            icon: Icons.lock_reset_rounded,
                            title: 'Change Password',
                            subtitle: 'Update your login password',
                            onTap: _openChangePassword,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassCard(
                          borderRadius: 30,
                          padding: EdgeInsets.zero,
                          color: Colors.white.withValues(alpha: 0.85),
                          borderColor:
                              Colors.white.withValues(alpha: 0.25),
                          shadowColor: Colors.black,
                          child: _SettingsTile(
                            icon: Icons.info_outline_rounded,
                            title: 'About',
                            subtitle: 'App version and details',
                            onTap: _openAbout,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.6,
                            child: GlassCard(
                              borderRadius: 30,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: const Color(
                                0xFFE4E8ED,
                              ).withValues(alpha: 0.58),
                              borderColor: const Color(
                                0xFFD7DCE3,
                              ).withValues(alpha: 0.78),
                              shadowColor: Colors.black,
                              onTap: _isLoggingOut
                                  ? null
                                  : _handleLogout,
                              child: const Center(
                                child: Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: AppTheme.errorRed,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: LiquidNavBar(
          selectedIndex: _selectedNavIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppTheme.policeBlue,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color:
                    AppTheme.policeBlue.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Account and app preferences',
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BiometricCard extends StatelessWidget {
  const _BiometricCard({
    required this.isChecking,
    required this.supported,
    required this.enabled,
    required this.updating,
    required this.subtitle,
    required this.onToggle,
    required this.autoLockMinutes,
    required this.lockOptions,
    required this.onLockTimeChanged,
    required this.getLockTimeLabel,
  });

  final bool isChecking;
  final bool supported;
  final bool enabled;
  final bool updating;
  final String subtitle;
  final ValueChanged<bool> onToggle;
  final int autoLockMinutes;
  final List<int> lockOptions;
  final ValueChanged<int> onLockTimeChanged;
  final String Function(int) getLockTimeLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2B5C),
                  Color(0xFF1E40AF),
                  Color(0xFF1D3557),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF0F2B5C,
                  ).withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'App Security & Lock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Biometrics and auto lock timer',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color:
                          Colors.white.withValues(alpha: 0.16),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (updating || isChecking)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Switch.adaptive(
                          value: enabled,
                          onChanged:
                              supported ? onToggle : null,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.white
                              .withValues(alpha: 0.38),
                          inactiveThumbColor: Colors.white70,
                          inactiveTrackColor: Colors.white
                              .withValues(alpha: 0.16),
                        ),
                    ],
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: 0.16),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: Colors.white70,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Auto Lock',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: autoLockMinutes,
                            dropdownColor:
                                const Color(0xFF0F2B5C),
                            icon: const Icon(
                              Icons
                                  .keyboard_arrow_down_rounded,
                              color: Colors.white,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                onLockTimeChanged(value);
                              }
                            },
                            items: lockOptions.map((minutes) {
                              return DropdownMenuItem<int>(
                                value: minutes,
                                child: Text(
                                  getLockTimeLabel(minutes),
                                ),
                              );
                            }).toList(growable: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    Colors.white.withValues(alpha: 0.06),
              ),
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  AppTheme.policeBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: AppTheme.policeBlue,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.policeBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return tile;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor:
            AppTheme.policeBlue.withValues(alpha: 0.05),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: tile,
      ),
    );
  }
}