class ShiftModel {
  const ShiftModel({
    required this.id,
    required this.officerId,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.location,
  });

  final String id;
  final String officerId;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isActive;
  final String location;

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['shift_Id']?.toString() ??
          json['id']?.toString() ??
          '',
      officerId: json['traffic_Officer_Id']?.toString() ??
          json['officerId']?.toString() ??
          '',
      startTime: DateTime.tryParse(
        json['start_Time']?.toString() ??
            json['startTime']?.toString() ??
            '',
      ),
      endTime: DateTime.tryParse(
        json['end_Time']?.toString() ??
            json['endTime']?.toString() ??
            '',
      ),
      isActive: json['is_Active'] == true ||
          json['isActive'] == true,
      location: json['location']?.toString() ?? '',
    );
  }
}