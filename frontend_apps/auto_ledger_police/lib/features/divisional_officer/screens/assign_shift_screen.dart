import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../shared/widgets/app_button.dart';

class AssignShiftScreen extends StatefulWidget {
  const AssignShiftScreen({super.key});

  @override
  State<AssignShiftScreen> createState() => _AssignShiftScreenState();
}

class _AssignShiftScreenState extends State<AssignShiftScreen> {
  final List<_OfficerOption> _officers = const [
    _OfficerOption(name: 'Nimal Perera', badgeNumber: 'TRF-GALLE-100'),
    _OfficerOption(name: 'Kamal Silva', badgeNumber: 'TRF-GALLE-101'),
    _OfficerOption(name: 'Sahan Fernando', badgeNumber: 'TRF-GALLE-102'),
  ];

  _OfficerOption? _selectedOfficer;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  bool _isLoading = false;

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

  void _handleAssignShift() {
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

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      setState(() => _isLoading = false);

      AppErrorHandler.showPopup(
        context,
        message: 'Shift form ready. API will be connected next.',
        isError: false,
      );
    });
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
                      child: Column(
                        children: [
                          _OfficerDropdown(
                            officers: _officers,
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
                      ),
                    ),
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

class _OfficerOption {
  const _OfficerOption({
    required this.name,
    required this.badgeNumber,
  });

  final String name;
  final String badgeNumber;
}

class _OfficerDropdown extends StatelessWidget {
  const _OfficerDropdown({
    required this.officers,
    required this.selectedOfficer,
    required this.onChanged,
  });

  final List<_OfficerOption> officers;
  final _OfficerOption? selectedOfficer;
  final ValueChanged<_OfficerOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<_OfficerOption>(
      initialValue: selectedOfficer,
      items: officers.map((officer) {
        return DropdownMenuItem(
          value: officer,
          child: Text('${officer.name}  •  ${officer.badgeNumber}'),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Traffic Officer',
        hintText: 'Select officer',
        prefixIcon: Icon(Icons.local_police_outlined),
      ),
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