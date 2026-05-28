class OfficerModel {
  const OfficerModel({
    required this.id,
    required this.name,
    required this.badgeNumber,
    required this.role,
    required this.districtId,
    required this.shifts,
  });

  final String id;
  final String name;
  final String badgeNumber;
  final String role;
  final String districtId;
  final List<ShiftInfoModel> shifts;

  ShiftInfoModel? get activeShift {
    if (shifts.isEmpty) return null;
    return shifts.first;
  }

  bool get hasActiveShift => activeShift != null;

  bool get isOnDutyNow {
    final shift = activeShift;

    if (shift == null || shift.startTime == null || shift.endTime == null) {
      return false;
    }

    final now = DateTime.now();
    final start = shift.startTime!;
    final end = shift.endTime!;

    return (now.isAtSameMomentAs(start) || now.isAfter(start)) &&
        (now.isAtSameMomentAs(end) || now.isBefore(end));
  }

  bool get isShiftScheduled {
    final shift = activeShift;

    if (shift == null || shift.startTime == null) {
      return false;
    }

    return DateTime.now().isBefore(shift.startTime!);
  }

  bool get isShiftEnded {
    final shift = activeShift;

    if (shift == null || shift.endTime == null) {
      return false;
    }

    return DateTime.now().isAfter(shift.endTime!);
  }

  String get shiftStatusLabel {
    if (!hasActiveShift) return 'No Shift';
    if (isOnDutyNow) return 'On Duty';
    if (isShiftScheduled) return 'Scheduled';
    if (isShiftEnded) return 'Shift Ended';

    return 'Off Duty';
  }

  String get shiftSummaryLabel {
    if (!hasActiveShift) return 'No assigned shift';
    if (isOnDutyNow) return 'Currently working';
    if (isShiftScheduled) return 'Upcoming shift';
    if (isShiftEnded) return 'Assigned shift ended';

    return 'Outside shift time';
  }

  factory OfficerModel.fromJson(Map<String, dynamic> json) {
    final rawShifts = json['shifts'];

    return OfficerModel(
      id: _readString(json, 'id'),
      name: _readString(json, 'name'),
      badgeNumber: _readString(json, 'badgeNumber'),
      role: _readString(json, 'role'),
      districtId: _readString(json, 'districtId'),
      shifts: rawShifts is List
          ? rawShifts
          .whereType<Map<String, dynamic>>()
          .map(ShiftInfoModel.fromJson)
          .toList()
          : <ShiftInfoModel>[],
    );
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return '';
    }

    return value.toString();
  }
}

class ShiftInfoModel {
  const ShiftInfoModel({
    required this.id,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final DateTime? startTime;
  final DateTime? endTime;

  factory ShiftInfoModel.fromJson(Map<String, dynamic> json) {
    return ShiftInfoModel(
      id: json['id']?.toString() ?? '',
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? ''),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
    );
  }
}