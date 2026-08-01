import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/officer_model.dart';
import '../../../models/shift_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../services/officer_service.dart';

class AssignShiftScreen extends StatefulWidget {
  const AssignShiftScreen({
    super.key,
    this.initialOfficer,
    this.initialShift,
  });

  final OfficerModel? initialOfficer;
  final ShiftModel? initialShift;

  @override
  State<AssignShiftScreen> createState() => _AssignShiftScreenState();
}

class _AssignShiftScreenState extends State<AssignShiftScreen> {
  final _officerService = OfficerService();
  late Future<List<OfficerModel>> _officersFuture;
  final TextEditingController _locationController = TextEditingController();
  final Map<String, List<ShiftModel>> _shiftCache = {};

  List<OfficerModel> _cachedOfficers = [];
  OfficerModel? _selectedOfficer;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  String? _trackedShiftId;
  DateTime? _originalStartDateTime;
  bool _isLoading = false;
  int _selectionToken = 0;

  @override
  void initState() {
    super.initState();

    _selectedOfficer = widget.initialOfficer;

    if (widget.initialShift != null) {
      _fillFromShift(widget.initialShift!);
    } else {
      _fillShiftTimes(widget.initialOfficer);
    }

    _officersFuture = _loadOfficers();

    if (widget.initialShift == null && widget.initialOfficer != null) {
      final token = ++_selectionToken;
      Future.microtask(() {
        _loadSelectedOfficerShift(widget.initialOfficer!, token);
      });
    }
  }

  @override
  void dispose() {
    _selectionToken++;
    _locationController.dispose();
    super.dispose();
  }

  Future<List<OfficerModel>> _loadOfficers() async {
    try {
      final officers = await _officerService.getDistrictTrafficOfficers();
      _cachedOfficers = officers;
      return officers;
    } catch (e) {
      rethrow;
    }
  }

  void _fillShiftTimes(OfficerModel? officer) {
    final shift = officer?.activeShift;
    _startDateTime = shift?.startTime;
    _endDateTime = shift?.endTime;
    _originalStartDateTime = shift?.startTime;
    _trackedShiftId = shift != null && shift.id.isNotEmpty ? shift.id : null;
    _locationController.text = shift?.location.trim() ?? '';
  }

  void _fillFromShift(ShiftModel shift) {
    _startDateTime = shift.startTime;
    _endDateTime = shift.endTime;
    _originalStartDateTime = shift.startTime;
    _trackedShiftId = shift.id.isNotEmpty ? shift.id : null;
    _locationController.text = shift.location.trim();
  }

  void _clearShiftValues() {
    _startDateTime = null;
    _endDateTime = null;
    _originalStartDateTime = null;
    _trackedShiftId = null;
    _locationController.clear();
  }

  void _handleOfficerChanged(OfficerModel? officer) {
    final token = ++_selectionToken;

    setState(() {
      _selectedOfficer = officer;
      _trackedShiftId = null;

      if (officer == null) {
        _clearShiftValues();
      } else {
        _fillShiftTimes(officer);
      }
    });

    if (officer != null) {
      _loadSelectedOfficerShift(officer, token);
    }
  }

  Future<void> _loadSelectedOfficerShift(
    OfficerModel officer,
    int token,
  ) async {
    try {
      final cached = _shiftCache[officer.id];
      final shifts =
          cached ?? await _officerService.getOfficerShifts(officer.id);

      _shiftCache[officer.id] = shifts;

      if (!mounted ||
          token != _selectionToken ||
          _selectedOfficer?.id != officer.id) {
        return;
      }

      final shift = _findAutoFillShift(shifts);

      if (shift != null) {
        setState(() {
          _fillFromShift(shift);
        });
      } else if (officer.activeShift == null) {
        setState(() {
          _clearShiftValues();
        });
      }
    } catch (_) {
      if (!mounted ||
          token != _selectionToken ||
          _selectedOfficer?.id != officer.id) {
        return;
      }

      if (officer.activeShift == null) {
        setState(() {
          _clearShiftValues();
        });
      }
    }
  }

  ShiftModel? _findAutoFillShift(List<ShiftModel> shifts) {
    final now = DateTime.now();

    for (final shift in shifts) {
      if (!shift.isActive) continue;

      final start = shift.startTime;
      final end = shift.endTime;

      if (start != null &&
          end != null &&
          !start.isAfter(now) &&
          end.isAfter(now)) {
        return shift;
      }
    }

    final futureShifts = shifts
        .where(
          (shift) =>
              shift.isActive &&
              shift.startTime != null &&
              shift.startTime!.isAfter(now),
        )
        .toList()
      ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

    if (futureShifts.isNotEmpty) return futureShifts.first;

    return null;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<void> _selectDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final today = _dateOnly(now);

    final baseValue = isStart
        ? (_startDateTime ?? now)
        : (_endDateTime ?? _startDateTime ?? now);

    final safeInitialDate = _dateOnly(baseValue).isBefore(today)
        ? today
        : _dateOnly(baseValue);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: today,
      lastDate: DateTime(now.year + 2, 12, 31),
    );

    if (selectedDate == null || !mounted) return;

    final initialTimeSource = isStart
        ? (_startDateTime ?? now)
        : (_endDateTime ?? _startDateTime ?? now);

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialTimeSource),
    );

    if (selectedTime == null || !mounted) return;

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startDateTime = selectedDateTime;
      } else {
        _endDateTime = selectedDateTime;
      }
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Select date and time';

    final local = dateTime.toLocal();

    final date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

    final hour = local.hour > 12
        ? local.hour - 12
        : local.hour == 0
            ? 12
            : local.hour;

    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$date  $hour:$minute $period';
  }

  String get _submitText {
    return _trackedShiftId == null ? 'Assign Shift' : 'Update Shift';
  }

  bool get _startTimeUserChanged {
    if (_originalStartDateTime == null) return false;
    if (_startDateTime == null) return true;

    return _startDateTime!
            .difference(_originalStartDateTime!)
            .abs()
            .inSeconds >
        60;
  }

  String _alertText(String message) {
    return message.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _showTopAlert(String message, {bool isError = true}) {
    if (!mounted) return;

    AppErrorHandler.showPopup(
      context,
      message: _alertText(message),
      isError: isError,
    );
  }

  Future<void> _handleAssignShift() async {
    if (_isLoading) return;

    if (_selectedOfficer == null) {
      _showTopAlert('Please select a traffic officer.');
      return;
    }

    final location = _locationController.text.trim();

    if (location.isEmpty) {
      _showTopAlert('Please enter shift location.');
      return;
    }

    if (_startDateTime == null) {
      _showTopAlert('Please select shift start time.');
      return;
    }

    if (_endDateTime == null) {
      _showTopAlert('Please select shift end time.');
      return;
    }

    final now = DateTime.now();
    final isNewShift = _trackedShiftId == null;

    if (isNewShift && !_startDateTime!.isAfter(now)) {
      _showTopAlert('Start time cannot be in the past.');
      return;
    }

    if (!isNewShift && _startTimeUserChanged && !_startDateTime!.isAfter(now)) {
      _showTopAlert('Updated start time must be in the future.');
      return;
    }

    if (!_endDateTime!.isAfter(_startDateTime!)) {
      _showTopAlert('End time must be after start time.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isNewShift) {
        final newShift = await _officerService.assignShift(
          officerId: _selectedOfficer!.id,
          startTime: _startDateTime!,
          endTime: _endDateTime!,
          location: location,
        );

        final freshOfficers = await _officerService.getDistrictTrafficOfficers();

        if (!mounted) return;

        final updatedOfficer = freshOfficers.firstWhere(
          (officer) => officer.id == _selectedOfficer!.id,
          orElse: () => _selectedOfficer!,
        );

        setState(() {
          _cachedOfficers = freshOfficers;
          _officersFuture = Future.value(freshOfficers);
          _selectedOfficer = updatedOfficer;
          _trackedShiftId = newShift.id;
          _startDateTime = newShift.startTime;
          _endDateTime = newShift.endTime;
          _originalStartDateTime = newShift.startTime;
          _shiftCache.remove(_selectedOfficer!.id);
        });

        _showTopAlert(
          'Shift assigned successfully.',
          isError: false,
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      } else {
        final updatedShift = await _officerService.updateShift(
          shiftId: _trackedShiftId!,
          startTime: _startTimeUserChanged ? _startDateTime : null,
          endTime: _endDateTime!,
          location: location,
        );

        final freshOfficers = await _officerService.getDistrictTrafficOfficers();

        if (!mounted) return;

        final updatedOfficer = freshOfficers.firstWhere(
          (officer) => officer.id == _selectedOfficer!.id,
          orElse: () => _selectedOfficer!,
        );

        setState(() {
          _cachedOfficers = freshOfficers;
          _officersFuture = Future.value(freshOfficers);
          _selectedOfficer = updatedOfficer;
          _startDateTime = updatedShift.startTime ?? _startDateTime;
          _endDateTime = updatedShift.endTime ?? _endDateTime;
          _originalStartDateTime =
              updatedShift.startTime ?? _originalStartDateTime;
          _shiftCache.remove(_selectedOfficer!.id);
        });

        _showTopAlert(
          'Shift updated successfully.',
          isError: false,
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;

      _showTopAlert(error.message);
    } catch (_) {
      if (!mounted) return;

      _showTopAlert('Unable to save shift. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshOfficers() async {
    final officers = await _loadOfficers();

    if (!mounted) return;

    final updated = _selectedOfficer == null
        ? null
        : officers.firstWhere(
            (officer) => officer.id == _selectedOfficer!.id,
            orElse: () => _selectedOfficer!,
          );

    final token = ++_selectionToken;

    setState(() {
      _selectedOfficer = updated;
      _officersFuture = Future.value(officers);

      if (updated == null) {
        _clearShiftValues();
      } else {
        _fillShiftTimes(updated);
      }
    });

    if (updated != null) {
      await _loadSelectedOfficerShift(updated, token);
    }
  }

  OfficerModel? _resolveSelectedOfficer(List<OfficerModel> officers) {
    final selected = _selectedOfficer;
    if (selected == null) return null;

    for (final officer in officers) {
      if (officer.id == selected.id) return officer;
    }

    return selected;
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
                title: const Text(
                  'Assign Shift',
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

                    return Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          labelStyle: const TextStyle(
                            color: Color(0xFF0B1A30),
                            fontWeight: FontWeight.w500,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF0B1A30),
                            fontWeight: FontWeight.w500,
                          ),
                          hintStyle: TextStyle(
                            color:
                                const Color(0xFF0B1A30).withValues(alpha: 0.35),
                            fontWeight: FontWeight.w400,
                          ),
                          suffixIconColor: const Color(0xFF0B1A30),
                          prefixIconColor: const Color(0xFF0B1A30),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xFF0B1A30),
                              width: 1.8,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                      ),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        children: [
                          const SizedBox(height: 16),
                          const _HeaderCard(),
                          const SizedBox(height: 24),
                          FutureBuilder<List<OfficerModel>>(
                            future: _officersFuture,
                            builder: (context, snapshot) {
                              final snapshotData = snapshot.data;
                              final officers = snapshotData ?? _cachedOfficers;

                              final isFirstLoad =
                                  snapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      _cachedOfficers.isEmpty &&
                                      snapshotData == null;

                              if (snapshot.hasError && officers.isEmpty) {
                                return _ErrorView(
                                  message: snapshot.error is ApiException
                                      ? (snapshot.error as ApiException).message
                                      : 'Unable to load traffic officers.',
                                  onRetry: () {
                                    _refreshOfficers();
                                  },
                                );
                              }

                              if (isFirstLoad) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 80),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF0B1A30),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                );
                              }

                              if (officers.isEmpty) {
                                return const _EmptyView();
                              }

                              final selected = _resolveSelectedOfficer(officers);

                              return Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0B1A30)
                                          .withValues(alpha: 0.04),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _OfficerDropdown(
                                      officers: officers,
                                      selectedOfficer: selected,
                                      onChanged: _handleOfficerChanged,
                                    ),
                                    const SizedBox(height: 18),
                                    _LocationInput(
                                      controller: _locationController,
                                    ),
                                    const SizedBox(height: 18),
                                    if (selected?.hasActiveShift == true)
                                      _ExistingShiftNotice(
                                        officer: selected!,
                                      ),
                                    if (selected?.hasActiveShift == true)
                                      const SizedBox(height: 18),
                                    _DateTimeSelector(
                                      title: 'Start Time',
                                      value: _formatDateTime(_startDateTime),
                                      icon: Icons.play_circle_outline_rounded,
                                      onTap: () => _selectDateTime(
                                        isStart: true,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _DateTimeSelector(
                                      title: 'End Time',
                                      value: _formatDateTime(_endDateTime),
                                      icon: Icons.stop_circle_outlined,
                                      onTap: () => _selectDateTime(
                                        isStart: false,
                                      ),
                                    ),
                                    const SizedBox(height: 26),
                                    AppButton(
                                      text: _submitText,
                                      isLoading: _isLoading,
                                      onPressed: _handleAssignShift,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
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
              Icons.schedule_rounded,
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
                  'Assign Duty Shift',
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
                  'Select officer and set duty time',
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
    OfficerModel? selected;

    if (selectedOfficer != null) {
      for (final officer in officers) {
        if (officer.id == selectedOfficer!.id) {
          selected = officer;
          break;
        }
      }
    }

    return DropdownButtonFormField<OfficerModel>(
      value: selected,
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
      iconEnabledColor: const Color(0xFF0B1A30),
      decoration: const InputDecoration(
        labelText: 'Traffic Officer',
        hintText: 'Select officer',
        prefixIcon: Icon(
          Icons.badge_outlined,
          color: Color(0xFF0B1A30),
        ),
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
    final badgeNumber =
        officer.badgeNumber.isEmpty ? 'No badge' : officer.badgeNumber;

    return Text(
      '$name - $badgeNumber',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF0B1A30),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LocationInput extends StatelessWidget {
  const _LocationInput({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      maxLines: 1,
      decoration: const InputDecoration(
        labelText: 'Location',
        hintText: 'Duty Location',
        labelStyle: TextStyle(
          color: Color(0xFF0B1A30),
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: TextStyle(
          color: Color(0xFF0B1A30),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          Icons.place_outlined,
          color: Color(0xFF0B1A30),
        ),
      ),
    );
  }
}

class _ExistingShiftNotice extends StatelessWidget {
  const _ExistingShiftNotice({required this.officer});

  final OfficerModel officer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF0B1A30).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            officer.isOnDutyNow
                ? Icons.play_circle_outline_rounded
                : Icons.schedule_rounded,
            color: const Color(0xFF0B1A30),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${officer.shiftStatusLabel}: existing shift values loaded.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0B1A30),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF0B1A30),
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0B1A30),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF0B1A30),
                size: 20,
              ),
            ],
          ),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

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
            Icons.person_off_outlined,
            color: Color(0xFF0B1A30),
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'No traffic officers found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0B1A30),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create a traffic officer account first.',
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