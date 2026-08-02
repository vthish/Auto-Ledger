import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/fine_model.dart';
import 'qr_scanner_screen.dart';

class FineResultScreen extends StatelessWidget {
  const FineResultScreen({
    super.key,
    required this.result,
    required this.licenseNumber,
  });

  final FineIssueResultModel result;
  final String licenseNumber;

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  double get _totalAmount {
    return result.fineDetails.fold<double>(0, (sum, fine) => sum + fine.amount);
  }

  int get _totalPoints {
    return result.fineDetails.fold<int>(0, (sum, fine) => sum + fine.points);
  }

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.trafficOfficerDashboard,
      (route) => false,
    );
  }

  void _issueAnotherFine(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(),
      ),
    );
  }

  Color _statusColor() {
    final status = result.licenseStatus.toUpperCase();
    if (status == 'ACTIVE') return AppTheme.successGreen;
    if (status == 'SUSPENDED' || status == 'REVOKED') return AppTheme.errorRed;
    return AppTheme.primaryBlack;
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double radius = 28,
    Color? color,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.38),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Fine Result',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth < 380 ? 16.0 : 20.0;

            return Container(
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
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 18,
                  bottom: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _glassCard(
                        radius: 32,
                        color: AppTheme.primaryBlack.withValues(alpha: 0.96),
                        borderColor: Colors.white.withValues(alpha: 0.14),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Fine Issued Successfully',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              licenseNumber.isEmpty
                                  ? 'The fine has been recorded.'
                                  : licenseNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _glassCard(
                        radius: 30,
                        child: Column(
                          children: [
                            _InfoRow(
                              title: 'License Status',
                              value: result.licenseStatus.isEmpty
                                  ? '-'
                                  : result.licenseStatus,
                              valueColor: statusColor,
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              title: 'Accumulated Points',
                              value: '${result.accumulatedPoints}',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              title: 'Fine Points',
                              value: '${_totalPoints}',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              title: 'Total Amount',
                              value: 'LKR ${_totalAmount.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              title: 'Temporary Expiry',
                              value: _formatDate(result.temporaryLicenseExpiry),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Fine Details',
                        style: TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (result.fineDetails.isEmpty)
                        _glassCard(
                          radius: 28,
                          child: const Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: AppTheme.primaryBlack,
                                size: 34,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Fine issued, but no fine details returned',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.primaryBlack,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...result.fineDetails.map(
                          (fine) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _FineDetailCard(fine: fine),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => _issueAnotherFine(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlack,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                          label: const Text(
                            'Issue Another Fine',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => _goToDashboard(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlack,
                            side: const BorderSide(color: AppTheme.primaryBlack),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Back to Dashboard',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
              color: valueColor ?? AppTheme.primaryBlack,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _FineDetailCard extends StatelessWidget {
  const _FineDetailCard({required this.fine});

  final FineModel fine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fine.offenseName.isEmpty ? 'Traffic Offense' : fine.offenseName,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            title: 'Status',
            value: fine.status.isEmpty ? 'PENDING' : fine.status,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Points',
            value: '${fine.points}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Amount',
            value: 'LKR ${fine.amount.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }
}