import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/fine_model.dart';
import '../services/fine_service.dart';

class CourtCasesScreen extends StatefulWidget {
  const CourtCasesScreen({super.key});

  @override
  State<CourtCasesScreen> createState() => _CourtCasesScreenState();
}

class _CourtCasesScreenState extends State<CourtCasesScreen> {
  final _fineService = FineService();

  late Future<List<FineModel>> _courtCasesFuture;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _courtCasesFuture = _loadCourtCases();
  }

  Future<List<FineModel>> _loadCourtCases() {
    return _fineService.getDistrictCourtCases();
  }

  Future<void> _refreshCourtCases() async {
    setState(() {
      _courtCasesFuture = _loadCourtCases();
    });

    await _courtCasesFuture;
  }

  Future<void> _confirmResolve({
    required FineModel courtCase,
    required String verdict,
  }) async {
    final isActivate = verdict == 'ACTIVE';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Text(
            isActivate ? 'Activate License?' : 'Revoke License?',
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            isActivate
                ? 'This will mark the court case as resolved and activate this license.'
                : 'This will mark the court case as resolved and revoke this license.',
            style: const TextStyle(
              color: AppTheme.textGray,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isActivate ? AppTheme.successGreen : AppTheme.errorRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                isActivate ? 'Activate' : 'Revoke',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _resolveCourtCase(
      fineId: courtCase.id,
      verdict: verdict,
    );
  }

  Future<void> _resolveCourtCase({
    required String fineId,
    required String verdict,
  }) async {
    if (_isResolving) return;

    setState(() => _isResolving = true);

    try {
      await _fineService.resolveCourtCase(
        fineId: fineId,
        finalVerdict: verdict,
      );

      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: verdict == 'ACTIVE'
            ? 'License activated successfully.'
            : 'License revoked successfully.',
        isError: false,
      );

      await _refreshCourtCases();
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
        message: 'Unable to resolve court case. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';

    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  String _formatAmount(double amount) {
    return 'LKR ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Court Cases',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshCourtCases,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 26.0;

            return RefreshIndicator(
              color: AppTheme.primaryBlack,
              onRefresh: _refreshCourtCases,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: FutureBuilder<List<FineModel>>(
                    future: _courtCasesFuture,
                    builder: (context, snapshot) {
                      final isLoading =
                          snapshot.connectionState == ConnectionState.waiting;
                      final courtCases = snapshot.data ?? <FineModel>[];

                      return Column(
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
                          if (isLoading)
                            const _LoadingCard()
                          else if (snapshot.hasError)
                            _ErrorCard(
                              onRetry: _refreshCourtCases,
                              message: snapshot.error is ApiException
                                  ? (snapshot.error as ApiException).message
                                  : 'Unable to load court cases.',
                            )
                          else if (courtCases.isEmpty)
                              const _EmptyCard()
                            else
                              ...courtCases.map(
                                    (courtCase) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _CourtCaseCard(
                                    courtCase: courtCase,
                                    issuedDate: _formatDate(courtCase.issuedAt),
                                    amount: _formatAmount(courtCase.amount),
                                    isResolving: _isResolving,
                                    onActivate: () => _confirmResolve(
                                      courtCase: courtCase,
                                      verdict: 'ACTIVE',
                                    ),
                                    onRevoke: () => _confirmResolve(
                                      courtCase: courtCase,
                                      verdict: 'REVOKED',
                                    ),
                                  ),
                                ),
                              ),
                          const SizedBox(height: 18),
                        ],
                      );
                    },
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

class _CourtCaseCard extends StatelessWidget {
  const _CourtCaseCard({
    required this.courtCase,
    required this.issuedDate,
    required this.amount,
    required this.isResolving,
    required this.onActivate,
    required this.onRevoke,
  });

  final FineModel courtCase;
  final String issuedDate;
  final String amount;
  final bool isResolving;
  final VoidCallback onActivate;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final licenseNumber =
    courtCase.licenseNumber.isEmpty ? 'Unknown License' : courtCase.licenseNumber;
    final officerName =
    courtCase.officerName.isEmpty ? 'Unknown Officer' : courtCase.officerName;

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
                      licenseNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      officerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                  value: courtCase.id,
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
                  value: issuedDate,
                ),
                const SizedBox(height: 10),
                _CaseInfoRow(
                  icon: Icons.scoreboard_outlined,
                  title: 'Points',
                  value: '${courtCase.points}',
                ),
                const SizedBox(height: 10),
                _CaseInfoRow(
                  icon: Icons.payments_outlined,
                  title: 'Amount',
                  value: amount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isResolving ? null : onActivate,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successGreen,
                    disabledForegroundColor: AppTheme.textGray,
                    side: BorderSide(
                      color: isResolving
                          ? AppTheme.borderGray
                          : AppTheme.successGreen,
                    ),
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
                  onPressed: isResolving ? null : onRevoke,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.borderGray,
                    disabledForegroundColor: AppTheme.textGray,
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
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryBlack,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.onRetry,
    required this.message,
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.errorRed),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorRed,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.errorRed,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
              side: const BorderSide(color: AppTheme.errorRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Retry',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.gavel_outlined,
            color: AppTheme.primaryBlack,
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'No pending court cases',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Court cases assigned to your district will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}