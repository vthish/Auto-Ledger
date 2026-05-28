import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _badgeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isPasswordHidden = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _badgeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please complete the required fields.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        badgeNumber: _badgeController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      final role = response.officer.role;

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
        message: 'Unsupported officer role.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 680;
            final horizontalPadding = constraints.maxWidth < 380 ? 22.0 : 28.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isSmallScreen ? 24 : 36),
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlack,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.local_police_outlined,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Auto-Ledger',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.primaryBlack,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Police Officer Portal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textGray,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Secure access for authorized personnel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textGray,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 28 : 42),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: AppTheme.borderGray),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 26,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlack,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Use your badge number and password.',
                                  style: TextStyle(
                                    color: AppTheme.textGray,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                AppTextField(
                                  controller: _badgeController,
                                  label: 'Badge Number',
                                  hint: 'Example: HEAD-GALLE-01',
                                  icon: Icons.badge_outlined,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Badge number is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  icon: Icons.lock_outline,
                                  obscureText: _isPasswordHidden,
                                  textInputAction: TextInputAction.done,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordHidden = !_isPasswordHidden;
                                      });
                                    },
                                    icon: Icon(
                                      _isPasswordHidden
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.trim().length < 4) {
                                      return 'Password is too short';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                AppButton(
                                  text: 'Login',
                                  icon: Icons.login_rounded,
                                  isLoading: _isLoading,
                                  onPressed: _handleLogin,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: AppTheme.textGray,
                                size: 17,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Authorized police personnel only',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textGray,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 36),
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
    );
  }
}