class LicenseModel {
  const LicenseModel({
    required this.id,
    required this.licenseNumber,
    required this.status,
    required this.points,
    required this.driverName,
    this.temporaryLicenseExpiry,
  });

  final String id;
  final String licenseNumber;
  final String status;
  final int points;
  final String driverName;
  final DateTime? temporaryLicenseExpiry;

  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];

    return LicenseModel(
      id: json['id']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      points: _readInt(json['points']),
      driverName: user is Map<String, dynamic>
          ? user['name']?.toString() ?? ''
          : json['driverName']?.toString() ?? '',
      temporaryLicenseExpiry: DateTime.tryParse(
        json['temporaryLicenseExpiry']?.toString() ?? '',
      ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}