import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/officer_model.dart';
import '../../../models/shift_model.dart';
import '../services/officer_service.dart';
import 'assign_shift_screen.dart';

class TrafficOfficerListScreen extends StatefulWidget {
  const TrafficOfficerListScreen({super.key});

  @override
  State<TrafficOfficerListScreen> createState() =>
      _TrafficOfficerListScreenState();
}

class _TrafficOfficerListScreenState extends State<TrafficOfficerListScreen> {
  final _officerService = OfficerService();
  late Future<List<OfficerModel>> _officersFuture;

  final Map<String, List<ShiftModel>> _shiftCache = {};
  List<OfficerModel> _cachedOfficers = [];
  List<DivisionalHeadModel> _cachedHeads = [];

  Timer? _autoRefreshTimer;
  int _loadVersion = 0;
  String? _transferringOfficerId;

  @override
  void initState() {
    super.initState();
    _officersFuture = _loadOfficers(clearCache: true);
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
      if (mounted && isCurrentRoute) {
        _refreshOfficers(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<List<OfficerModel>> _loadOfficers({bool clearCache = false}) async {
    final version = ++_loadVersion;
    final officers = await _officerService.getDistrictTrafficOfficers();

    if (!mounted || version != _loadVersion) {
      return officers;
    }

    _cachedOfficers = officers;

    if (clearCache) {
      _shiftCache.clear();
    }

    _loadShiftsInBackground(officers, version);

    return officers;
  }

  void _loadShiftsInBackground(List<OfficerModel> officers, int version) {
    Future<void>(() async {
      const batchSize = 8;
      final entries = <MapEntry<String, List<ShiftModel>>>[];

      for (var i = 0; i < officers.length; i += batchSize) {
        if (!mounted || version != _loadVersion) return;

        final end = i + batchSize > officers.length
            ? officers.length
            : i + batchSize;

        final batch = officers.sublist(i, end);

        final results = await Future.wait(
          batch.map((officer) async {
            try {
              final shifts = await _officerService.getOfficerShifts(officer.id);
              return MapEntry(officer.id, shifts);
            } catch (_) {
              return MapEntry(officer.id, <ShiftModel>[]);
            }
          }),
        );

        entries.addAll(results);
      }

      if (!mounted || version != _loadVersion) return;

      setState(() {
        _shiftCache.addEntries(entries);
      });
    });
  }

  Future<void> _loadOfficerShifts(String officerId) async {
    if (_shiftCache.containsKey(officerId)) return;

    try {
      final shifts = await _officerService.getOfficerShifts(officerId);
      if (!mounted) return;
      setState(() {
        _shiftCache[officerId] = shifts;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _shiftCache[officerId] = [];
      });
    }
  }

  List<ShiftModel>? _shiftsForOfficer(OfficerModel officer) {
    return _shiftCache[officer.id];
  }

  ShiftModel? _activeShift(List<ShiftModel> shifts) {
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

    return null;
  }

  ShiftModel? _nextShift(List<ShiftModel> shifts) {
    final now = DateTime.now();

    final futureShifts = shifts
        .where(
          (shift) =>
              shift.isActive &&
              shift.startTime != null &&
              shift.startTime!.isAfter(now),
        )
        .toList()
      ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

    if (futureShifts.isEmpty) return null;
    return futureShifts.first;
  }

  ShiftModel? _lastShift(List<ShiftModel> shifts) {
    final now = DateTime.now();

    final pastShifts = shifts
        .where((shift) => shift.endTime != null && shift.endTime!.isBefore(now))
        .toList()
      ..sort((a, b) => b.endTime!.compareTo(a.endTime!));

    if (pastShifts.isEmpty) return null;
    return pastShifts.first;
  }

  String _getStatusForOfficer(OfficerModel officer) {
    final shifts = _shiftsForOfficer(officer);

    if (shifts == null) return 'Checking';
    if (shifts.isEmpty) return 'No Shift';
    if (_activeShift(shifts) != null) return 'On Duty';
    if (_nextShift(shifts) != null) return 'On Schedule';
    if (_lastShift(shifts) != null) return 'Off Duty';

    return 'No Shift';
  }

  String _getLocationForOfficer(OfficerModel officer) {
    final shifts = _shiftsForOfficer(officer);

    if (shifts == null || shifts.isEmpty) return '';

    final active = _activeShift(shifts);
    if (active != null && active.location.trim().isNotEmpty) {
      return active.location.trim();
    }

    final next = _nextShift(shifts);
    if (next != null && next.location.trim().isNotEmpty) {
      return next.location.trim();
    }

    return '';
  }

  String _formatShiftTime(OfficerModel officer) {
    final shifts = _shiftsForOfficer(officer);

    if (shifts == null) return 'Checking shift details';
    if (shifts.isEmpty) return 'No shifts assigned';

    final active = _activeShift(shifts);
    if (active != null) return _formatShiftRange(active, 'Current');

    final next = _nextShift(shifts);
    if (next != null) return _formatShiftRange(next, 'Upcoming');

    final last = _lastShift(shifts);
    if (last != null) return _formatShiftRange(last, 'Last');

    return 'No shifts assigned';
  }

  String _formatShiftRange(ShiftModel shift, String label) {
    final start = shift.startTime;
    final end = shift.endTime;

    if (start == null || end == null) return 'Invalid shift times';

    return '$label: ${_formatTime(start)} - ${_formatTime(end)}';
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();

    final hour = local.hour > 12
        ? local.hour - 12
        : local.hour == 0
            ? 12
            : local.hour;

    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  Color _getStatusColor(String status) {
    if (status == 'On Duty') return const Color(0xFF059669);
    if (status == 'On Schedule') return const Color(0xFFDC2626);
    return const Color(0xFF64748B);
  }

  Color _getStatusBackground(String status) {
    if (status == 'On Duty') {
      return const Color(0xFF059669).withValues(alpha: 0.1);
    }

    if (status == 'On Schedule') {
      return const Color(0xFFDC2626).withValues(alpha: 0.1);
    }

    return const Color(0xFFF1F5F9);
  }

  IconData _getStatusIcon(String status) {
    if (status == 'On Duty') return Icons.play_circle_outline_rounded;
    if (status == 'On Schedule') return Icons.event_available_outlined;
    if (status == 'Checking') return Icons.hourglass_empty_rounded;
    return Icons.schedule_outlined;
  }

  Future<void> _openAssignShift(OfficerModel officer) async {
    await _loadOfficerShifts(officer.id);

    if (!mounted) return;

    final shiftToEdit = _getShiftToEdit(officer);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssignShiftScreen(
          initialOfficer: officer,
          initialShift: shiftToEdit,
        ),
      ),
    );

    if (!mounted) return;

    await _refreshOfficers();
  }

  ShiftModel? _getShiftToEdit(OfficerModel officer) {
    final shifts = _shiftsForOfficer(officer);

    if (shifts == null || shifts.isEmpty) return null;

    final active = _activeShift(shifts);
    if (active != null) return active;

    final next = _nextShift(shifts);
    if (next != null) return next;

    return null;
  }

  Future<void> _loadDivisionalHeadsIfNeeded() async {
    if (_cachedHeads.isNotEmpty) return;
    _cachedHeads = await _officerService.getDivisionalHeads();
  }

  Future<void> _transferOfficer(OfficerModel officer) async {
    try {
      await _loadDivisionalHeadsIfNeeded();
    } catch (_) {
      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: 'Unable to load divisional heads. Please try again.',
      );
      return;
    }

    final session = await const TokenStorage().getSession();

    if (!mounted) return;

    if (session == null) {
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to identify your division. Please log in again.',
      );
      return;
    }

    final currentHeadId = session.officerId.trim();
    final currentDivisionName = session.divisionName.trim().toLowerCase();

    final availableHeads = _cachedHeads.where((head) {
      final isCurrentHead =
          currentHeadId.isNotEmpty && head.id.trim() == currentHeadId;

      final isOwnDivision =
          currentDivisionName.isNotEmpty &&
          head.divisionName.trim().toLowerCase() == currentDivisionName;

      return !isCurrentHead && !isOwnDivision;
    }).toList();

    if (availableHeads.isEmpty) {
      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: 'No other divisional heads available for transfer.',
      );
      return;
    }

    DivisionalHeadModel? selectedHead;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0B1A30),
                              Color(0xFF1E3A8A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0B1A30)
                                  .withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Transfer Officer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF0B1A30),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${officer.name} (${officer.badgeNumber})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF0B1A30),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<DivisionalHeadModel>(
                        value: selectedHead,
                        isExpanded: true,
                        hint: const Text(
                          'Select New Divisional Head',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                        selectedItemBuilder: (context) {
                          return availableHeads.map<Widget>((head) {
                            final divisionName = head.divisionName.isEmpty
                                ? 'Unknown Division'
                                : head.divisionName;

                            final headName =
                                head.name.isEmpty ? 'Unknown Head' : head.name;

                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$divisionName • $headName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B1A30),
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        decoration: InputDecoration(
                          labelText: 'New Divisional Head',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          labelStyle: const TextStyle(
                            color: Color(0xFF0B1A30),
                            fontWeight: FontWeight.w600,
                          ),
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
                            vertical: 12,
                          ),
                        ),
                        items: availableHeads.map((head) {
                          final divisionName = head.divisionName.isEmpty
                              ? 'Unknown Division'
                              : head.divisionName;

                          final headName =
                              head.name.isEmpty ? 'Unknown Head' : head.name;

                          return DropdownMenuItem(
                            value: head,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    divisionName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0B1A30),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    headName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedHead = value;
                          });
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: selectedHead == null
                                  ? null
                                  : () => Navigator.pop(dialogContext, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B1A30),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                'Transfer',
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
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || selectedHead == null) return;

    setState(() {
      _transferringOfficerId = officer.id;
    });

    try {
      await _officerService.transferOfficer(
        officerId: officer.id,
        newHeadId: selectedHead!.id,
      );

      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: 'Officer transferred to ${selectedHead!.name} successfully.',
        isError: false,
      );

      await _refreshOfficers();
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
        message: 'Unable to transfer officer. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _transferringOfficerId = null;
        });
      }
    }
  }

  Future<void> _refreshOfficers({bool silent = false}) async {
    final future = _loadOfficers(clearCache: !silent);

    if (!mounted) return;

    setState(() {
      _officersFuture = future;
    });

    try {
      await future;
    } catch (_) {}
  }

  Widget _buildOfficerCard(OfficerModel officer) {
    final status = _getStatusForOfficer(officer);
    final location = _getLocationForOfficer(officer);
    final showAssign = status == 'Off Duty' || status == 'No Shift';
    final showTransfer = status != 'On Duty' && status != 'Checking';

    return _OfficerListCard(
      officer: officer,
      status: status,
      shiftTime: _formatShiftTime(officer),
      location: location,
      statusColor: _getStatusColor(status),
      statusBackground: _getStatusBackground(status),
      statusIcon: _getStatusIcon(status),
      showAssignButton: showAssign,
      showTransferButton: showTransfer,
      onAssignShift: () => _openAssignShift(officer),
      onTransfer: () => _transferOfficer(officer),
      isTransferring: _transferringOfficerId == officer.id,
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
                title: const Text(
                  'Traffic Officers',
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

                    return FutureBuilder<List<OfficerModel>>(
                      future: _officersFuture,
                      builder: (context, snapshot) {
                        final snapshotData = snapshot.data;
                        final officers = snapshotData ?? _cachedOfficers;

                        final isFirstLoad =
                            snapshot.connectionState == ConnectionState.waiting &&
                                _cachedOfficers.isEmpty &&
                                snapshotData == null;

                        if (snapshot.hasError && officers.isEmpty) {
                          return ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            children: [
                              const SizedBox(height: 16),
                              const _HeaderCard(),
                              const SizedBox(height: 24),
                              _ErrorCard(
                                message: snapshot.error is ApiException
                                    ? (snapshot.error as ApiException).message
                                    : 'Unable to load traffic officers.',
                                onRetry: () {
                                  setState(() {
                                    _officersFuture = _loadOfficers(
                                      clearCache: true,
                                    );
                                  });
                                },
                              ),
                              const SizedBox(height: 32),
                            ],
                          );
                        }

                        if (isFirstLoad) {
                          return ListView(
                            physics: const BouncingScrollPhysics(),
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

                        final itemCount =
                            officers.isEmpty ? 6 : officers.length + 5;

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            if (index == 0) return const SizedBox(height: 16);
                            if (index == 1) return const _HeaderCard();
                            if (index == 2) return const SizedBox(height: 24);
                            if (index == 3) {
                              return _HeaderStats(officers: officers);
                            }
                            if (index == 4) return const SizedBox(height: 14);

                            if (officers.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 32),
                                child: _EmptyCard(),
                              );
                            }

                            final officerIndex = index - 5;
                            final officer = officers[officerIndex];
                            final isLast = officerIndex == officers.length - 1;

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isLast ? 32 : 14,
                              ),
                              child: _buildOfficerCard(officer),
                            );
                          },
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
              Icons.groups_2_rounded,
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
                  'Traffic Officers',
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
                  'View officers assigned to your division',
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

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({required this.officers});

  final List<OfficerModel> officers;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Officer List',
          style: TextStyle(
            color: Color(0xFF0B1A30),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${officers.length} officers',
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

class _OfficerListCard extends StatelessWidget {
  const _OfficerListCard({
    required this.officer,
    required this.status,
    required this.shiftTime,
    required this.location,
    required this.statusColor,
    required this.statusBackground,
    required this.statusIcon,
    required this.showAssignButton,
    required this.showTransferButton,
    required this.onAssignShift,
    required this.onTransfer,
    required this.isTransferring,
  });

  final OfficerModel officer;
  final String status;
  final String shiftTime;
  final String location;
  final Color statusColor;
  final Color statusBackground;
  final IconData statusIcon;
  final bool showAssignButton;
  final bool showTransferButton;
  final VoidCallback onAssignShift;
  final VoidCallback onTransfer;
  final bool isTransferring;

  @override
  Widget build(BuildContext context) {
    final showLocation =
        (status == 'On Duty' || status == 'On Schedule') && location.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
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
                  Icons.badge_outlined,
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
                      officer.name.isEmpty ? 'Unnamed Officer' : officer.name,
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
                      officer.badgeNumber.isEmpty
                          ? 'No Badge'
                          : officer.badgeNumber,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: status == 'On Duty'
                        ? const Color(0xFF059669).withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'On Duty') ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  color: const Color(0xFF0B1A30),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status == 'No Shift'
                            ? 'No Shift Assigned'
                            : status == 'Off Duty'
                                ? 'Off Duty'
                                : status == 'Checking'
                                    ? 'Checking Shift'
                                    : 'Shift Details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0B1A30),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shiftTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
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
          if (showLocation) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF0B1A30),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duty Location',
                          style: TextStyle(
                            color: Color(0xFF0B1A30),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
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
          ],
          if (showAssignButton || showTransferButton) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (showAssignButton)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAssignShift,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B1A30),
                        side: const BorderSide(
                          color: Color(0xFFCBD5E1),
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Assign Shift',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (showAssignButton && showTransferButton)
                  const SizedBox(width: 10),
                if (showTransferButton)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isTransferring ? null : onTransfer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B1A30),
                        side: BorderSide(
                          color: isTransferring
                              ? Colors.grey.shade300
                              : const Color(0xFF0B1A30).withValues(alpha: 0.3),
                        ),
                        backgroundColor: isTransferring
                            ? Colors.grey.shade50
                            : const Color(0xFF0B1A30).withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: isTransferring
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0B1A30),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Transfer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ],
        ],
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