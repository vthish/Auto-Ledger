import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/fine_model.dart';
import '../services/fine_service.dart';

class DistrictStatisticsScreen extends StatefulWidget {
  const DistrictStatisticsScreen({super.key});

  @override
  State<DistrictStatisticsScreen> createState() =>
      _DistrictStatisticsScreenState();
}

class _DistrictStatisticsScreenState extends State<DistrictStatisticsScreen> {
  final _fineService = FineService();

  late Future<DistrictStatisticsModel> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _loadStatistics();
  }

  Future<DistrictStatisticsModel> _loadStatistics() {
    return _fineService.getDistrictStatistics();
  }

  Future<void> _refreshStatistics() async {
    setState(() {
      _statisticsFuture = _loadStatistics();
    });

    await _statisticsFuture;
  }

  String _formatRevenue(double value) {
    return 'LKR ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'District Statistics',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshStatistics,
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
              onRefresh: _refreshStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: FutureBuilder<DistrictStatisticsModel>(
                    future: _statisticsFuture,
                    builder: (context, snapshot) {
                      final isLoading =
                          snapshot.connectionState == ConnectionState.waiting;

                      if (isLoading) {
                        return const Column(
                          children: [
                            SizedBox(height: 18),
                            _HeaderCard(),
                            SizedBox(height: 24),
                            _LoadingCard(),
                          ],
                        );
                      }

                      if (snapshot.hasError) {
                        return Column(
                          children: [
                            const SizedBox(height: 18),
                            const _HeaderCard(),
                            const SizedBox(height: 24),
                            _ErrorCard(
                              onRetry: _refreshStatistics,
                              message: snapshot.error is ApiException
                                  ? (snapshot.error as ApiException).message
                                  : 'Unable to load district statistics.',
                            ),
                          ],
                        );
                      }

                      final statistics = snapshot.data ??
                          const DistrictStatisticsModel(
                            totalFinesToday: 0,
                            revenueToday: 0,
                            pendingCourtCases: 0,
                          );

                      final cards = [
                        _StatisticCardData(
                          title: 'Fines Today',
                          value: '${statistics.totalFinesToday}',
                          subtitle: 'Issued today',
                          icon: Icons.receipt_long_outlined,
                        ),
                        _StatisticCardData(
                          title: 'Revenue Today',
                          value: _formatRevenue(statistics.revenueToday),
                          subtitle: 'Paid fine revenue',
                          icon: Icons.payments_outlined,
                        ),
                        _StatisticCardData(
                          title: 'Court Cases',
                          value: '${statistics.pendingCourtCases}',
                          subtitle: 'Pending review',
                          icon: Icons.gavel_outlined,
                        ),
                      ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          const _HeaderCard(),
                          const SizedBox(height: 24),
                          const Text(
                            'Key Statistics',
                            style: TextStyle(
                              color: AppTheme.primaryBlack,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...cards.map(
                                (card) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _StatisticCard(data: card),
                            ),
                          ),
                          const SizedBox(height: 28),
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

class _StatisticCardData {
  const _StatisticCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Icons.bar_chart_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 18),
          Text(
            'District Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'View today fine activity, paid revenue, and court pending cases for your district.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({required this.data});

  final _StatisticCardData data;

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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              data.icon,
              color: AppTheme.primaryBlack,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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