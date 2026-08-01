import 'offense_model.dart';

class FineModel {
  const FineModel({
    required this.id,
    required this.status,
    required this.issuedAt,
    required this.dueDate,
    required this.licenseNumber,
    required this.driverName,
    required this.offenses,
    required this.officerName,
    required this.officerBadgeNumber,
    this.scanLocation = '',
    this.comment,
    this.paymentAmount,
    this.paymentStatus,
  });

  final String id;
  final String status;
  final DateTime? issuedAt;
  final DateTime? dueDate;
  final String licenseNumber;
  final String driverName;
  final List<OffenseModel> offenses;
  final String officerName;
  final String officerBadgeNumber;
  final String scanLocation;
  final String? comment;
  final double? paymentAmount;
  final String? paymentStatus;

  String get offenseName {
    if (offenses.isEmpty) return '';
    return offenses.map((offense) => offense.name).join(', ');
  }

  int get points {
    return offenses.fold<int>(0, (sum, offense) => sum + offense.points);
  }

  double get amount {
    return offenses.fold<double>(0, (sum, offense) => sum + offense.amount);
  }

  bool get isPaid => status.toUpperCase() == 'PAID';

  factory FineModel.fromJson(Map<String, dynamic> json) {
    final license = json['license'];
    final user = license is Map<String, dynamic> ? license['user'] : null;
    final officer = json['trafficOfficer'] ?? json['officer'];
    final rawOffenses =
        json['offenses'] ?? json['fineDetails'] ?? json['items'] ?? json['fine'];

    final offenses = rawOffenses is List
        ? rawOffenses
            .whereType<Map<String, dynamic>>()
            .map(OffenseModel.fromJson)
            .toList()
        : _readSingleOffense(json);

    final payment = json['payment'] as Map<String, dynamic>?;

    return FineModel(
      id: _readString(
        json,
        const ['fine_Id', 'id', 'fineId', 'fine_id'],
      ),
      status: _readString(
        json,
        const ['status', 'fineStatus'],
      ),
      issuedAt: _readDate(
        json,
        const ['issue_At', 'issuedAt', 'createdAt', 'fineIssuedAt'],
      ),
      dueDate: _readDate(
        json,
        const ['due_Date', 'dueDate', 'payBy', 'due_at'],
      ),
      licenseNumber: license is Map<String, dynamic>
          ? _readString(
              license,
              const ['license_No', 'licenseNumber', 'licenseNo', 'license_no'],
            )
          : _readString(
              json,
              const ['license_No', 'licenseNumber', 'licenseNo', 'license_no'],
            ),
      driverName: user is Map<String, dynamic>
          ? _readString(
              user,
              const ['full_Name', 'name', 'fullName', 'driverName'],
            )
          : _readString(
              json,
              const ['full_Name', 'driverName', 'name', 'fullName'],
            ),
      offenses: offenses,
      officerName: officer is Map<String, dynamic>
          ? _readString(
              officer,
              const ['name', 'fullName', 'officerName'],
            )
          : _readString(
              json,
              const ['officerName', 'name', 'fullName'],
            ),
      officerBadgeNumber: officer is Map<String, dynamic>
          ? _readString(
              officer,
              const ['badge_No', 'badgeNumber', 'badgeNo'],
            )
          : _readString(
              json,
              const ['officerBadgeNumber', 'badgeNumber', 'badgeNo'],
            ),
      scanLocation: _readScanLocation(json),
      comment: _readString(json, const ['comment', 'officerNote', 'note']),
      paymentAmount: payment != null
          ? _readDouble(payment['amount'] ?? payment['total'])
          : null,
      paymentStatus: payment != null
          ? _readString(payment, const ['status', 'paymentStatus'])
          : null,
    );
  }

  static String _readScanLocation(Map<String, dynamic> json) {
    final direct = _readString(
      json,
      const [
        'scanLocation',
        'scan_location',
        'qrScanLocation',
        'qr_scan_location',
        'location',
      ],
    );

    if (direct.isNotEmpty) return direct;

    final qrScanHistory = json['qrScanHistory'] ??
        json['qr_scan_history'] ??
        json['scanHistory'] ??
        json['scan'];

    if (qrScanHistory is Map<String, dynamic>) {
      return _readString(
        qrScanHistory,
        const [
          'scanLocation',
          'scan_location',
          'location',
        ],
      );
    }

    if (qrScanHistory is List && qrScanHistory.isNotEmpty) {
      final first = qrScanHistory.first;
      if (first is Map<String, dynamic>) {
        return _readString(
          first,
          const [
            'scanLocation',
            'scan_location',
            'location',
          ],
        );
      }
    }

    return '';
  }

  static List<OffenseModel> _readSingleOffense(Map<String, dynamic> json) {
    final offense = json['offenseCategory'] ?? json['offense'] ?? json['item'];

    if (offense is Map<String, dynamic>) {
      return [OffenseModel.fromJson(offense)];
    }

    final offenseName =
        json['offenseName']?.toString() ?? json['title']?.toString() ?? '';

    if (offenseName.trim().isEmpty) {
      return <OffenseModel>[];
    }

    return [
      OffenseModel(
        id: '',
        code: '',
        name: offenseName,
        description: offenseName,
        amount: _readDouble(json['amount'] ?? json['fee']),
        points: _readInt(json['points'] ?? json['demeritPoints']),
        isCourtCase: false,
      ),
    ];
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
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

  static DateTime? _readDate(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = json[key]?.toString() ?? '';
      if (raw.trim().isEmpty) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return null;
  }
}

class DistrictStatisticsModel {
  const DistrictStatisticsModel({
    required this.totalOfficers,
    required this.activeOfficersOnDuty,
    required this.totalFinesIssued,
    required this.totalRevenue,
    required this.pendingFinesCount,
    required this.overdueCourtCases,
  });

  final int totalOfficers;
  final int activeOfficersOnDuty;
  final int totalFinesIssued;
  final double totalRevenue;
  final int pendingFinesCount;
  final int overdueCourtCases;

  factory DistrictStatisticsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DistrictStatisticsModel(
      totalOfficers: _readInt(json['totalOfficers']),
      activeOfficersOnDuty: _readInt(json['activeOfficersOnDuty']),
      totalFinesIssued: _readInt(json['totalFinesIssued']),
      totalRevenue: _readDouble(json['totalRevenue']),
      pendingFinesCount: _readInt(json['pendingFinesCount']),
      overdueCourtCases: _readInt(json['overdueCourtCases']),
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

class FineIssueResultModel {
  const FineIssueResultModel({
    required this.fineId,
    required this.licenseId,
    required this.status,
    this.licenseStatus = '',
    this.accumulatedPoints = 0,
    this.temporaryLicenseExpiry,
    this.fineDetails = const [],
  });

  final String fineId;
  final String licenseId;
  final String status;
  final String licenseStatus;
  final int accumulatedPoints;
  final DateTime? temporaryLicenseExpiry;
  final List<FineModel> fineDetails;

  factory FineIssueResultModel.fromJson(Map<String, dynamic> json) {
    final fineDetails = json['offenses'] as List? ?? [];
    final licenseData = json['license'] as Map<String, dynamic>? ?? {};

    return FineIssueResultModel(
      fineId: json['fine_Id']?.toString() ?? json['id']?.toString() ?? '',
      licenseId: json['license_Id']?.toString() ??
          json['licenseId']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'PENDING',
      licenseStatus: licenseData['status']?.toString() ?? 'ACTIVE',
      accumulatedPoints: licenseData['points'] as int? ?? 24,
      temporaryLicenseExpiry: json['temporaryLicenseExpiry'] != null
          ? DateTime.tryParse(json['temporaryLicenseExpiry'].toString())
          : null,
      fineDetails: fineDetails
          .map((e) => FineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}