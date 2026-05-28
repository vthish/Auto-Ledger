class ShiftModel {
  const ShiftModel({
    required this.id,
    required this.officerId,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final String officerId;
  final DateTime? startTime;
  final DateTime? endTime;

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id']?.toString() ?? '',
      officerId: json['officerId']?.toString() ?? '',
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? ''),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'officerId': officerId,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }
}