import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class DistrictStatisticsScreen extends StatelessWidget {
  const DistrictStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statistics = [
      const _StatisticCardData(
        title: 'Total Fines',
        value: '128',
        subtitle: 'Issued in district',
        icon: Icons.receipt_long_outlined,
      ),
      const _StatisticCardData(
        title: 'Court Cases',
        value: '12',
        subtitle: 'Pending review',
        icon: Icons.gavel_outlined,
      ),
      const _StatisticCardData(
        title: 'Active Officers',
        value: '08',
        subtitle: 'Currently assigned',
        icon: Icons.local_police_outlined,
      ),
      const _StatisticCardData(
        title: 'Total Points',
        value: '342',
        subtitle: 'Demerit points issued',
        icon: Icons.scoreboard_outlined,
      ),
    ];

    final recentSummary = [
      const _SummaryRowData(
        title: 'Speeding violations',
        value: '46',
        icon: Icons.speed_outlined,
      ),
      const _SummaryRowData(
        title: 'Reckless driving',
        value: '31',
        icon: Icons.warning_amber_rounded,
      ),
      const _SummaryRowData(
        title: 'DUI / Court offenses',
        value: '12',
        icon: Icons.balance_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'District Statistics',
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
                            'View fine activity, officer status, court cases, and violation summary for your district.',
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
                    const Text(
                      'Key Statistics',
                      style: TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      itemCount: statistics.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth < 390 ? 1 : 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: constraints.maxWidth < 390 ? 2.45 : 1.25,
                      ),
                      itemBuilder: (context, index) {
                        return _StatisticCard(data: statistics[index]);
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Violation Summary',
                      style: TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
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
                        children: recentSummary
                            .map(
                              (item) => Padding(
                            padding: EdgeInsets.only(
                              bottom: item == recentSummary.last ? 0 : 14,
                            ),
                            child: _SummaryRow(data: item),
                          ),
                        )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _BackendNoticeCard(),
                    const SizedBox(height: 28),
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

class _SummaryRowData {
  const _SummaryRowData({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({required this.data});

  final _StatisticCardData data;

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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.title,
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.data});

  final _SummaryRowData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            data.icon,
            color: AppTheme.primaryBlack,
            size: 23,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            data.title,
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlack,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            data.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _BackendNoticeCard extends StatelessWidget {
  const _BackendNoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.primaryBlack,
            size: 23,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'These values are sample UI data. Real district statistics will load from the backend API in the next integration phase.',
              style: TextStyle(
                color: AppTheme.textGray,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}