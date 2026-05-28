import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/officer_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../services/officer_service.dart';

class AssignShiftScreen extends StatefulWidget {
  const AssignShiftScreen({super.key});

  @override
  State<AssignShiftScreen> createState() => _AssignShiftScreenState();
}

class _AssignShiftScreenState extends State<AssignShiftScreen> {
  final _officerService = OfficerService();

  late Future<List<OfficerModel>> _officersFuture;

  OfficerModel? _selectedOfficer;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _officersFuture = _officerService.getDistrictTrafficOfficers();
  }

  Future<void> _selectDateTime({required bool isStart}) async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDateTime ?? now) : (_endDateTime ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        isStart ? (_startDateTime ?? now) : (_endDateTime ?? now),
      ),
    );

    if (selectedTime == null) return;

    final dateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startDateTime = dateTime;
      } else {
        _endDateTime = dateTime;
      }
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Select date and time';

    final date =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
        ? 12
        : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$date  $hour:$minute $period';
  }

  Future<void> _handleAssignShift() async {
    if (_selectedOfficer == null) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please select a traffic officer.',
      );
      return;
    }

    if (_startDateTime == null) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please select shift start time.',
      );
      return;
    }

    if (_endDateTime == null) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please select shift end time.',
      );
      return;
    }

    if (!_endDateTime!.isAfter(_startDateTime!)) {
      AppErrorHandler.showPopup(
        context,
        message: 'End time must be after start time.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _officerService.assignShift(
        officerId: _selectedOfficer!.id,
        startTime: _startDateTime!,
        endTime: _endDateTime!,
      );

      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: 'Shift assigned successfully.',
        isError: false,
      );

      setState(() {
        _selectedOfficer = null;
        _startDateTime = null;
        _endDateTime = null;
        _officersFuture = _officerService.getDistrictTrafficOfficers();
      });
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
        message: 'Unable to assign shift. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshOfficers() async {
    setState(() {
      _officersFuture = _officerService.getDistrictTrafficOfficers();
      _selectedOfficer = null;
    });

    await _officersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Assign Shift',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshOfficers,
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
              onRefresh: _refreshOfficers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                              Icons.schedule_outlined,
                              color: Colors.white,
                              size: 34,
                            ),
                            SizedBox(height: 18),
                            Text(
                              'Assign Duty Shift',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Select a traffic officer and set the active duty start and end time.',
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppTheme.borderGray),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: FutureBuilder<List<OfficerModel>>(
                          future: _officersFuture,
                          builder: (context, snapshot) {
                            final isLoading = snapshot.connectionState ==
                                ConnectionState.waiting;
                            final officers = snapshot.data ?? <OfficerModel>[];

                            if (isLoading) {
                              return const _LoadingView();
                            }

                            if (snapshot.hasError) {
                              return _ErrorView(
                                message: snapshot.error is ApiException
                                    ? (snapshot.error as ApiException).message
                                    : 'Unable to load traffic officers.',
                                onRetry: _refreshOfficers,
                              );
                            }

                            if (officers.isEmpty) {
                              return const _EmptyView();
                            }

                            return Column(
                              children: [
                                _OfficerDropdown(
                                  officers: officers,
                                  selectedOfficer: _selectedOfficer,
                                  onChanged: (value) {
                                    setState(() => _selectedOfficer = value);
                                  },
                                ),
                                const SizedBox(height: 16),
                                _DateTimeSelector(
                                  title: 'Start Time',
                                  value: _formatDateTime(_startDateTime),
                                  icon: Icons.play_circle_outline_rounded,
                                  onTap: () => _selectDateTime(isStart: true),
                                ),
                                const SizedBox(height: 16),
                                _DateTimeSelector(
                                  title: 'End Time',
                                  value: _formatDateTime(_endDateTime),
                                  icon: Icons.stop_circle_outlined,
                                  onTap: () => _selectDateTime(isStart: false),
                                ),
                                const SizedBox(height: 24),
                                AppButton(
                                  text: 'Assign Shift',
                                  icon: Icons.schedule_send_outlined,
                                  isLoading: _isLoading,
                                  onPressed: _handleAssignShift,
                                ),
                              ],
                            );
                          },
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

class _OfficerDropdown extends StatelessWidget {
  const _OfficerDropdown({
    required this.officers,
    required this.selectedOfficer,
    required this.onChanged,
  });

  final List<OfficerModel> officers;
  final OfficerModel? selectedOfficer;
  final ValueChanged<OfficerModel?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedOfficer == null
        ? null
        : officers.where((officer) => officer.id == selectedOfficer!.id).isEmpty
        ? null
        : officers.firstWhere((officer) => officer.id == selectedOfficer!.id);

    return DropdownButtonFormField<OfficerModel>(
      initialValue: selected,
      isExpanded: true,
      items: officers.map((officer) {
        return DropdownMenuItem(
          value: officer,
          child: _OfficerDropdownText(officer: officer),
        );
      }).toList(),
      selectedItemBuilder: (context) {
        return officers.map((officer) {
          return _OfficerDropdownText(officer: officer);
        }).toList();
      },
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Traffic Officer',
        hintText: 'Select officer',
        prefixIcon: Icon(Icons.local_police_outlined),
      ),
    );
  }
}

class _OfficerDropdownText extends StatelessWidget {
  const _OfficerDropdownText({required this.officer});

  final OfficerModel officer;

  @override
  Widget build(BuildContext context) {
    final name = officer.name.isEmpty ? 'Unnamed Officer' : officer.name;
    final badgeNumber = officer.badgeNumber.isEmpty ? 'No badge' : officer.badgeNumber;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$name - $badgeNumber',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTimeSelector extends StatelessWidget {
  const _DateTimeSelector({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.lightGray,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppTheme.borderGray),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryBlack,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
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
              const Icon(
                Icons.calendar_month_outlined,
                color: AppTheme.textGray,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryBlack,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(
          Icons.person_off_outlined,
          color: AppTheme.primaryBlack,
          size: 34,
        ),
        SizedBox(height: 12),
        Text(
          'No traffic officers found',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.primaryBlack,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Create a traffic officer account first.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textGray,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}