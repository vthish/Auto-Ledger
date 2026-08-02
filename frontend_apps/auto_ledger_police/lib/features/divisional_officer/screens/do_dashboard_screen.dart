import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/fine_model.dart';
import '../../../models/officer_model.dart';
import '../../divisional_officer/services/fine_service.dart';
import '../../divisional_officer/services/officer_service.dart';
import 'add_traffic_officer_screen.dart';
import 'assign_shift_screen.dart';
import 'court_cases_screen.dart';
import 'traffic_officer_list_screen.dart';
import 'settings_screen.dart';
import 'revoked_licenses_screen.dart';

class DoDashboardScreen extends StatefulWidget {
  const DoDashboardScreen({super.key});

  @override
  State<DoDashboardScreen> createState() => _DoDashboardScreenState();
}

class _DoDashboardScreenState extends State<DoDashboardScreen>
    with SingleTickerProviderStateMixin {
  final FineService _fineService = FineService();
  final OfficerService _officerService = OfficerService();
  DistrictStatisticsModel? _stats;
  int _calculatedOnDutyCount = 0;
  bool _isLoading = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _loadStats(showLoadingSpinner: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadStats({bool showLoadingSpinner = false}) async {
    if (showLoadingSpinner && _stats == null) {
      if (mounted) setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _fineService.getDistrictStatistics(),
        _officerService.getDistrictTrafficOfficers(),
      ]);

      final stats = results[0] as DistrictStatisticsModel?;
      final officers = results[1] as List<OfficerModel>? ?? [];

      final onDutyCount = officers.where((officer) => officer.isOnDutyNow).length;

      if (mounted) {
        setState(() {
          _stats = stats;
          _calculatedOnDutyCount = onDutyCount;
          _isLoading = false;
        });
        if (!_animController.isCompleted) {
          _animController.forward();
        }
      }
    } catch (_) {
      try {
        final stats = await _fineService.getDistrictStatistics();
        if (mounted) {
          setState(() {
            _stats = stats;
            _calculatedOnDutyCount = stats.activeOfficersOnDuty;
            _isLoading = false;
          });
          if (!_animController.isCompleted) {
            _animController.forward();
          }
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
          if (!_animController.isCompleted) {
            _animController.forward();
          }
        }
      }
    }
  }

  Future<void> _openScreen(BuildContext context, Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) {
      _loadStats(showLoadingSpinner: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final isLoading = _isLoading;

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
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                titleSpacing: 24,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1A30).withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_police_rounded,
                        color: Color(0xFF0B1A30),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Color(0xFF0B1A30),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _WelcomeCard(),
                      const SizedBox(height: 28),
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(
                              color: Color(0xFF0B1A30),
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      else if (stats != null) ...[
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Quick Statistics',
                                      style: TextStyle(
                                        color: Color(0xFF0B1A30),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0B1A30).withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Live Update',
                                        style: TextStyle(
                                          color: Color(0xFF0B1A30),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildStatsGrid(stats),
                                const SizedBox(height: 32),
                                const Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    color: Color(0xFF0B1A30),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildMenuGrid(context),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DistrictStatisticsModel stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _StatsCard(
                label: 'Total Officer',
                value: stats.totalOfficers.toString(),
                icon: Icons.groups_rounded,
                accentColor: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatsCard(
                label: 'On Duty',
                value: _calculatedOnDutyCount.toString(),
                icon: Icons.shield_rounded,
                accentColor: const Color(0xFF0D9488),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatsCard(
                label: 'Total Fines',
                value: stats.totalFinesIssued.toString(),
                icon: Icons.receipt_long_rounded,
                accentColor: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatsCard(
                label: 'Court Case',
                value: stats.overdueCourtCases.toString(),
                icon: Icons.gavel_rounded,
                accentColor: const Color(0xFFDC2626),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menuData = const [
      _MenuData(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Add TO',
        route: 'add_officer',
      ),
      _MenuData(
        icon: Icons.list_alt_rounded,
        title: 'TO List',
        route: 'officer_list',
      ),
      _MenuData(
        icon: Icons.schedule_rounded,
        title: 'Assign Shift',
        route: 'assign_shift',
      ),
      _MenuData(
        icon: Icons.gavel_rounded,
        title: 'Court Cases',
        route: 'court_cases',
      ),
      _MenuData(
        icon: Icons.cancel_rounded,
        title: 'Revoked License',
        route: 'revoked_licenses',
      ),
      _MenuData(
        icon: Icons.settings_rounded,
        title: 'Settings',
        route: 'settings',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.88,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: menuData.length,
      itemBuilder: (context, index) {
        final item = menuData[index];
        return _MenuCard(
          icon: item.icon,
          title: item.title,
          onTap: () {
            switch (item.route) {
              case 'add_officer':
                _openScreen(context, const AddTrafficOfficerScreen());
                break;
              case 'officer_list':
                _openScreen(context, const TrafficOfficerListScreen());
                break;
              case 'assign_shift':
                _openScreen(context, const AssignShiftScreen());
                break;
              case 'court_cases':
                _openScreen(context, const CourtCasesScreen());
                break;
              case 'revoked_licenses':
                _openScreen(context, const RevokedLicensesScreen());
                break;
              case 'settings':
                _openScreen(context, const SettingsScreen());
                break;
            }
          },
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PoliceSession?>(
      future: const TokenStorage().getSession(),
      builder: (context, snapshot) {
        final session = snapshot.data;
        final officerName = session?.officerName.trim().isNotEmpty == true
            ? session!.officerName
            : 'Officer';
        final divisionLabel = session?.districtId.trim().isNotEmpty == true
            ? 'Divisional Head • ${session!.districtId}'
            : 'Divisional Head';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B1A30),
                Color(0xFF162A4A),
                Color(0xFF0F213C),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1A30).withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $officerName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              divisionLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Text(
                  'Manage traffic officers, shift schedules, court cases, and district statistics from one unified dashboard.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E9F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF0B1A30),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE5E9F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B1A30),
                      Color(0xFF1E3A8A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B1A30).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFF0B1A30),
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuData {
  const _MenuData({
    required this.icon,
    required this.title,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String route;
}