import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../models/fine_model.dart';

class FineService {
  FineService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<FineModel>> getDistrictCourtCases() async {
    final response = await _apiClient.get(ApiConstants.districtCourtCases);

    if (response is! List) {
      return <FineModel>[];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(FineModel.fromJson)
        .toList();
  }

  Future<void> resolveCourtCase({
    required String fineId,
    required String finalVerdict,
  }) async {
    await _apiClient.patch(
      '${ApiConstants.resolveCourtCasePrefix}/$fineId/resolve',
      body: {
        'finalVerdict': finalVerdict,
      },
    );
  }

  Future<DistrictStatisticsModel> getDistrictStatistics() async {
    final response = await _apiClient.get(ApiConstants.districtStatistics);

    return DistrictStatisticsModel.fromJson(
      response as Map<String, dynamic>,
    );
  }
}
