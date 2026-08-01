import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../models/officer_model.dart';
import '../../../models/shift_model.dart';

class OfficerService {
  OfficerService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<OfficerModel> registerTrafficOfficer({
    required String name,
    required String email,
    required String badgeNumber,
    required String password,
  }) async {
    final payload = {
      'badgeNo': badgeNumber.trim(),
      'email': email.trim(),
      'name': name.trim(),
      'passwordStr': password.trim(),
    };

    try {
      final response = await _apiClient.post(
        ApiConstants.registerOfficer,
        body: payload,
      );

      final data = _extractMap(response);
      if (data != null) {
        return OfficerModel.fromJson(data);
      }

      return OfficerModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<OfficerModel>> getDistrictTrafficOfficers() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.districtOfficers,
      );

      final rawList = _extractList(response);
      final officers = rawList.map(OfficerModel.fromJson).toList();

      return officers;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ShiftModel>> getOfficerShifts(String officerId) async {
    try {
      final response = await _apiClient.get(
        '/officers/$officerId/shifts',
      );

      final rawList = _extractList(response);
      final shifts = rawList.map(ShiftModel.fromJson).toList();

      return shifts;
    } catch (e) {
      rethrow;
    }
  }

  Future<ShiftModel> assignShift({
    required String officerId,
    required DateTime startTime,
    required DateTime endTime,
    String location = 'Duty Location',
  }) async {
    final payload = {
      'officerId': officerId,
      'date': DateTime.now().toUtc().toIso8601String(),
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'location': location.trim(),
    };

    try {
      final response = await _apiClient.post(
        ApiConstants.assignShift,
        body: payload,
      );

      final data = _extractMap(response);
      if (data != null) {
        return ShiftModel.fromJson(data);
      }

      return ShiftModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<ShiftModel> updateShift({
    required String shiftId,
    DateTime? startTime,
    required DateTime endTime,
    String location = 'Duty Location',
  }) async {
    final payload = <String, dynamic>{
      'endTime': endTime.toUtc().toIso8601String(),
      'location': location.trim(),
    };

    if (startTime != null) {
      payload['startTime'] = startTime.toUtc().toIso8601String();
    }

    try {
      final response = await _apiClient.patch(
        '/officers/shift/$shiftId',
        body: payload,
      );

      final data = _extractMap(response);
      if (data != null) {
        return ShiftModel.fromJson(data);
      }

      return ShiftModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> transferOfficer({
    required String officerId,
    required String newHeadId,
  }) async {
    try {
      await _apiClient.patch(
        '/officers/transfer/$officerId',
        body: {'newHeadId': newHeadId},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DivisionalHeadModel>> getDivisionalHeads() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.divisionalHeads,
      );

      final rawList = _extractList(response);
      final heads = rawList.map(DivisionalHeadModel.fromJson).toList();

      return heads;
    } catch (e) {
      return [];
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic response) {
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }

    if (response is Map<String, dynamic>) {
      final keys = <String>[
        'data',
        'items',
        'results',
        'officers',
        'shifts',
        'list',
        'divisionalHeads',
        'divisional_heads',
      ];

      for (final key in keys) {
        final candidate = response[key];
        final extracted = _extractList(candidate);

        if (extracted.isNotEmpty) {
          return extracted;
        }
      }
    }

    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic>? _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final dataKeys = <String>[
        'data',
        'result',
        'item',
        'officer',
        'shift',
      ];

      for (final key in dataKeys) {
        final candidate = response[key];

        if (candidate is Map<String, dynamic>) {
          return candidate;
        }
      }

      return response;
    }

    return null;
  }
}

class DivisionalHeadModel {
  const DivisionalHeadModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.divisionId,
    required this.divisionName,
    required this.isActive,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String divisionId;
  final String divisionName;
  final bool isActive;

  factory DivisionalHeadModel.fromJson(Map<String, dynamic> json) {
    final division = json['division'] as Map<String, dynamic>? ?? {};

    return DivisionalHeadModel(
      id: json['divisional_Head_Id']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      divisionId: json['division_Id']?.toString() ??
          division['division_Id']?.toString() ??
          '',
      divisionName: division['division_Name']?.toString() ?? '',
      isActive: json['is_Active'] == true || json['isActive'] == true,
    );
  }
}