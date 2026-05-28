class FineModel {
  const FineModel({
    required this.id,
    required this.status,
    required this.issuedAt,
    required this.dueDate,
    required this.licenseNumber,
    required this.driverName,
    required this.offenseName,
    required this.points,
    required this.amount,
    required this.officerName,
    required this.officerBadgeNumber,
  });

  final String id;
  final String status;
  final DateTime? issuedAt;
  final DateTime? dueDate;
  final String licenseNumber;
  final String driverName;
  final String offenseName;
  final int points;
  final double amount;
  final String officerName;
  final String officerBadgeNumber;

  factory FineModel.fromJson(Map<String, dynamic> json) {
    final license = json['license'];
    final user = license is Map<String, dynamic> ? license['user'] : null;
    final officer = json['officer'];
    final offense = json['offenseCategory'] ?? json['offense'];

    return FineModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      issuedAt: DateTime.tryParse(json['issuedAt']?.toString() ?? ''),
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? ''),
      licenseNumber: license is Map<String, dynamic>
          ? license['licenseNumber']?.toString() ?? ''
          : json['licenseNumber']?.toString() ?? '',
      driverName: user is Map<String, dynamic>
          ? user['name']?.toString() ?? ''
          : json['driverName']?.toString() ?? '',
      offenseName: offense is Map<String, dynamic>
          ? offense['name']?.toString() ??
          offense['description']?.toString() ??
          ''
          : json['offenseName']?.toString() ?? '',
      points: offense is Map<String, dynamic>
          ? _readInt(offense['points'])
          : _readInt(json['points']),
      amount: offense is Map<String, dynamic>
          ? _readDouble(offense['amount'])
          : _readDouble(json['amount']),
      officerName: officer is Map<String, dynamic>
          ? officer['name']?.toString() ?? ''
          : json['officerName']?.toString() ?? '',
      officerBadgeNumber: officer is Map<String, dynamic>
          ? officer['badgeNumber']?.toString() ?? ''
          : json['officerBadgeNumber']?.toString() ?? '',
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DistrictStatisticsModel {
  const DistrictStatisticsModel({
    required this.totalFinesToday,
    required this.revenueToday,
    required this.pendingCourtCases,
  });

  final int totalFinesToday;
  final double revenueToday;
  final int pendingCourtCases;

  factory DistrictStatisticsModel.fromJson(Map<String, dynamic> json) {
    return DistrictStatisticsModel(
      totalFinesToday: _readInt(json['totalFinesToday']),
      revenueToday: _readDouble(json['revenueToday']),
      pendingCourtCases: _readInt(json['pendingCourtCases']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}