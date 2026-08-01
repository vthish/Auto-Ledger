import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/license_model.dart';
import 'offense_select_screen.dart';

class LicensePreviewScreen extends StatefulWidget {
  const LicensePreviewScreen({
    super.key,
    required this.qrToken,
    required this.license,
  });

  final String qrToken;
  final LicenseModel license;

  @override
  State<LicensePreviewScreen> createState() =>
      _LicensePreviewScreenState();
}

class _LicensePreviewScreenState extends State<LicensePreviewScreen> {
  static const Color _liquidGlassColor = Color(0xFFE4E8ED);
  static const Color _liquidGlassBorderColor = Color(0xFFC7CDD5);
  static const Color _darkCardTextColor = Color(0xFF111318);

  Timer? _timer;
  late final DateTime _expiresAt;
  Duration _remaining = Duration.zero;
  bool _expiredDialogShown = false;

  String get _sessionToken {
    final token = widget.qrToken.trim();

    if (token.isNotEmpty) {
      return token;
    }

    return widget.license.scanToken.trim();
  }

  @override
  void initState() {
    super.initState();

    final expiresAt = widget.license.scanExpiresAt;

    if (expiresAt == null) {
      _expiresAt = DateTime.now().add(
        const Duration(minutes: 5),
      );
      _remaining = const Duration(minutes: 5);
    } else {
      _expiresAt = expiresAt;

      final remaining = _expiresAt.difference(DateTime.now());

      _remaining = remaining.isNegative
          ? Duration.zero
          : remaining;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );

    if (_remaining == Duration.zero) {
      _scheduleExpiredDialog();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _scheduleExpiredDialog() {
    if (_expiredDialogShown) {
      return;
    }

    _expiredDialogShown = true;
    _timer?.cancel();
    _timer = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showExpiredDialog();
      }
    });
  }

  void _updateRemaining() {
    if (!mounted) {
      return;
    }

    final remaining = _expiresAt.difference(DateTime.now());

    final safeRemaining = remaining.isNegative
        ? Duration.zero
        : remaining;

    setState(() {
      _remaining = safeRemaining;
    });

    if (safeRemaining == Duration.zero) {
      _scheduleExpiredDialog();
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }

    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '${local.year}-$month-$day';
  }

  String _formatCountdown(Duration duration) {
    final seconds = duration.inSeconds.clamp(0, 99999);
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _statusColor() {
    final status = widget.license.status.trim().toUpperCase();

    if (status == 'ACTIVE') {
      return AppTheme.successGreen;
    }

    if (status.startsWith('TEMP')) {
      return AppTheme.errorRed;
    }

    if (status == 'SUSPENDED' || status == 'REVOKED') {
      return AppTheme.errorRed;
    }

    return AppTheme.policeBlue;
  }

  bool get _hasCriticalStatus {
    final status = widget.license.status.trim().toUpperCase();

    return status == 'SUSPENDED' || status == 'REVOKED';
  }

  Future<void> _showExpiredDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 28,
                sigmaY: 28,
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: AppTheme.policeBlue.withValues(
                      alpha: 0.18,
                    ),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.policeBlue.withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.timer_off_rounded,
                        color: AppTheme.errorRed,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Session Expired',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.policeBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This QR verification window has expired.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();

                          Navigator.of(context)
                              .pushNamedAndRemoveUntil(
                            AppRoutes.trafficOfficerDashboard,
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.policeBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Go to Dashboard',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openOffenseSelection() {
    if (_remaining == Duration.zero) {
      _showExpiredDialog();
      return;
    }

    if (_hasCriticalStatus) {
      AppErrorHandler.showPopup(
        context,
        message:
            'Suspended and revoked licenses cannot proceed to fines.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OffenseSelectScreen(
          qrToken: _sessionToken,
          license: widget.license,
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    Color? color,
    Color? borderColor,
    double radius = 25,
    Color? shadowColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: color ??
                Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ??
                  AppTheme.policeBlue.withValues(alpha: 0.12),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor ??
                    AppTheme.policeBlue.withValues(
                      alpha: 0.04,
                    ),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _liquidGreyCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 25,
  }) {
    return _glassCard(
      radius: radius,
      padding: padding,
      color: _liquidGlassColor.withValues(alpha: 0.72),
      borderColor: _liquidGlassBorderColor.withValues(
        alpha: 0.92,
      ),
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: child,
    );
  }

  Widget _scanTimerBanner() {
    final color = _remaining == Duration.zero
        ? AppTheme.errorRed
        : _remaining.inSeconds <= 30
            ? Colors.orange
            : AppTheme.successGreen;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _remaining == Duration.zero
                  ? Icons.timer_off_rounded
                  : Icons.timer_outlined,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _remaining == Duration.zero
                      ? 'Scan session expired'
                      : 'Scan session active',
                  style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _remaining == Duration.zero
                      ? 'Please return to the dashboard.'
                      : 'Time remaining: ${_formatCountdown(_remaining)}',
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 11.5,
                    height: 1.3,
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

  Widget _currentValuesCard(Color statusColor) {
    final license = widget.license;

    return _glassCard(
      radius: 25,
      child: Column(
        children: [
          _InfoRow(
            title: 'Driver Name',
            value: license.driverName.isEmpty
                ? '-'
                : license.driverName,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'License No',
            value: license.licenseNumber.isEmpty
                ? '-'
                : license.licenseNumber,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Status',
            value: license.status.isEmpty
                ? '-'
                : license.status,
            valueColor: statusColor,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Points',
            value: '${license.points}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'NIC',
            value: license.nicNo?.isEmpty == true
                ? 'N/A'
                : (license.nicNo ?? 'N/A'),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Address',
            value: license.address?.isEmpty == true
                ? 'N/A'
                : (license.address ?? 'N/A'),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Blood Group',
            value: license.bloodGroup?.isEmpty == true
                ? 'N/A'
                : (license.bloodGroup ?? 'N/A'),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Token',
            value: _sessionToken.isEmpty
                ? 'Missing'
                : 'Active',
          ),
        ],
      ),
    );
  }

  String _getTransmissionType(dynamic category) {
    try {
      if (category is Map) {
        if (category['transmission'] != null) {
          return category['transmission'].toString();
        }

        if (category['transmissionType'] != null) {
          return category['transmissionType'].toString();
        }

        if (category['transmission_type'] != null) {
          return category['transmission_type'].toString();
        }

        if (category['isAutomatic'] != null) {
          return category['isAutomatic'] == true
              ? 'Auto'
              : 'Manual';
        }
      }

      final dynamic value = category;

      try {
        final transmission = value.transmission;

        if (transmission != null) {
          return transmission.toString();
        }
      } catch (_) {}

      try {
        final transmissionType = value.transmissionType;

        if (transmissionType != null) {
          return transmissionType.toString();
        }
      } catch (_) {}
    } catch (_) {}

    return 'Auto / Manual';
  }

  Widget _vehicleCategoriesSection() {
    final categories = widget.license.vehicleCategories;

    if (categories.isEmpty) {
      return _liquidGreyCard(
        radius: 25,
        child: const Column(
          children: [
            Icon(
              Icons.directions_car_outlined,
              color: _darkCardTextColor,
              size: 30,
            ),
            SizedBox(height: 8),
            Text(
              'No vehicle categories found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _darkCardTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Categories',
          style: TextStyle(
            color: AppTheme.policeBlue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...categories.map(
          (category) {
            final transmission = _getTransmissionType(category);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _liquidGreyCard(
                radius: 25,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.directions_car_outlined,
                      title: 'Class',
                      value: category.vehicleClass.isEmpty
                          ? 'N/A'
                          : category.vehicleClass,
                      titleColor: _darkCardTextColor,
                      valueColor: _darkCardTextColor,
                      iconColor: _darkCardTextColor,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.settings_suggest_outlined,
                      title: 'Transmission',
                      value: transmission,
                      titleColor: _darkCardTextColor,
                      valueColor: _darkCardTextColor,
                      iconColor: _darkCardTextColor,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      title: 'Issue Date',
                      value: _formatDate(category.issueDate),
                      titleColor: _darkCardTextColor,
                      valueColor: _darkCardTextColor,
                      iconColor: _darkCardTextColor,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.event_available_outlined,
                      title: 'Expiry Date',
                      value: _formatDate(category.expiryDate),
                      titleColor: _darkCardTextColor,
                      valueColor: _darkCardTextColor,
                      iconColor: _darkCardTextColor,
                    ),
                    if (category.restriction != null &&
                        category.restriction!
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.info_outline,
                        title: 'Restriction',
                        value: category.restriction!,
                        titleColor: _darkCardTextColor,
                        valueColor: _darkCardTextColor,
                        iconColor: _darkCardTextColor,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _headerCard() {
    final license = widget.license;

    final hasImage = license.imageUrl != null &&
        license.imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
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
              borderRadius: BorderRadius.circular(25),
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
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: 0.30,
                      ),
                      width: 1.2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: hasImage
                        ? Image.network(
                            license.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return _buildPlaceholderImage();
                            },
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        license.licenseNumber.isEmpty
                            ? 'License Verified'
                            : license.licenseNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        license.driverName.isEmpty
                            ? 'Driver details loaded from backend.'
                            : license.driverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _extraDetailsSection() {
    final license = widget.license;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'License Details',
          style: TextStyle(
            color: AppTheme.policeBlue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _liquidGreyCard(
          radius: 25,
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                title: 'Issue Date',
                value: _formatDate(license.issueDate),
                titleColor: _darkCardTextColor,
                valueColor: _darkCardTextColor,
                iconColor: _darkCardTextColor,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.event_available_outlined,
                title: 'Expiry Date',
                value: _formatDate(license.expiryDate),
                titleColor: _darkCardTextColor,
                valueColor: _darkCardTextColor,
                iconColor: _darkCardTextColor,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.timer_outlined,
                title: 'Temporary Expiry',
                value: _formatDate(
                  license.temporaryLicenseExpiry,
                ),
                titleColor: _darkCardTextColor,
                valueColor: _darkCardTextColor,
                iconColor: _darkCardTextColor,
              ),
              if (license.dateOfBirth != null) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.cake_outlined,
                  title: 'Date of Birth',
                  value: _formatDate(license.dateOfBirth),
                  titleColor: _darkCardTextColor,
                  valueColor: _darkCardTextColor,
                  iconColor: _darkCardTextColor,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _vehicleCategoriesSection(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FBFF),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'License Preview',
          style: TextStyle(
            color: AppTheme.policeBlue,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
          child: BackdropGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                24,
              ),
              children: [
                _headerCard(),
                const SizedBox(height: 12),
                _scanTimerBanner(),
                const SizedBox(height: 12),
                _currentValuesCard(statusColor),
                const SizedBox(height: 12),
                if (_hasCriticalStatus) ...[
                  _glassCard(
                    radius: 25,
                    color: AppTheme.errorRed.withValues(
                      alpha: 0.08,
                    ),
                    borderColor: AppTheme.errorRed.withValues(
                      alpha: 0.28,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.errorRed,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'License is ${widget.license.status.toUpperCase()}. Fine issuance is blocked.',
                            style: const TextStyle(
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _extraDetailsSection(),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _remaining == Duration.zero ||
                            _hasCriticalStatus
                        ? null
                        : _openOffenseSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.policeBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      _hasCriticalStatus
                          ? 'Fine Issuance Blocked'
                          : 'Continue to Offenses',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.value,
    this.icon,
    this.valueColor,
    this.titleColor,
    this.iconColor,
  });

  final String title;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final Color? titleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: iconColor ?? AppTheme.policeBlue,
            size: 19,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: titleColor ?? AppTheme.textGray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? AppTheme.policeBlue,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}