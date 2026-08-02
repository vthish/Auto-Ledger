import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../models/fine_model.dart';

class FineService {
  FineService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<FineModel>> getDistrictCourtCases() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.districtCourtCases,
      );

      if (response is! List) {
        return <FineModel>[];
      }

      final fines = response
          .whereType<Map<String, dynamic>>()
          .map(FineModel.fromJson)
          .toList();
      return fines;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resolveCourtCase({
    required String fineId,
    required String verdict,
  }) async {
    try {
      await _apiClient.patch(
        '/fines/$fineId/resolve-overdue',
        body: {'verdict': verdict},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<DistrictStatisticsModel> getDistrictStatistics() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.districtStatistics,
      );

      final stats = DistrictStatisticsModel.fromJson(
        response as Map<String, dynamic>,
      );
      return stats;
    } catch (e) {
      rethrow;
    }
  }
}