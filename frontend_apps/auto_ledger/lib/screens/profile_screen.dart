import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/secure_storage.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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

  bool _isChangingPassword = false;
  bool _oldPwVisible = false;
  bool _newPwVisible = false;
  bool _confirmPwVisible = false;

  final _oldPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _oldPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetching from my-license as it contains user specific details and points
      final response = await ApiService.dio.get('/license/my-license');
      final data = response.data;

      if (mounted) {
        setState(() {
          _fullName = data['full_Name'] ?? 'Unknown User';
          _nic = data['nic_No'] ?? 'N/A';
          _address = data['address'] ?? 'N/A';
          _points = data['points'] ?? 0;
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

  Future<void> _changePassword() async {
    final oldPw = _oldPwController.text.trim();
    final newPw = _newPwController.text.trim();
    final confirmPw = _confirmPwController.text.trim();

    if (oldPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      _showSnackBar('Please fill all password fields.', Colors.orange.shade800);
      return;
    }

    if (newPw != confirmPw) {
      _showSnackBar('New passwords do not match!', Colors.red.shade800);
      return;
    }

    if (newPw.length < 6) {
      _showSnackBar('Password must be at least 6 characters.', Colors.orange.shade800);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isChangingPassword = true);

    try {
      // Assuming you have an endpoint like this in your Auth module
      await ApiService.dio.post('/auth/change-password', data: {
        'oldPassword': oldPw,
        'newPassword': newPw,
      });

      if (mounted) {
        setState(() {
          _isChangingPassword = false;
          _oldPwController.clear();
          _newPwController.clear();
          _confirmPwController.clear();
        });
        _showSnackBar('Password updated successfully!', Colors.green.shade800);
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _isChangingPassword = false);
        _showSnackBar(e.response?.data['message'] ?? 'Failed to change password.', Colors.red.shade800);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChangingPassword = false);
        _showSnackBar('An error occurred. Try again.', Colors.red.shade800);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(150),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(100), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 40),
                  const SizedBox(height: 16),
                  const Text('Logout', style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Are you sure you want to logout?', textAlign: TextAlign.center, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(100),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            HapticFeedback.heavyImpact();
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
    if (_points >= 80) return Colors.red.shade600;
    if (_points >= 50) return Colors.orange.shade600;
    if (_points >= 24) return Colors.amber.shade600;
    return Colors.green.shade600;
  }

  Widget _buildGlassBackground() {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(color: const Color(0xFFF0F4FF)),
          Positioned(top: -100, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(color: const Color(0xFF1A2980).withAlpha(100), shape: BoxShape.circle))),
          Positioned(bottom: 50, left: -100, child: Container(width: 350, height: 350, decoration: BoxDecoration(color: Colors.greenAccent.withAlpha(80), shape: BoxShape.circle))),
          Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent))),
        ],
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

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(80),
            border: Border.all(color: Colors.white.withAlpha(150), width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Center(
            child: Text(initials, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.blue.shade900)),
          ),
        ),
        const SizedBox(height: 16),
        Text(_fullName, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blue.shade900)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.black.withAlpha(20), borderRadius: BorderRadius.circular(12)),
          child: Text('NIC: $_nic', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: 1.0)),
        ),
      ],
    );
  }

  Widget _buildPointsWidget() {
    final color = _getPointsColor();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(60),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(120), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Demerit Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.blue.shade900)),
                  const SizedBox(height: 4),
                  const Text('Accumulated penalty points', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                ],
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(30),
                  border: Border.all(color: color.withAlpha(150), width: 3),
                  boxShadow: [BoxShadow(color: color.withAlpha(40), blurRadius: 15, spreadRadius: 2)],
                ),
                child: Center(
                  child: Text(_points.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isVisible, VoidCallback onVisibilityToggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(70),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(150), width: 1.0),
        ),
        child: TextField(
          controller: controller,
          obscureText: !isVisible,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13),
            prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.blue.shade800, size: 18),
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.black54, size: 18),
              onPressed: onVisibilityToggle,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordResetSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(50),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(120), width: 1.5),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              iconColor: Colors.blue.shade900,
              collapsedIconColor: Colors.blue.shade900,
              title: Row(
                children: [
                  Icon(Icons.password_rounded, color: Colors.blue.shade900, size: 22),
                  const SizedBox(width: 12),
                  Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.blue.shade900)),
                ],
              ),
              childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              children: [
                _buildPasswordField('Current Password', _oldPwController, _oldPwVisible, () => setState(() => _oldPwVisible = !_oldPwVisible)),
                _buildPasswordField('New Password', _newPwController, _newPwVisible, () => setState(() => _newPwVisible = !_newPwVisible)),
                _buildPasswordField('Confirm New Password', _confirmPwController, _confirmPwVisible, () => setState(() => _confirmPwVisible = !_confirmPwVisible)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2980).withAlpha(200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _isChangingPassword ? null : _changePassword,
                    child: _isChangingPassword
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                )
              ],
            ),
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
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text('My Profile', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w900, fontSize: 20)),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A2980)))
              : _errorMessage.isNotEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 50),
                const SizedBox(height: 16),
                Text(_errorMessage, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _fetchUserProfile, child: const Text('Retry'))
              ],
            ),
          )
              : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 30),
                _buildPointsWidget(),
                const SizedBox(height: 20),

                // Address Info Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withAlpha(120), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: Colors.blue.shade900, size: 20),
                              const SizedBox(width: 8),
                              Text('Registered Address', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w800, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_address, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                _buildPasswordResetSection(),
                const SizedBox(height: 30),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50.withAlpha(200),
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.red.withAlpha(100), width: 1.5)
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}