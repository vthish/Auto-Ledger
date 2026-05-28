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