import 'fine_model.dart';

class VehicleCategory {
  const VehicleCategory({
    required this.id,
    required this.vehicleClass,
    required this.issueDate,
    required this.expiryDate,
    this.restriction,
    this.transmission,
  });

  final String id;
  final String vehicleClass;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? restriction;
  final String? transmission;

  String get transmissionLabel {
    final value = transmission?.trim();
    if (value == null || value.isEmpty) {
      return 'Auto / Manual';
    }
    return value;
  }
}

class LicenseModel {
  const LicenseModel({
    required this.id,
    required this.licenseNumber,
    required this.status,
    required this.points,
    required this.driverName,
    required this.recentFines,
    this.issueDate,
    this.expiryDate,
    this.temporaryLicenseExpiry,
    this.scanToken = '',
    this.scanExpiresAt,
    this.nicNo,
    this.address,
    this.imageUrl,
    this.vehicleCategories = const [],
    this.dateOfBirth,
    this.bloodGroup,
  });

  final String id;
  final String licenseNumber;
  final String status;
  final int points;
  final String driverName;
  final List<FineModel> recentFines;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final DateTime? temporaryLicenseExpiry;
  final String scanToken;
  final DateTime? scanExpiresAt;
  final String? nicNo;
  final String? address;
  final String? imageUrl;
  final List<VehicleCategory> vehicleCategories;
  final DateTime? dateOfBirth;
  final String? bloodGroup;

  bool get hasExtraDetails =>
      issueDate != null ||
      expiryDate != null ||
      temporaryLicenseExpiry != null ||
      recentFines.isNotEmpty ||
      nicNo != null ||
      address != null ||
      imageUrl != null ||
      vehicleCategories.isNotEmpty;

  LicenseModel copyWith({
    String? id,
    String? licenseNumber,
    String? status,
    int? points,
    String? driverName,
    List<FineModel>? recentFines,
    DateTime? issueDate,
    DateTime? expiryDate,
    DateTime? temporaryLicenseExpiry,
    String? scanToken,
    DateTime? scanExpiresAt,
    String? nicNo,
    String? address,
    String? imageUrl,
    List<VehicleCategory>? vehicleCategories,
    DateTime? dateOfBirth,
    String? bloodGroup,
  }) {
    return LicenseModel(
      id: id ?? this.id,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      status: status ?? this.status,
      points: points ?? this.points,
      driverName: driverName ?? this.driverName,
      recentFines: recentFines ?? this.recentFines,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      temporaryLicenseExpiry:
      temporaryLicenseExpiry ?? this.temporaryLicenseExpiry,
      scanToken: scanToken ?? this.scanToken,
      scanExpiresAt: scanExpiresAt ?? this.scanExpiresAt,
      nicNo: nicNo ?? this.nicNo,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      vehicleCategories: vehicleCategories ?? this.vehicleCategories,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
    );
  }

  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    final licenseData = _asMap(json['license']) ?? json;
    final user = _asMap(licenseData['user']) ?? _asMap(json['user']);

    final rawFines = licenseData['fines'] ??
        licenseData['recentFines'] ??
        json['fines'] ??
        json['recentFines'] ??
        const [];

    final recentFines = rawFines is List
        ? rawFines
            .whereType<Map<String, dynamic>>()
            .map(FineModel.fromJson)
            .take(5)
            .toList()
        : <FineModel>[];

    final issueDate = _readDateFromMaps(
          [licenseData, json, user],
          const ['issue_Date', 'issueDate', 'issuedAt'],
        ) ??
        _readNestedDate(
          licenseData,
          'vehicleCategories',
          const ['issue_Date', 'issueDate', 'issuedAt'],
        );

    final expiryDate = _readDateFromMaps(
          [licenseData, json],
          const ['expiry_Date', 'expiryDate'],
        ) ??
        _readNestedDate(
          licenseData,
          'vehicleCategories',
          const ['expiry_Date', 'expiryDate'],
        );

    final tempExpiry = _readDateFromMaps(
          [licenseData, json],
          const ['temporaryExpiry', 'temporaryLicenseExpiry', 'expiry_Date'],
        ) ??
        _readNestedDate(
          licenseData,
          'temporaryLicenses',
          const ['expiry_Date', 'expiryDate'],
        );

    final vehicleCategories = _parseVehicleCategories(
        licenseData['vehicleCategories'] ?? json['vehicleCategories']);

    final dob = _readDateFromMaps(
      [user, licenseData, json],
      const ['date_of_birth', 'dateOfBirth', 'dob'],
    );

    final blood = _readStringFromMaps(
      [user, licenseData, json],
      const ['blood_Group', 'bloodGroup', 'blood_group'],
    );

    return LicenseModel(
      id: _readStringFromMaps(
        [licenseData, json],
        const ['license_Id', 'licenseId', 'license_id', 'id'],
      ),
      licenseNumber: _readStringFromMaps(
        [licenseData, json],
        const ['license_No', 'licenseNumber', 'licenseNo', 'license_no'],
      ),
      status: _readStringFromMaps(
        [licenseData, json],
        const ['status', 'licenseStatus'],
        fallback: 'ACTIVE',
      ),
      points: _readInt(licenseData['points'] ?? json['points'] ?? 24),
      driverName: _readStringFromMaps(
        [user, licenseData, json],
        const ['name', 'fullName', 'driverName', 'full_Name'],
      ),
      recentFines: recentFines,
      issueDate: issueDate,
      expiryDate: expiryDate,
      temporaryLicenseExpiry: tempExpiry,
      scanToken: _readStringFromMaps(
        [licenseData, json],
        const ['scanToken', 'scan_token', 'qrToken', 'qr_token', 'token'],
      ),
      scanExpiresAt: _readDateFromMaps(
        [licenseData, json],
        const ['expiresAt', 'scanExpiresAt'],
      ),
      nicNo: _readStringFromMaps(
        [licenseData, json, user],
        const ['nic_No', 'nicNo', 'nic_no', 'nic'],
      ),
      address: _readStringFromMaps(
        [licenseData, json, user],
        const ['address', 'fullAddress'],
      ),
      imageUrl: _readStringFromMaps(
        [licenseData, json],
        const ['image', 'imageUrl', 'photo'],
      ),
      vehicleCategories: vehicleCategories,
      dateOfBirth: dob,
      bloodGroup: blood,
    );
  }

  static List<VehicleCategory> _parseVehicleCategories(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => VehicleCategory(
              id: json['category_Id']?.toString() ??
                  json['id']?.toString() ??
                  '',
              vehicleClass: json['vehicle_Class']?.toString() ??
                  json['vehicleClass']?.toString() ??
                  '',
              issueDate: _parseDate(json['issue_Date'] ?? json['issueDate']),
              expiryDate: _parseDate(json['expiry_Date'] ?? json['expiryDate']),
              restriction: json['restriction']?.toString(),
              transmission: _readTransmission(json),
            ))
        .toList();
  }

  static String? _readTransmission(Map<String, dynamic> json) {
    final isAutomatic = json['isAutomatic'];
    if (isAutomatic is bool) {
      return isAutomatic ? 'Auto' : 'Manual';
    }

    final candidates = [
      json['transmission'],
      json['transmissionType'],
      json['transmission_type'],
      json['gearBox'],
      json['gearbox'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final value = candidate.toString().trim();
      if (value.isEmpty) continue;

      final normalized = value.toLowerCase();
      if (normalized == 'true') return 'Auto';
      if (normalized == 'false') return 'Manual';
      return value;
    }

    return null;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    final parsed = DateTime.tryParse(value.toString());
    return parsed ?? DateTime.now();
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static String _readStringFromMaps(
    List<Map<String, dynamic>?> maps,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final map in maps) {
      if (map == null) continue;
      for (final key in keys) {
        final value = map[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return fallback;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _readDateFromMaps(
    List<Map<String, dynamic>?> maps,
    List<String> keys,
  ) {
    for (final map in maps) {
      if (map == null) continue;
      for (final key in keys) {
        final raw = map[key]?.toString() ?? '';
        if (raw.trim().isEmpty) continue;
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static DateTime? _readNestedDate(
    Map<String, dynamic> json,
    String nestedKey,
    List<String> keys,
  ) {
    final nested = json[nestedKey];
    if (nested is Map<String, dynamic>) {
      return _readDateFromMaps([nested], keys);
    }
    if (nested is List) {
      for (final item in nested.whereType<Map<String, dynamic>>()) {
        final date = _readDateFromMaps([item], keys);
        if (date != null) return date;
      }
    }
    return null;
  }
}