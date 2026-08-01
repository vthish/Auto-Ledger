import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/auth_response_model.dart';

enum LoginRole {
  divisionalHead,
  trafficOfficer,
}

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  void _resetApiClient() {
    _apiClient = ApiClient();
  }

  Future<AuthResponseModel> login({
    String? username,
    String? loginId,
    required String password,
    LoginRole loginRole = LoginRole.trafficOfficer,
  }) async {
    _resetApiClient();

    final resolvedLoginId = (loginId ?? username ?? '').trim();

    final endpoint = loginRole == LoginRole.divisionalHead
        ? ApiConstants.headLogin
        : ApiConstants.officerLogin;

    final payload = loginRole == LoginRole.divisionalHead
        ? {
            'username': resolvedLoginId,
            'password': password.trim(),
          }
        : {
            'badgeNo': resolvedLoginId,
            'password': password.trim(),
          };

    final response = await _apiClient.post(
      endpoint,
      requiresAuth: false,
      body: payload,
    );

    final authResponse = AuthResponseModel.fromJson(
      response as Map<String, dynamic>,
    );

    await _saveAuthenticatedSession(authResponse);

    return authResponse;
  }

  Future<AuthResponseModel> smartLogin({
    required String loginId,
    required String password,
  }) async {
    _resetApiClient();

    try {
      final response = await _apiClient.post(
        ApiConstants.headLogin,
        requiresAuth: false,
        body: {
          'username': loginId.trim(),
          'password': password.trim(),
        },
      );

      final authResponse = AuthResponseModel.fromJson(
        response as Map<String, dynamic>,
      );

      await _saveAuthenticatedSession(authResponse);

      return authResponse;
    } on ApiException catch (e) {
      if (e.statusCode != 401 && e.statusCode != 404) {
        rethrow;
      }
    }

    try {
      final response = await _apiClient.post(
        ApiConstants.officerLogin,
        requiresAuth: false,
        body: {
          'badgeNo': loginId.trim(),
          'password': password.trim(),
        },
      );

      final authResponse = AuthResponseModel.fromJson(
        response as Map<String, dynamic>,
      );

      await _saveAuthenticatedSession(authResponse);

      return authResponse;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 404) {
        throw ApiException(
          statusCode: 401,
          message: 'Please check your ID/Badge and Password.',
        );
      }
      rethrow;
    }
  }

  Future<void> requestForgotPasswordOtp({
    required String badgeNo,
    required String email,
  }) async {
    _resetApiClient();
    await _apiClient.post(
      ApiConstants.officerForgotPasswordRequest,
      requiresAuth: false,
      body: {
        'badgeNo': badgeNo.trim(),
        'email': email.trim(),
      },
    );
  }

  Future<void> resetForgottenPassword({
    required String badgeNo,
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _resetApiClient();
    await _apiClient.post(
      ApiConstants.officerResetPassword,
      requiresAuth: false,
      body: {
        'badgeNo': badgeNo.trim(),
        'email': email.trim(),
        'otp': otp.trim(),
        'newPasswordStr': newPassword.trim(),
      },
    );
  }

  Future<void> requestHeadForgotPasswordOtp({
    required String username,
    required String email,
  }) async {
    _resetApiClient();
    await _apiClient.post(
      ApiConstants.headForgotPasswordRequest,
      requiresAuth: false,
      body: {
        'username': username.trim(),
        'email': email.trim(),
      },
    );
  }

  Future<void> resetHeadForgottenPassword({
    required String username,
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _resetApiClient();
    await _apiClient.post(
      ApiConstants.headResetPassword,
      requiresAuth: false,
      body: {
        'username': username.trim(),
        'email': email.trim(),
        'otp': otp.trim(),
        'newPasswordStr': newPassword.trim(),
      },
    );
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.patch(
      ApiConstants.changePassword,
      body: {
        'oldPassword': oldPassword.trim(),
        'newPassword': newPassword.trim(),
      },
    );
  }

  Future<void> logout() async {
    await _tokenStorage.clearSession();
  }

  Future<void> _saveAuthenticatedSession(AuthResponseModel authResponse) async {
    await _tokenStorage.saveSession(
      accessToken: authResponse.accessToken,
      officerId: authResponse.officer.id,
      officerName: authResponse.officer.name,
      officerBadgeNumber: authResponse.officer.badgeNumber,
      role: authResponse.officer.role,
      districtId: authResponse.officer.divisionId,
      email: authResponse.officer.email,
      divisionName: authResponse.officer.divisionName,
      divisionalHeadName: authResponse.officer.divisionalHeadName,
      dutyLocation: authResponse.officer.dutyLocation,
    );

    await _ensureDeviceId();
  }

  Future<void> _ensureDeviceId() async {
    final existingDeviceId = await _tokenStorage.getDeviceId();

    if (existingDeviceId == null || existingDeviceId.isEmpty) {
      final defaultDeviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await _tokenStorage.saveDeviceId(defaultDeviceId);
    }
  }
}