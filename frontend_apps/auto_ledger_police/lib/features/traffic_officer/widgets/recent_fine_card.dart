import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RecentFineCard extends StatelessWidget {
  const RecentFineCard({
    super.key,
    required this.fine,
  });

  final dynamic fine;

  @override
  Widget build(BuildContext context) {
    final licenseNo = fine['license']?['license_No'] ?? 'N/A';
    final offenseName = fine['offenses']?.isNotEmpty == true
        ? fine['offenses']['offenceCategory']['name'] ?? 'Unknown'
        : 'Unknown';
    final amount = fine['payment']?['amount'] ?? 0.0;
    final status = fine['status'] ?? 'PENDING';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.policeBlue.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_outlined,
              color: _getStatusColor(status),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'License: $licenseNo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.policeBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  offenseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${(amount).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppTheme.successGreen;
      case 'PENDING':
        return Colors.orange;
      case 'OVERDUE':
        return AppTheme.errorRed;
      default:
        return AppTheme.textGray;
    }
  }
}