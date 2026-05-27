import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';

class CourtCasesScreen extends StatelessWidget {
  const CourtCasesScreen({super.key});

  void _showResolveMessage(BuildContext context, String action) {
    AppErrorHandler.showPopup(
      context,
      message: '$action action will be connected with backend next.',
      isError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final courtCases = [
      const _CourtCaseData(
        fineId: 'FINE-1001',
        driverName: 'Kasun Perera',
        licenseNumber: 'B1234567',
        offenseName: 'Driving under influence',
        issuedDate: '2026-05-27',
        points: 10,
        status: 'COURT_PENDING',
      ),
      const _CourtCaseData(
        fineId: 'FINE-1002',
        driverName: 'Amal Silva',
        licenseNumber: 'B9988776',
        offenseName: 'Dangerous driving',
        issuedDate: '2026-05-26',
        points: 8,
        status: 'COURT_PENDING',
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Court Cases',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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
                    const SizedBox(height: 18),
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
                            Icons.gavel_outlined,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Pending Court Cases',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Review court pending fines and resolve license status after the final decision.',
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
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Pending Cases',
                            style: TextStyle(
                              color: AppTheme.primaryBlack,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            '${courtCases.length} Cases',
                            style: const TextStyle(
                              color: AppTheme.primaryBlack,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...courtCases.map(
                          (courtCase) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CourtCaseCard(
                          courtCase: courtCase,
                          onActivate: () => _showResolveMessage(
                            context,
                            'Activate license',
                          ),
                          onRevoke: () => _showResolveMessage(
                            context,
                            'Revoke license',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
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

class _CourtCaseData {
  const _CourtCaseData({
    required this.fineId,
    required this.driverName,
    required this.licenseNumber,
    required this.offenseName,
    required this.issuedDate,
    required this.points,
    required this.status,
  });

  final String fineId;
  final String driverName;
  final String licenseNumber;
  final String offenseName;
  final String issuedDate;
  final int points;
  final String status;
}

class _CourtCaseCard extends StatelessWidget {
  const _CourtCaseCard({
    required this.courtCase,
    required this.onActivate,
    required this.onRevoke,
  });

  final _CourtCaseData courtCase;
  final VoidCallback onActivate;
  final VoidCallback onRevoke;

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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlack,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.balance_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courtCase.driverName,
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      courtCase.licenseNumber,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _CaseInfoRow(
                  icon: Icons.receipt_long_outlined,
                  title: 'Fine ID',
                  value: courtCase.fineId,
                ),
                const SizedBox(height: 10),
                _CaseInfoRow(
                  icon: Icons.warning_amber_rounded,
                  title: 'Offense',
                  value: courtCase.offenseName,
                ),
                const SizedBox(height: 10),
                _CaseInfoRow(
                  icon: Icons.calendar_today_outlined,
                  title: 'Issued Date',
                  value: courtCase.issuedDate,
                ),
                const SizedBox(height: 10),
                _CaseInfoRow(
                  icon: Icons.scoreboard_outlined,
                  title: 'Points',
                  value: '${courtCase.points}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onActivate,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlack,
                    side: const BorderSide(color: AppTheme.primaryBlack),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 19),
                  label: const Text(
                    'Activate',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRevoke,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.block_outlined, size: 19),
                  label: const Text(
                    'Revoke',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaseInfoRow extends StatelessWidget {
  const _CaseInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryBlack,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}