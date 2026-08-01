import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/fine_model.dart';
import '../services/traffic_fine_service.dart';

class FineHistoryScreen extends StatefulWidget {
  const FineHistoryScreen({super.key});

  @override
  State<FineHistoryScreen> createState() => _FineHistoryScreenState();
}

class _FineHistoryScreenState extends State<FineHistoryScreen> {
  final _service = TrafficFineService();

  late Future<List<FineModel>> _future;
  List<FineModel> _cachedFines = const [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _loadData() {
    setState(() {
      _future = _load();
    });
  }

  Future<List<FineModel>> _load() async {
    final fines = List<FineModel>.of(
      await _service.getFineHistory(),
      growable: false,
    );

    final sortedFines = fines.toList(growable: false)
      ..sort((a, b) {
        final aDate =
            a.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

    _cachedFines = sortedFines;

    return sortedFines;
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }

    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final displayHour =
        local.hour % 12 == 0 ? 12 : local.hour % 12;

    return '${local.year}-$month-$day $displayHour:$minute $ampm';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppTheme.successGreen;
      case 'PENDING':
        return Colors.orange;
      case 'OVERDUE':
      case 'COURT_CASE':
      case 'COURT':
      case 'REVOKED':
      case 'SUSPENDED':
        return AppTheme.errorRed;
      default:
        return AppTheme.textGray;
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
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FBFF),
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.policeBlue,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Fine History',
            style: TextStyle(
              color: AppTheme.policeBlue,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
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
            child: FutureBuilder<List<FineModel>>(
              future: _future,
              builder: (context, snapshot) {
                final fines = snapshot.data ?? _cachedFines;
                final isLoading =
                    snapshot.connectionState ==
                            ConnectionState.waiting &&
                        fines.isEmpty;

                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.policeBlue,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                if (snapshot.hasError && fines.isEmpty) {
                  final message = snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'Unable to load fine history.';

                  return _ErrorState(
                    message: message,
                    onRetry: _loadData,
                  );
                }

                if (fines.isEmpty) {
                  return const _EmptyState();
                }

                return BackdropGroup(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      24,
                    ),
                    itemCount: fines.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _FineHistoryCard(
                        fine: fines[index],
                        formatDate: _formatDate,
                        statusColor: _statusColor,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FineHistoryCard extends StatelessWidget {
  const _FineHistoryCard({
    required this.fine,
    required this.formatDate,
    required this.statusColor,
  });

  final FineModel fine;
  final String Function(DateTime? dateTime) formatDate;
  final Color Function(String status) statusColor;

  @override
  Widget build(BuildContext context) {
    final title = fine.offenseName.isEmpty
        ? 'Traffic Offense'
        : fine.offenseName;
    final color = statusColor(fine.status);
    final status =
        fine.status.isEmpty ? 'PENDING' : fine.status;
    final scanLocation = fine.scanLocation.trim();
    final officerName = fine.officerName.trim();
    final officerBadgeNumber =
        fine.officerBadgeNumber.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(
              0xFFE4E8ED,
            ).withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.62),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.policeBlue.withValues(
                  alpha: 0.055,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.policeBlue,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withValues(alpha: 0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Chip(
                    label:
                        'License: ${fine.licenseNumber.isEmpty ? '-' : fine.licenseNumber}',
                  ),
                  if (officerName.isNotEmpty)
                    _Chip(
                      label: 'Officer: $officerName',
                    ),
                  _Chip(
                    label: 'Points: ${fine.points}',
                  ),
                  _Chip(
                    label:
                        'Amount: LKR ${fine.amount.toStringAsFixed(2)}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final issuedCard = _MetaRow(
                    title: 'Issued',
                    value: formatDate(fine.issuedAt),
                  );
                  final dueDateCard = _MetaRow(
                    title: 'Due Date',
                    value: formatDate(fine.dueDate),
                  );

                  if (constraints.maxWidth < 290) {
                    return Column(
                      children: [
                        issuedCard,
                        const SizedBox(height: 8),
                        dueDateCard,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: issuedCard),
                      const SizedBox(width: 8),
                      Expanded(child: dueDateCard),
                    ],
                  );
                },
              ),
              if (scanLocation.isNotEmpty) ...[
                const SizedBox(height: 6),
                _MetaRow(
                  title: 'Scan Location',
                  value: scanLocation,
                  maxLines: 2,
                ),
              ],
              if (officerBadgeNumber.isNotEmpty) ...[
                const SizedBox(height: 6),
                _MetaRow(
                  title: 'Badge Number',
                  value: officerBadgeNumber,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.title,
    required this.value,
    this.maxLines = 1,
  });

  final String title;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFE8EBEF,
        ).withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.50),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '-' : value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.policeBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFE8EBEF,
        ).withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.46),
          width: 0.7,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.policeBlue,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppTheme.textGray,
          ),
          SizedBox(height: 12),
          Text(
            'No fine history found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.policeBlue,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.errorRed,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.policeBlue,
                side: const BorderSide(
                  color: AppTheme.policeBlue,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}