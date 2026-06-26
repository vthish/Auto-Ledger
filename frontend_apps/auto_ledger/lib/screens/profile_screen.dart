import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/secure_storage.dart';
import '../utils/settings_util.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final void Function(String, IconData) onLogActivity;

  const ProfileScreen({super.key, required this.onLogActivity});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _errorMessage = '';

  String _fullName = '';
  String _nic = '';
  String _address = '';
  int _points = 0;
  String? _imageUrl;

  bool _isBiometricEnabled = false;
  bool _isChangingPassword = false;

  final _oldPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _oldPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  void _showGlassToast(String message, {bool isError = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final topPadding = MediaQuery.of(context).padding.top;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 10,
        left: 20,
        right: 20,
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
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isError ? Colors.redAccent.withAlpha(50) : Colors.green.shade600.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(100), width: 1.0),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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

    Navigator.of(context, rootNavigator: true).overlay?.insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 3), () {
      if (_overlayEntry != null && _overlayEntry!.mounted) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    });
  }

  Future<void> _checkBiometricStatus() async {
    final isEnabled = await SettingsUtil.isBiometricEnabled();
    setState(() {
      _isBiometricEnabled = isEnabled;
    });
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.dio.get('/license/my-license');
      final data = response.data;

      if (mounted) {
        setState(() {
          _fullName = data['full_Name'] ?? 'Unknown User';
          _nic = data['nic_No'] ?? 'N/A';
          _address = data['address'] ?? 'N/A';
          _points = data['points'] ?? 0;
          _imageUrl = data['image'];
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.response?.data['message'] ?? 'Failed to load profile.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword(BuildContext dialogContext, StateSetter setModalState) async {
    final oldPw = _oldPwController.text.trim();
    final newPw = _newPwController.text.trim();
    final confirmPw = _confirmPwController.text.trim();

    if (oldPw.isEmpty) {
      _showGlassToast('Current password is required.', isError: true);
      return;
    }
    if (newPw.isEmpty) {
      _showGlassToast('Please enter a new password.', isError: true);
      return;
    }
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (!passwordRegex.hasMatch(newPw)) {
      _showGlassToast('Password must be at least 8 characters, contain uppercase, lowercase, number, and special character.', isError: true);
      return;
    }
    if (newPw == oldPw) {
      _showGlassToast('New password cannot be the same as your current password.', isError: true);
      return;
    }
    if (confirmPw.isEmpty) {
      _showGlassToast('Please confirm your new password.', isError: true);
      return;
    }
    if (newPw != confirmPw) {
      _showGlassToast('New password and confirm password do not match.', isError: true);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setModalState(() {
      _isChangingPassword = true;
    });

    try {
      await ApiService.dio.post('/auth/user/change-password', data: {
        'oldPassword': oldPw,
        'newPassword': newPw,
      });

      if (mounted) {
        setModalState(() {
          _isChangingPassword = false;
        });

        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
        }

        _oldPwController.clear();
        _newPwController.clear();
        _confirmPwController.clear();

        _showGlassToast('Password updated successfully!');
        widget.onLogActivity('Password Changed Successfully', Icons.password_rounded);
      }
    } on DioException catch (e) {
      if (mounted) {
        setModalState(() {
          _isChangingPassword = false;
        });
        _showGlassToast(e.response?.data['message'] ?? 'Failed to change password. Check your current password.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setModalState(() {
          _isChangingPassword = false;
        });
        _showGlassToast('An unexpected error occurred. Try again.', isError: true);
      }
    }
  }

  void _showBiometricPasswordDialog() {
    final TextEditingController pwController = TextEditingController();
    bool isObscured = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(160),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withAlpha(50), Colors.white.withAlpha(20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withAlpha(80), width: 1.0),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 40, offset: const Offset(0, 10))
                      ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 50),
                      ),
                      const SizedBox(height: 16),
                      const Text('Security Verification', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      const Text(
                        'Please enter your current password to enable Biometric Authentication.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withAlpha(50), width: 1.0),
                        ),
                        child: TextField(
                          controller: pwController,
                          obscureText: isObscured,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            hintText: 'Current Password',
                            hintStyle: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w500),
                            suffixIcon: IconButton(
                              icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                              onPressed: () {
                                setModalState(() {
                                  isObscured = !isObscured;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() => _isBiometricEnabled = false);
                              },
                              child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.white.withAlpha(40),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.white.withAlpha(80), width: 1)
                                ),
                              ),
                              onPressed: () {
                                if (pwController.text.trim().isEmpty) {
                                  _showGlassToast('Password is required!', isError: true);
                                  return;
                                }
                                Navigator.pop(context);
                                SettingsUtil.setBiometricEnabled(true);
                                setState(() => _isBiometricEnabled = true);
                                _showGlassToast('Biometrics Enabled Successfully!');
                                widget.onLogActivity('Enabled Biometric Login', Icons.fingerprint_rounded);
                              },
                              child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _showChangePasswordDialog() {
    widget.onLogActivity('Initiated Password Change', Icons.password_rounded);

    bool oldPwVis = false;
    bool newPwVis = false;
    bool confPwVis = false;
    _oldPwController.clear();
    _newPwController.clear();
    _confirmPwController.clear();

    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(160),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withAlpha(40), Colors.white.withAlpha(15)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withAlpha(80), width: 1.0),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 40, offset: const Offset(0, 10))
                      ]
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.password_rounded, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 24),

                        _buildDialogPasswordField('Current Password', _oldPwController, oldPwVis, () => setModalState(() => oldPwVis = !oldPwVis)),
                        _buildDialogPasswordField('New Password', _newPwController, newPwVis, () => setModalState(() => newPwVis = !newPwVis)),
                        _buildDialogPasswordField('Confirm New Password', _confirmPwController, confPwVis, () => setModalState(() => confPwVis = !confPwVis)),

                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.white.withAlpha(40),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.white.withAlpha(80), width: 1)
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isChangingPassword ? null : () => _changePassword(dialogContext, setModalState),
                                child: _isChangingPassword
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Save Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                          ],
                        )
                      ],
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

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(160),
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withAlpha(40), Colors.white.withAlpha(15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withAlpha(80), width: 1.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.withAlpha(30), shape: BoxShape.circle),
                    child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 45),
                  ),
                  const SizedBox(height: 16),
                  const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  const Text('Are you sure you want to logout from your account?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(20),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.white.withAlpha(40), width: 1)
                            ),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700.withAlpha(180),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.red.shade400.withAlpha(100), width: 1)
                            ),
                          ),
                          onPressed: () async {
                            HapticFeedback.heavyImpact();
                            widget.onLogActivity('Logged Out', Icons.logout_rounded);
                            await SecureStorage.deleteToken();
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                            }
                          },
                          child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getPointsColor() {
    if (_points >= 80) return Colors.red.shade400;
    if (_points >= 50) return Colors.orange.shade400;
    if (_points >= 24) return Colors.amber.shade400;
    return Colors.green.shade400;
  }

  Widget _buildGlassBackground() {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(color: const Color(0xFF0B0F19)),
          Positioned(top: -40, left: -60, child: Container(width: 280, height: 280, decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withAlpha(140), shape: BoxShape.circle))),
          Positioned(top: 250, right: -80, child: Container(width: 240, height: 240, decoration: BoxDecoration(color: Colors.purple.shade900.withAlpha(120), shape: BoxShape.circle))),
          Positioned(bottom: 80, left: -40, child: Container(width: 320, height: 320, decoration: BoxDecoration(color: Colors.teal.shade900.withAlpha(120), shape: BoxShape.circle))),
          Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75), child: Container(color: Colors.transparent))),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withAlpha(45), Colors.white.withAlpha(20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(40), width: 1.0),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 25, offset: const Offset(0, 8))
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    String initials = _fullName.isNotEmpty ? _fullName.substring(0, 1).toUpperCase() : '?';
    if (_fullName.contains(' ')) {
      final parts = _fullName.split(' ');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        initials += parts[1].substring(0, 1).toUpperCase();
      }
    }

    return _buildGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(15),
              border: Border.all(color: Colors.white.withAlpha(120), width: 2.0),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(35), blurRadius: 15, offset: const Offset(0, 4))],
              image: _imageUrl != null && _imageUrl!.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(_imageUrl!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _imageUrl == null || _imageUrl!.isEmpty
                ? Center(
              child: Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
            )
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _fullName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2, letterSpacing: 0.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withAlpha(50), width: 1.0)
                  ),
                  child: Text('NIC: $_nic', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsWidget() {
    final color = _getPointsColor();

    return _buildGlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Demerit Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Accumulated penalty points', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white60)),
              ],
            ),
          ),
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(40),
              border: Border.all(color: color.withAlpha(180), width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: color.withAlpha(50),
                    blurRadius: 12,
                    spreadRadius: 2
                )
              ],
            ),
            child: Center(
              child: Text(_points.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricToggle() {
    return _buildGlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Text('Biometric Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          Switch(
            value: _isBiometricEnabled,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF1A2980).withAlpha(200),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.white.withAlpha(20),
            trackOutlineColor: WidgetStateProperty.resolveWith((states) {
              if (!states.contains(WidgetState.selected)) {
                return Colors.white.withAlpha(40);
              }
              return null;
            }),
            onChanged: (bool value) {
              if (value) {
                _showBiometricPasswordDialog();
              } else {
                SettingsUtil.setBiometricEnabled(false);
                setState(() => _isBiometricEnabled = false);
                _showGlassToast('Biometric login disabled.', isError: true);
                widget.onLogActivity('Disabled Biometric Login', Icons.fingerprint_rounded);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDialogPasswordField(String label, TextEditingController controller, bool isVisible, VoidCallback onVisibilityToggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(40), width: 1.0),
        ),
        child: TextField(
          controller: controller,
          obscureText: !isVisible,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            isDense: true,
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w600, fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 18),
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white70, size: 18),
              onPressed: onVisibilityToggle,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildGlassBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF0B0F19).withAlpha(120),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withAlpha(40), width: 1.0)),
                  ),
                ),
              ),
            ),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage.isNotEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 50),
                const SizedBox(height: 16),
                Text(_errorMessage, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withAlpha(30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _fetchUserProfile,
                    child: const Text('Retry', style: TextStyle(color: Colors.white))
                )
              ],
            ),
          )
              : SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildPointsWidget(),
                  const SizedBox(height: 20),

                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: Colors.white.withAlpha(200), size: 20),
                            const SizedBox(width: 8),
                            const Text('Registered Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(_address, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildBiometricToggle(),

                  const SizedBox(height: 20),
                  _buildGlassCard(
                    padding: const EdgeInsets.all(4),
                    child: ListTile(
                      onTap: _showChangePasswordDialog,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(15), shape: BoxShape.circle),
                        child: const Icon(Icons.password_rounded, color: Colors.white),
                      ),
                      title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                    ),
                  ),

                  const SizedBox(height: 30),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50.withAlpha(15),
                            foregroundColor: Colors.red.shade300,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.redAccent.withAlpha(50), width: 1.0)
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _logout();
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, size: 22),
                              SizedBox(width: 10),
                              Text('Log Out', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            ],
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
      ],
    );
  }
}