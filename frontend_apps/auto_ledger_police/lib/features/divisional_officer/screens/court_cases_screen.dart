import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  List<FineModel> _cachedCourtCases = [];
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _courtCasesFuture = _loadCourtCases();
  }

  Future<List<FineModel>> _loadCourtCases() async {
    final courtCases = await _fineService.getDistrictCourtCases();
    _cachedCourtCases = courtCases;
    return courtCases;
  }

  Future<void> _refreshCourtCases() async {
    final future = _loadCourtCases();

    setState(() {
      _courtCasesFuture = future;
    });

    try {
      await future;
    } catch (_) {}
  }

  Future<void> _confirmResolve({
    required FineModel courtCase,
    required String verdict,
  }) async {
    final isActivate = verdict == 'ACTIVE';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B1A30).withValues(alpha: 0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isActivate
                        ? const Color(0xFF059669).withValues(alpha: 0.1)
                        : AppTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isActivate
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                    color: isActivate
                        ? const Color(0xFF059669)
                        : AppTheme.errorRed,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isActivate ? 'Activate License?' : 'Revoke License?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF0B1A30),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isActivate
                      ? 'This will mark the court case as resolved and activate this license.'
                      : 'This will mark the court case as resolved and revoke this license.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0B1A30),
                          side: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActivate
                              ? const Color(0xFF059669)
                              : AppTheme.errorRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        child: Text(
                          isActivate ? 'Activate' : 'Revoke',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        verdict: verdict,
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

  Widget _buildContent({
    required AsyncSnapshot<List<FineModel>> snapshot,
    required double horizontalPadding,
  }) {
    final snapshotData = snapshot.data;
    final courtCases = snapshotData ?? _cachedCourtCases;

    final isFirstLoad = snapshot.connectionState == ConnectionState.waiting &&
        _cachedCourtCases.isEmpty &&
        snapshotData == null;

    if (snapshot.hasError && courtCases.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        children: [
          const SizedBox(height: 16),
          const _HeaderCard(),
          const SizedBox(height: 24),
          _ErrorCard(
            onRetry: _refreshCourtCases,
            message: snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Unable to load court cases.',
          ),
          const SizedBox(height: 32),
        ],
      );
    }

    if (isFirstLoad) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        children: const [
          SizedBox(height: 160),
          Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0B1A30),
              strokeWidth: 3,
            ),
          ),
        ],
      );
    }

    final itemCount = courtCases.isEmpty ? 6 : courtCases.length + 5;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) return const SizedBox(height: 16);
        if (index == 1) return const _HeaderCard();
        if (index == 2) return const SizedBox(height: 24);
        if (index == 3) {
          return _CourtCaseSectionHeader(count: courtCases.length);
        }
        if (index == 4) return const SizedBox(height: 14);

        if (courtCases.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 32),
            child: _EmptyCard(),
          );
        }

        final caseIndex = index - 5;
        final courtCase = courtCases[caseIndex];
        final isLast = caseIndex == courtCases.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 32 : 14),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 12),
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(
                  color: Color(0xFF0B1A30),
                ),
                centerTitle: false,
                title: const Text(
                  'Court Cases',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0B1A30),
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding =
                        constraints.maxWidth < 380 ? 20.0 : 24.0;

                    return FutureBuilder<List<FineModel>>(
                      future: _courtCasesFuture,
                      builder: (context, snapshot) {
                        return _buildContent(
                          snapshot: snapshot,
                          horizontalPadding: horizontalPadding,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1A30),
            Color(0xFF162A4A),
            Color(0xFF0F213C),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: const Icon(
              Icons.gavel_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Court Cases',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review and resolve court cases',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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

class _CourtCaseSectionHeader extends StatelessWidget {
  const _CourtCaseSectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Pending Cases',
          style: TextStyle(
            color: Color(0xFF0B1A30),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count Cases',
            style: const TextStyle(
              color: Color(0xFF0B1A30),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
    final licenseNumber = courtCase.licenseNumber.isEmpty
        ? 'Unknown License'
        : courtCase.licenseNumber;
    final officerName = courtCase.officerName.isEmpty
        ? 'Unknown Officer'
        : courtCase.officerName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1A30).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0B1A30).withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.balance_rounded,
                  color: Color(0xFF0B1A30),
                  size: 24,
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
                        color: Color(0xFF0B1A30),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      officerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    color: AppTheme.errorRed,
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
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
                child: OutlinedButton(
                  onPressed: isResolving ? null : onActivate,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    side: BorderSide(
                      color: isResolving
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF059669),
                    ),
                    backgroundColor:
                        const Color(0xFF059669).withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    minimumSize: const Size(0, 46),
                  ),
                  child: const Text(
                    'Activate',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isResolving ? null : onRevoke,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    minimumSize: const Size(0, 46),
                  ),
                  child: const Text(
                    'Revoke',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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
          color: const Color(0xFF0B1A30),
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
              color: Color(0xFF0B1A30),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppTheme.errorRed.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorRed,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.errorRed,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
              side: const BorderSide(color: AppTheme.errorRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.gavel_outlined,
            color: Color(0xFF0B1A30),
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'No pending court cases',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0B1A30),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Court cases assigned to your district will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}