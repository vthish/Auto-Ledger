import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';

class TrafficOfficerListScreen extends StatelessWidget {
  const TrafficOfficerListScreen({super.key});

  void _showPendingMessage(BuildContext context, String officerName) {
    AppErrorHandler.showPopup(
      context,
      message: '$officerName shift assignment will be connected next.',
      isError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final officers = [
      const _OfficerListItemData(
        name: 'Nimal Perera',
        badgeNumber: 'TRF-GALLE-100',
        status: 'No active shift',
        shiftTime: 'Shift not assigned',
        isActive: false,
      ),
      const _OfficerListItemData(
        name: 'Kamal Silva',
        badgeNumber: 'TRF-GALLE-101',
        status: 'Active shift',
        shiftTime: '08:00 AM - 05:00 PM',
        isActive: true,
      ),
      const _OfficerListItemData(
        name: 'Sahan Fernando',
        badgeNumber: 'TRF-GALLE-102',
        status: 'No active shift',
        shiftTime: 'Shift not assigned',
        isActive: false,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Traffic Officers',
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
                            Icons.groups_2_outlined,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(height: 18),
                          Text(
                            'District Officers',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'View traffic officers assigned to your district and manage their duty shifts.',
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
                            'Officer List',
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
                            '${officers.length} Officers',
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
                    ...officers.map(
                          (officer) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _OfficerListCard(
                          officer: officer,
                          onAssignShift: () => _showPendingMessage(
                            context,
                            officer.name,
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

class _OfficerListItemData {
  const _OfficerListItemData({
    required this.name,
    required this.badgeNumber,
    required this.status,
    required this.shiftTime,
    required this.isActive,
  });

  final String name;
  final String badgeNumber;
  final String status;
  final String shiftTime;
  final bool isActive;
}

class _OfficerListCard extends StatelessWidget {
  const _OfficerListCard({
    required this.officer,
    required this.onAssignShift,
  });

  final _OfficerListItemData officer;
  final VoidCallback onAssignShift;

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
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_police_outlined,
                  color: AppTheme.primaryBlack,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      officer.name,
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      officer.badgeNumber,
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
                  color: officer.isActive
                      ? AppTheme.primaryBlack
                      : AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  officer.isActive ? 'Active' : 'Idle',
                  style: TextStyle(
                    color:
                    officer.isActive ? Colors.white : AppTheme.primaryBlack,
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
            child: Row(
              children: [
                Icon(
                  officer.isActive
                      ? Icons.schedule_rounded
                      : Icons.schedule_outlined,
                  color: AppTheme.primaryBlack,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        officer.status,
                        style: const TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        officer.shiftTime,
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
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onAssignShift,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlack,
                side: const BorderSide(color: AppTheme.primaryBlack),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: const Icon(Icons.schedule_send_outlined, size: 20),
              label: const Text(
                'Assign Shift',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}