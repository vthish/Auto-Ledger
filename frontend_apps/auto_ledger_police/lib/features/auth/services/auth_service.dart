import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/auth_response_model.dart';

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthResponseModel> login({
    required String badgeNumber,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      requiresAuth: false,
      body: {
        'badgeNumber': badgeNumber.trim(),
        'password': password.trim(),
      },
    );

    final authResponse = AuthResponseModel.fromJson(
      response as Map<String, dynamic>,
    );

    await _tokenStorage.saveSession(
      accessToken: authResponse.accessToken,
      officerId: authResponse.officer.id,
      officerName: authResponse.officer.name,
      officerBadgeNumber: authResponse.officer.badgeNumber,
      role: authResponse.officer.role,
      districtId: authResponse.officer.districtId,
    );

    return authResponse;
  }

  Future<void> logout() async {
    await _tokenStorage.clearSession();
  }
}