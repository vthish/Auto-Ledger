import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/license_model.dart';
import '../../../models/offense_model.dart';
import '../services/traffic_fine_service.dart';

const Color _selectedOffenseGlassColor = Color(0xFFE4E8ED);
const Color _selectedOffenseBorderColor = Color(0xFFC7CDD5);

class FineConfirmationScreen extends StatefulWidget {
  const FineConfirmationScreen({
    super.key,
    required this.qrToken,
    required this.license,
    required this.selectedOffenses,
  });

  final String qrToken;
  final LicenseModel license;
  final List<OffenseModel> selectedOffenses;

  @override
  State<FineConfirmationScreen> createState() =>
      _FineConfirmationScreenState();
}

class _FineConfirmationScreenState
    extends State<FineConfirmationScreen> {
  final _trafficFineService = TrafficFineService();
  final _commentController = TextEditingController();

  Timer? _timer;
  late final DateTime _expiresAt;

  bool _isLoading = false;
  bool _expiredDialogShown = false;
  Duration _remaining = Duration.zero;

  String get _sessionId {
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

    if (_remaining == Duration.zero) {
      _scheduleExpiredDialog();
    } else {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateRemaining(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _commentController.dispose();
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

    if (_remaining != safeRemaining) {
      setState(() {
        _remaining = safeRemaining;
      });
    }

    if (safeRemaining == Duration.zero) {
      _scheduleExpiredDialog();
    }
  }

  String _offenseKey(OffenseModel offense) {
    final id = offense.id.trim();

    if (id.isNotEmpty) {
      return id;
    }

    return offense.code.trim();
  }

  double get _totalAmount {
    return widget.selectedOffenses.fold<double>(
      0,
      (total, offense) => total + offense.amount,
    );
  }

  int get _totalPoints {
    return widget.selectedOffenses.fold<int>(
      0,
      (total, offense) => total + offense.points,
    );
  }

  Future<void> _showExpiredDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 24,
                sigmaY: 24,
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.errorRed.withValues(
                      alpha: 0.18,
                    ),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.errorRed.withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.timer_off_rounded,
                        color: AppTheme.errorRed,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Session Expired',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.policeBlue,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This QR verification window has expired.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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
                            borderRadius: BorderRadius.circular(20),
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

  Future<bool> _confirmIssueFine() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 24,
                sigmaY: 24,
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(30),
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
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.policeBlue,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.policeBlue.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fact_check_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Issue Fine?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.policeBlue,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will submit the selected offenses and update the driver license status if needed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label:
                              '${widget.selectedOffenses.length} Offenses',
                          icon: Icons.receipt_long_outlined,
                        ),
                        _Chip(
                          label: '$_totalPoints Points',
                          icon: Icons.bolt_rounded,
                        ),
                        _Chip(
                          label:
                              'LKR ${_totalAmount.toStringAsFixed(2)}',
                          icon: Icons.payments_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(false);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.policeBlue,
                              side: BorderSide(
                                color: AppTheme.policeBlue
                                    .withValues(alpha: 0.25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(25),
                              ),
                              minimumSize:
                                  const Size.fromHeight(44),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.policeBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(25),
                              ),
                              minimumSize:
                                  const Size.fromHeight(44),
                            ),
                            child: const Text(
                              'Issue Fine',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
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
          ),
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _issueFine() async {
    if (_isLoading) {
      return;
    }

    if (widget.selectedOffenses.isEmpty) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please select at least one offense.',
      );
      return;
    }

    final confirmed = await _confirmIssueFine();

    if (!confirmed || !mounted) {
      return;
    }

    final expired = widget.license.scanExpiresAt != null &&
        widget.license.scanExpiresAt!.isBefore(
          DateTime.now(),
        );

    if (expired || _remaining == Duration.zero) {
      await _showExpiredDialog();
      return;
    }

    final status = widget.license.status.trim().toUpperCase();

    if (status == 'SUSPENDED' || status == 'REVOKED') {
      AppErrorHandler.showPopup(
        context,
        message:
            'Suspended and revoked licenses cannot proceed to fines.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _trafficFineService.issueFine(
        sessionId: _sessionId,
        licenseId: widget.license.id.trim().isEmpty
            ? null
            : widget.license.id.trim(),
        offenseIds: widget.selectedOffenses
            .map(_offenseKey)
            .where((id) => id.isNotEmpty)
            .toList(growable: false),
        comment: _commentController.text.trim(),
        license: widget.license,
        selectedOffenses: widget.selectedOffenses,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.trafficOfficerDashboard,
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      AppErrorHandler.showPopup(
        context,
        message: error.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      AppErrorHandler.showPopup(
        context,
        message: 'Unable to issue fine. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 25,
    Color? color,
    Color? borderColor,
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
                  AppTheme.policeBlue.withValues(
                    alpha: 0.12,
                  ),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor ??
                    AppTheme.policeBlue.withValues(
                      alpha: 0.05,
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

  Widget _headerCard() {
    return Container(
      decoration: BoxDecoration(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F2B5C),
                    Color(0xFF1E40AF),
                    Color(0xFF1D3557),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.license.licenseNumber.isEmpty
                        ? 'Confirm Fine'
                        : widget.license.licenseNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.license.driverName.isEmpty
                        ? 'Review selected offenses.'
                        : widget.license.driverName,
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
      ),
    );
  }

  Widget _summaryCard() {
    return _glassCard(
      radius: 25,
      child: Column(
        children: [
          _InfoRow(
            title: 'Offenses Count',
            value: '${widget.selectedOffenses.length}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Total Penalty Points',
            value: '$_totalPoints',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Total Fine Amount',
            value:
                'LKR ${_totalAmount.toStringAsFixed(2)}',
            valueColor: AppTheme.policeBlue,
          ),
        ],
      ),
    );
  }

  Widget _notesCard() {
    return _glassCard(
      radius: 32,
      padding: EdgeInsets.zero,
      child: TextField(
        controller: _commentController,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.policeBlue,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          hintText: 'Add an optional officer note here...',
          hintStyle: TextStyle(
            color: AppTheme.textGray,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.edit_note_rounded,
            color: AppTheme.policeBlue,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _selectedOffensesList() {
    return Column(
      children: widget.selectedOffenses
          .map(
            (offense) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SelectedOffenseCard(
                offense: offense,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FBFF),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Fine Confirmation',
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
                const SizedBox(height: 16),
                const Text(
                  'Review Fine Details',
                  style: TextStyle(
                    color: AppTheme.policeBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _summaryCard(),
                const SizedBox(height: 16),
                const Text(
                  'Officer Notes',
                  style: TextStyle(
                    color: AppTheme.policeBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _notesCard(),
                const SizedBox(height: 16),
                const Text(
                  'Selected Offenses',
                  style: TextStyle(
                    color: AppTheme.policeBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _selectedOffensesList(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _issueFine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.policeBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(24),
                      ),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Issuing Fine...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Issue Fine',
                            style: TextStyle(
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
    this.valueColor,
  });

  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textGray,
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
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedOffenseCard extends StatelessWidget {
  const _SelectedOffenseCard({
    required this.offense,
  });

  final OffenseModel offense;

  @override
  Widget build(BuildContext context) {
    final offenseName = offense.name.trim().isEmpty
        ? 'Traffic Offense'
        : offense.name.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: _selectedOffenseGlassColor.withValues(
              alpha: 0.68,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _selectedOffenseBorderColor.withValues(
                alpha: 0.94,
              ),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offenseName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _Chip(
                    label: '${offense.points} pts',
                    icon: Icons.bolt_rounded,
                  ),
                  _Chip(
                    label:
                        'LKR ${offense.amount.toStringAsFixed(2)}',
                    icon: Icons.payments_outlined,
                  ),
                  if (offense.isCourtCase)
                    const _Chip(
                      label: 'Court Case',
                      icon: Icons.gavel_rounded,
                      color: AppTheme.errorRed,
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    this.color,
  });

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.policeBlue;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: chipColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}