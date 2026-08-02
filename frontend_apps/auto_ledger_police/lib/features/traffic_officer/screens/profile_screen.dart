import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_nav_bar.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _tokenStorage = const TokenStorage();

  bool _isLoading = true;
  bool _isNavigating = false;
  String _name = '';
  String _badgeNumber = '';
  String _email = '';
  String _role = '';
  String _divisionName = '';
  String _divisionalHeadName = '';
  String _dutyLocation = '';
  final int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final session = await _tokenStorage.getSession();

      if (!mounted) {
        return;
      }

      setState(() {
        if (session == null) {
          _name = '';
          _badgeNumber = '';
          _email = '';
          _role = '';
          _divisionName = '';
          _divisionalHeadName = '';
          _dutyLocation = '';
        } else {
          _name = session.officerName;
          _badgeNumber = session.officerBadgeNumber;
          _email = session.email;
          _role = session.role.replaceAll('_', ' ');
          _divisionName = session.divisionName;
          _divisionalHeadName = session.divisionalHeadName;
          _dutyLocation = session.dutyLocation;
        }

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onNavTap(int index) async {
    if (_isNavigating || index == 0) {
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

      if (index == 2) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const SettingsScreen(),
          ),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  String _getInitials(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'O';
    }

    final parts = trimmed
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return 'O';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    16,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 300,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.policeBlue,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _PageHeader(),
                            const SizedBox(height: 18),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      20,
                                      18,
                                      20,
                                    ),
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
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 68,
                                          height: 68,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.14,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.25,
                                              ),
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _getInitials(_name),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _name.isEmpty
                                              ? 'Traffic Officer'
                                              : _name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _badgeNumber.isEmpty
                                              ? 'N/A'
                                              : _badgeNumber,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.18,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            _role.isEmpty
                                                ? 'Traffic Officer'
                                                : _role,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
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
                                        color: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _InfoCard(
                              icon: Icons.email_outlined,
                              title: 'Email',
                              value: _email.isEmpty
                                  ? 'Not available'
                                  : _email,
                            ),
                            const SizedBox(height: 8),
                            _InfoCard(
                              icon: Icons.badge_outlined,
                              title: 'Badge Number',
                              value: _badgeNumber.isEmpty
                                  ? 'N/A'
                                  : _badgeNumber,
                            ),
                            const SizedBox(height: 8),
                            _InfoCard(
                              icon: Icons.place_outlined,
                              title: 'Division',
                              value: _divisionName.isEmpty
                                  ? 'Not assigned'
                                  : _divisionName,
                            ),
                            const SizedBox(height: 8),
                            _InfoCard(
                              icon: Icons.location_on_outlined,
                              title: 'Duty Location',
                              value: _dutyLocation.isEmpty
                                  ? 'Not assigned'
                                  : _dutyLocation,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 8),
                            _InfoCard(
                              icon: Icons.people_outlined,
                              title: 'Divisional Head',
                              value: _divisionalHeadName.isEmpty
                                  ? 'Not assigned'
                                  : _divisionalHeadName,
                            ),
                            const SizedBox(height: 12),
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
                color: AppTheme.policeBlue.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
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
                'My Profile',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Traffic Officer account details',
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.maxLines = 1,
  });

  final IconData icon;
  final String title;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      borderRadius: 30,
      color: Colors.white.withValues(alpha: 0.85),
      borderColor: Colors.white.withValues(alpha: 0.25),
      shadowColor: Colors.black,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.policeBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: AppTheme.policeBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.policeBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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