class OfficerModel {
  const OfficerModel({
    required this.id,
    required this.name,
    required this.badgeNumber,
    required this.role,
    required this.districtId,
    this.shift,
  });

  final String id;
  final String name;
  final String badgeNumber;
  final String role;
  final String districtId;
  final ShiftInfoModel? shift;

  factory OfficerModel.fromJson(Map<String, dynamic> json) {
    return OfficerModel(
      id: _readString(json, 'id'),
      name: _readString(json, 'name'),
      badgeNumber: _readString(json, 'badgeNumber'),
      role: _readString(json, 'role'),
      districtId: _readString(json, 'districtId'),
      shift: json['shift'] is Map<String, dynamic>
          ? ShiftInfoModel.fromJson(json['shift'] as Map<String, dynamic>)
          : json['activeShift'] is Map<String, dynamic>
          ? ShiftInfoModel.fromJson(
        json['activeShift'] as Map<String, dynamic>,
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'badgeNumber': badgeNumber,
      'role': role,
      'districtId': districtId,
      'shift': shift?.toJson(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }
}