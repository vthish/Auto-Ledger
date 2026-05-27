import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import 'add_traffic_officer_screen.dart';

class DoDashboardScreen extends StatelessWidget {
  const DoDashboardScreen({super.key});

  void _showPendingMessage(BuildContext context, String featureName) {
    AppErrorHandler.showPopup(
      context,
      message: '$featureName will be connected next.',
      isError: false,
    );
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => screen,
      ),
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
                    _DashboardHeader(
                      onLogout: () => _showPendingMessage(context, 'Logout'),
                    ),
                    const SizedBox(height: 26),
                    const _WelcomeCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Divisional Officer Actions',
                      style: TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardActionCard(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'Add Traffic Officer',
                      subtitle: 'Create a new traffic officer account.',
                      onTap: () => _openScreen(
                        context,
                        const AddTrafficOfficerScreen(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardActionCard(
                      icon: Icons.groups_2_outlined,
                      title: 'Traffic Officer List',
                      subtitle: 'View officers assigned to your district.',
                      onTap: () => _showPendingMessage(
                        context,
                        'Traffic Officer List',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardActionCard(
                      icon: Icons.schedule_outlined,
                      title: 'Assign Shift',
                      subtitle: 'Set active duty time for an officer.',
                      onTap: () => _showPendingMessage(
                        context,
                        'Assign Shift',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardActionCard(
                      icon: Icons.gavel_outlined,
                      title: 'Court Cases',
                      subtitle: 'Review and resolve court pending fines.',
                      onTap: () => _showPendingMessage(
                        context,
                        'Court Cases',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardActionCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'District Statistics',
                      subtitle: 'View district level fine summary.',
                      onTap: () => _showPendingMessage(
                        context,
                        'District Statistics',
                      ),
                    ),
                    const SizedBox(height: 28),
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                'Divisional Officer Dashboard',
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
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          color: AppTheme.primaryBlack,
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Icons.verified_user_outlined,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 18),
          Text(
            'Welcome, Divisional Officer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage traffic officers, duty shifts, court cases, and district level statistics from one place.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
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
              const SizedBox(width: 16),
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
                    const SizedBox(height: 5),
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
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textGray,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}