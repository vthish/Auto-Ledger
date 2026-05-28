import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/services/auth_service.dart';

class ToDashboardScreen extends StatelessWidget {
  const ToDashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 26.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlack,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.local_police_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Police Portal',
                                style: TextStyle(
                                  color: AppTheme.primaryBlack,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Traffic Officer Dashboard',
                                style: TextStyle(
                                  color: AppTheme.textGray,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _handleLogout(context),
                          icon: const Icon(Icons.logout_rounded),
                          color: AppTheme.primaryBlack,
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlack,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Welcome, Traffic Officer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'QR scanning, license verification, fine issuing, and history pages will be connected next.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Traffic Officer Actions',
                      style: TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _ToActionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan Driver QR',
                      subtitle: 'Verify driver license using QR token.',
                    ),
                    SizedBox(height: 14),
                    const _ToActionCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Issue Fine',
                      subtitle: 'Select offense and issue a traffic fine.',
                    ),
                    SizedBox(height: 14),
                    const _ToActionCard(
                      icon: Icons.history_rounded,
                      title: 'Fine History',
                      subtitle: 'View issued fines and recent activity.',
                    ),
                    SizedBox(height: 28),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ToActionCard extends StatelessWidget {
  const _ToActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryBlack,
              size: 26,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 13,
                    height: 1.35,
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