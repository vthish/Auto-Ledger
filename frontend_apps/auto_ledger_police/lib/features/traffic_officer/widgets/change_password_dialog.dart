import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/services/auth_service.dart';
import 'glass_dialog.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState
    extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isCurrentPasswordHidden = true;
  bool _isNewPasswordHidden = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    final currentPassword =
        _currentPasswordController.text.trim();
    final newPassword =
        _newPasswordController.text.trim();
    final confirmPassword =
        _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      AppErrorHandler.showPopup(
        context,
        message: 'New passwords do not match.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.changePassword(
        oldPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      AppErrorHandler.showPopup(
        context,
        message: e.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      AppErrorHandler.showPopup(
        context,
        message:
            'Unable to change password. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialogShell(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GlassDialogIcon(
                icon: Icons.lock_reset_rounded,
              ),
              const SizedBox(height: 14),
              const Text(
                'Change Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Update your login password securely.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _currentPasswordController,
                label: 'Current Password',
                hint: 'Enter current password',
                icon: Icons.lock_outline,
                obscureText: _isCurrentPasswordHidden,
                borderRadius: 26,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isCurrentPasswordHidden =
                          !_isCurrentPasswordHidden;
                    });
                  },
                  icon: Icon(
                    _isCurrentPasswordHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Current password is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _newPasswordController,
                label: 'New Password',
                hint: 'Enter new password',
                icon: Icons.lock_reset_outlined,
                obscureText: _isNewPasswordHidden,
                borderRadius: 26,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isNewPasswordHidden =
                          !_isNewPasswordHidden;
                    });
                  },
                  icon: Icon(
                    _isNewPasswordHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'New password is required';
                  }

                  if (value.trim().length < 6) {
                    return 'Password must be at least 6 characters';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Re-enter new password',
                icon: Icons.lock_reset_outlined,
                obscureText: _isNewPasswordHidden,
                borderRadius: 26,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Confirm password is required';
                  }

                  if (value.trim() !=
                      _newPasswordController.text.trim()) {
                    return 'Passwords do not match';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop(false);
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.policeBlue,
                        side: BorderSide(
                          color: AppTheme.policeBlue
                              .withValues(alpha: 0.24),
                        ),
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.28),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(25),
                        ),
                        minimumSize:
                            const Size.fromHeight(48),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.policeBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(25),
                        ),
                        minimumSize:
                            const Size.fromHeight(48),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}