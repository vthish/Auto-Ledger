import 'dart:async';

import 'package:auto_ledger_police/core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../services/traffic_fine_service.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/liquid_nav_bar.dart';
import 'fine_history_screen.dart';
import 'profile_screen.dart';
import 'qr_scanner_screen.dart';
import 'settings_screen.dart';

class ToDashboardScreen extends StatefulWidget {
  const ToDashboardScreen({super.key});

  @override
  State<ToDashboardScreen> createState() => _ToDashboardScreenState();
}

class _ToDashboardScreenState extends State<ToDashboardScreen>
    with WidgetsBindingObserver {
  final _fineService = TrafficFineService();
  final _tokenStorage = const TokenStorage();

  ModalRoute<dynamic>? _route;

  bool _isLoading = true;
  bool _isFetching = false;
  bool _isNavigating = false;
  String _officerName = 'Officer';
  String _badgeNumber = 'Traffic Officer';
  String _divisionName = 'Police Operations';
  bool _isOnDuty = true;
  int _todayFines = 0;
  int _totalFines = 0;
  int _selectedNavIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadDashboardData(showLoading: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        (_route?.isCurrent ?? false)) {
      unawaited(_loadDashboardData(showLoading: false));
    }
  }

  static String _valueOrFallback(String? value, String fallback) {
    final normalizedValue = value?.trim();

    if (normalizedValue == null || normalizedValue.isEmpty) {
      return fallback;
    }

    return normalizedValue;
  }

  static DateTime? _toLocalDateTime(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }

    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }

    return null;
  }

  static DateTime? _extractFineDate(dynamic fine) {
    dynamic value;

    try {
      value = fine.issuedAt;
    } catch (_) {
      value = null;
    }

    final issuedAt = _toLocalDateTime(value);

    if (issuedAt != null) {
      return issuedAt;
    }

    try {
      value = fine.createdAt;
    } catch (_) {
      value = null;
    }

    final createdAt = _toLocalDateTime(value);

    if (createdAt != null) {
      return createdAt;
    }

    try {
      value = fine.date;
    } catch (_) {
      value = null;
    }

    return _toLocalDateTime(value);
  }

  Future<void> _loadDashboardData({required bool showLoading}) async {
    if (_isFetching) {
      return;
    }

    _isFetching = true;

    if (showLoading && mounted && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait<Object?>([
        _tokenStorage.getSession(),
        _fineService.getFineHistory(),
      ]);

      final session = results[0] as PoliceSession?;
      final allFines =
          results[1] as List<dynamic>? ?? const <dynamic>[];

      final now = DateTime.now();
      var todayCount = 0;

      for (final fine in allFines) {
        final issuedAt = _extractFineDate(fine);

        if (issuedAt != null && DateUtils.isSameDay(issuedAt, now)) {
          todayCount++;
        }
      }

      if (!mounted) {
        return;
      }

      final officerName = _valueOrFallback(
        session?.officerName,
        'Officer',
      );
      final badgeNumber = _valueOrFallback(
        session?.officerBadgeNumber,
        'Traffic Officer',
      );
      final divisionName = _valueOrFallback(
        session?.divisionName,
        'Police Operations',
      );

      setState(() {
        _officerName = officerName;
        _badgeNumber = badgeNumber;
        _divisionName = divisionName;
        _isOnDuty = true;
        _totalFines = allFines.length;
        _todayFines = todayCount;

        if (showLoading) {
          _isLoading = false;
        }
      });
    } on ApiException catch (e) {
      if (!mounted || !(_route?.isCurrent ?? false)) {
        return;
      }

      AppErrorHandler.showPopup(
        context,
        message: e.message,
      );
    } catch (_) {
      if (!mounted || !(_route?.isCurrent ?? false)) {
        return;
      }

      AppErrorHandler.showPopup(
        context,
        message: 'Unable to load dashboard data. Please try again.',
      );
    } finally {
      _isFetching = false;

      if (showLoading && mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openPage(
    WidgetBuilder builder, {
    int? selectedNavIndex,
  }) async {
    if (!mounted || _isNavigating) {
      return;
    }

    _isNavigating = true;

    if (selectedNavIndex != null &&
        _selectedNavIndex != selectedNavIndex) {
      setState(() {
        _selectedNavIndex = selectedNavIndex;
      });
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: builder),
      );
    } finally {
      _isNavigating = false;

      if (mounted &&
          selectedNavIndex != null &&
          _selectedNavIndex != 1) {
        setState(() {
          _selectedNavIndex = 1;
        });
      }
    }

    if (!mounted) {
      return;
    }

    await _loadDashboardData(showLoading: false);
  }

  Future<void> _openScanner() {
    return _openPage(
      (_) => const QrScannerScreen(),
    );
  }

  Future<void> _openHistory() {
    return _openPage(
      (_) => const FineHistoryScreen(),
    );
  }

  Future<void> _openProfile() {
    return _openPage(
      (_) => const ProfileScreen(),
      selectedNavIndex: 0,
    );
  }

  Future<void> _openSettings() {
    return _openPage(
      (_) => const SettingsScreen(),
      selectedNavIndex: 2,
    );
  }

  Future<void> _onNavTap(int index) async {
    switch (index) {
      case 0:
        await _openProfile();
        return;
      case 1:
        if (mounted && _selectedNavIndex != 1) {
          setState(() {
            _selectedNavIndex = 1;
          });
        }
        return;
      case 2:
        await _openSettings();
        return;
    }
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
                  padding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: horizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _DashboardHeader(),
                      const SizedBox(height: 14),
                      _WelcomeCard(
                        officerName: _officerName,
                        badgeNumber: _badgeNumber,
                        divisionName: _divisionName,
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(title: 'Today\'s Overview'),
                      const SizedBox(height: 10),
                      DashboardStatsCard(
                        todayFines: _todayFines,
                        totalFines: _totalFines,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 18),
                      const _SectionTitle(title: 'Quick Actions'),
                      const SizedBox(height: 10),
                      _ToActionCard(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Scan Driver QR',
                        subtitle: 'Scan and verify license',
                        onTap: _openScanner,
                      ),
                      const SizedBox(height: 12),
                      _ToActionCard(
                        icon: Icons.history_rounded,
                        title: 'Fine History',
                        subtitle: 'View issued fines',
                        onTap: _openHistory,
                      ),
                      const SizedBox(height: 18),
                      _ShiftStatusCard(isOnDuty: _isOnDuty),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: LiquidNavBar(
          selectedIndex: _selectedNavIndex,
          onTap: (index) async {
            await _onNavTap(index);
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

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
            Icons.local_police_rounded,
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
                'Traffic Officer',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Secure field operations',
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.policeBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppTheme.policeBlue.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                color: AppTheme.policeBlue,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.policeBlue,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.officerName,
    required this.badgeNumber,
    required this.divisionName,
  });

  final String officerName;
  final String badgeNumber;
  final String divisionName;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
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
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Welcome, $officerName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF60A5FA),
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep the road safe with fast, secure operations.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFE0E7FF),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoChip(
                      icon: Icons.location_on_rounded,
                      label: divisionName,
                      foreground: const Color(0xFFF0F9FF),
                      background: Colors.white.withValues(alpha: 0.12),
                      border: Colors.white.withValues(alpha: 0.22),
                    ),
                    _InfoChip(
                      icon: Icons.badge_rounded,
                      label: badgeNumber,
                      foreground: const Color(0xFFF0F9FF),
                      background: Colors.white.withValues(alpha: 0.12),
                      border: Colors.white.withValues(alpha: 0.22),
                    ),
                  ],
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
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: border,
          width: 1.1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF93C5FD),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToActionCard extends StatelessWidget {
  const _ToActionCard({
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        splashColor: AppTheme.policeBlue.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFE4EBF5),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.policeBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.policeBlue,
                  size: 27,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
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

class _ShiftStatusCard extends StatelessWidget {
  const _ShiftStatusCard({required this.isOnDuty});

  final bool isOnDuty;

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnDuty ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE4EBF5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.shade50,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: statusColor.shade700,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shift Status',
                  style: TextStyle(
                    color: AppTheme.policeBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.circle_rounded,
                      color: statusColor.shade500,
                      size: 10,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnDuty ? 'Active • On Duty' : 'Off Duty',
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: statusColor.shade50,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: statusColor.shade200,
                width: 1,
              ),
            ),
            child: Text(
              isOnDuty ? 'LIVE' : 'OFF',
              style: TextStyle(
                color: statusColor.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}