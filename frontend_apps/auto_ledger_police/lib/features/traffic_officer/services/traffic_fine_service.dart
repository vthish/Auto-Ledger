import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../models/fine_model.dart';
import '../../../models/license_model.dart';
import '../../../models/offense_model.dart';

class TrafficFineService {
  TrafficFineService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<OffenseModel>> getOffenses() async {
    final response = await _apiClient.get(ApiConstants.offenses);
    final items = _unwrapList(response);

    if (items.isEmpty) return <OffenseModel>[];

    final offenses = items
        .whereType<Map<String, dynamic>>()
        .map(OffenseModel.fromJson)
        .toList();

    offenses.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return offenses;
  }

  Future<LicenseModel> scanQr({
    required String sessionId,
  }) async {
    final url = '${ApiConstants.qrScan}$sessionId';

    final response = await _apiClient.post(
      url,
      body: const <String, dynamic>{},
    );

    final payload = _unwrapMap(response);
    final driverData = payload['driver'] as Map<String, dynamic>?;

    if (driverData == null) {
      throw const ApiException(
        statusCode: 400,
        message: 'Invalid QR session. Driver data not found.',
      );
    }

    final licenseData = driverData['license'] as Map<String, dynamic>?;
    if (licenseData == null) {
      throw const ApiException(
        statusCode: 400,
        message: 'Invalid QR session. License data not found.',
      );
    }

    final expiresAt = _readDate(payload['expiresAt']);
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      throw const ApiException(
        statusCode: 400,
        message: 'This QR verification window has expired. Scan the QR code again.',
      );
    }

    final sessionIdFromResponse = payload['sessionId']?.toString() ?? sessionId;

    final license = LicenseModel.fromJson(licenseData);

    return license.copyWith(
      scanToken: sessionIdFromResponse.trim(),
      scanExpiresAt: expiresAt,
      driverName: driverData['name']?.toString() ?? license.driverName,
      nicNo: driverData['nic']?.toString() ?? license.nicNo,
    );
  }

  Future<FineIssueResultModel> issueFine({
    required String sessionId,
    String? licenseId,
    required List<String> offenseIds,
    required String comment,
    required LicenseModel license,
    required List<OffenseModel> selectedOffenses,
  }) async {
    final resolvedOffenseIds = _resolveOffenseIds(
      offenseIds: offenseIds,
      selectedOffenses: selectedOffenses,
    );

    if (sessionId.trim().isEmpty) {
      throw Exception('Session ID is missing.');
    }

    if (resolvedOffenseIds.isEmpty) {
      throw Exception('No valid offense ids selected.');
    }

    final body = <String, dynamic>{
      'sessionId': sessionId.trim(),
      'offenseIds': resolvedOffenseIds,
    };

    final trimmedComment = comment.trim();
    if (trimmedComment.isNotEmpty) {
      body['comment'] = trimmedComment;
    }

    final response = await _apiClient.post(
      ApiConstants.issueFine,
      body: body,
    );

    final payload = _unwrapMap(response);

    final fineDetails = _buildFineDetails(
      payload: payload,
      selectedOffenses: selectedOffenses,
      license: license,
    );

    return FineIssueResultModel(
      fineId: _readString(
        payload,
        const ['fine_Id', 'fineId', 'fine_id', 'id'],
      ),
      licenseId: _readString(
        payload,
        const ['license_Id', 'licenseId', 'license_id'],
        fallback: licenseId?.trim().isNotEmpty == true
            ? licenseId!.trim()
            : license.licenseNumber,
      ),
      status: _readString(
        payload,
        const ['status', 'fineStatus'],
        fallback: 'PENDING',
      ),
      licenseStatus: _readString(
        payload,
        const ['licenseStatus', 'license_status'],
        fallback: license.status,
      ),
      accumulatedPoints: _readInt(
        payload['accumulatedPoints'] ??
            payload['currentPoints'] ??
            payload['points'] ??
            license.points,
      ),
      temporaryLicenseExpiry: _readDate(
        payload['temporaryLicenseExpiry'] ??
            payload['temporary_license_expiry'] ??
            payload['tempLicenseExpiry'] ??
            payload['temporaryExpiry'],
      ),
      fineDetails: fineDetails,
    );
  }

  Future<List<FineModel>> getFineHistory() async {
    final response = await _apiClient.get(ApiConstants.fineHistory);
    final items = _unwrapList(response);

    if (items.isEmpty) return <FineModel>[];

    final fines = items
        .whereType<Map<String, dynamic>>()
        .map(FineModel.fromJson)
        .toList();

    fines.sort((a, b) {
      final aDate = a.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return fines;
  }

  Map<String, dynamic> _unwrapMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;

      final result = response['result'];
      if (result is Map<String, dynamic>) return result;

      return response;
    }

    return <String, dynamic>{};
  }

  List<dynamic> _unwrapList(dynamic response) {
    if (response is List) return response;

    if (response is Map<String, dynamic>) {
      final items = response['items'];
      if (items is List) return items;

      final data = response['data'];
      if (data is List) return data;

      final fines = response['fines'];
      if (fines is List) return fines;

      final results = response['results'];
      if (results is List) return results;
    }

    return <dynamic>[];
  }

  List<FineModel> _buildFineDetails({
    required Map<String, dynamic> payload,
    required List<OffenseModel> selectedOffenses,
    required LicenseModel license,
  }) {
    final rawFineDetails = payload['offenses'] ??
        payload['fineDetails'] ??
        payload['items'] ??
        payload['fine'];

    if (rawFineDetails is List) {
      final parsed = rawFineDetails
          .whereType<Map<String, dynamic>>()
          .map(FineModel.fromJson)
          .toList();

      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    final dueDate = _readDate(
      payload['dueDate'] ?? payload['payBy'] ?? payload['due_at'],
    );

    final status = _readString(
      payload,
      const ['status', 'fineStatus'],
      fallback: 'PENDING',
    );

    return selectedOffenses.map((offense) {
      return FineModel(
        id: offense.id.isNotEmpty ? offense.id : offense.code,
        status: status,
        issuedAt: DateTime.now(),
        dueDate: dueDate,
        licenseNumber: license.licenseNumber,
        driverName: license.driverName,
        offenses: [offense],
        officerName: '',
        officerBadgeNumber: '',
      );
    }).toList();
  }

  List<String> _resolveOffenseIds({
    required List<String> offenseIds,
    required List<OffenseModel> selectedOffenses,
  }) {
    final selectedIds = selectedOffenses
        .map((offense) => offense.id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (selectedIds.isNotEmpty) {
      return selectedIds;
    }

    return offenseIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  String _readString(
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

  int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}