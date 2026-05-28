class ShiftModel {
  const ShiftModel({
    required this.id,
    required this.officerId,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  final String id;
  final String officerId;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isActive;

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id']?.toString() ?? '',
      officerId: json['officerId']?.toString() ?? '',
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? ''),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
      isActive: json['isActive'] == true,
    );
  }
}