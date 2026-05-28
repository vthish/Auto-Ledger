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
    required String badgeNumber,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.registerOfficer,
      body: {
        'name': name.trim(),
        'badgeNumber': badgeNumber.trim(),
        'password': password.trim(),
      },
    );

    return OfficerModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<OfficerModel>> getDistrictTrafficOfficers() async {
    final response = await _apiClient.get(ApiConstants.districtOfficers);

    if (response is! List) {
      return <OfficerModel>[];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(OfficerModel.fromJson)
        .toList();
  }

  Future<ShiftModel> assignShift({
    required String officerId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.assignShift,
      body: {
        'officerId': officerId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      },
    );

    return ShiftModel.fromJson(response as Map<String, dynamic>);
  }
}