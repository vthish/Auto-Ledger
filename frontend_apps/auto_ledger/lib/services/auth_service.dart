import 'package:dio/dio.dart';
import 'api_service.dart';
import '../utils/secure_storage.dart';

class AuthService {
  static String _errorMessage(
    DioException error,
    String fallback,
  ) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return fallback;
  }

  static Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> data,
  ) async {
    try {
      final response =
          await ApiService.dio.post('/auth/user/register', data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data is Map<String, dynamic>
              ? response.data['message'] ?? 'OTP sent successfully.'
              : 'OTP sent successfully.',
        };
      }

      return {
        'success': false,
        'message': 'Registration failed. Please try again.',
      };
    } on DioException catch (error) {
      return {
        'success': false,
        'message': _errorMessage(
          error,
          'Registration failed. Please check your NIC and email.',
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyRegistration(
    String nicNo,
    String otp,
  ) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/verify-registration',
        data: {'nicNo': nicNo, 'otp': otp},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await SecureStorage.deleteToken();

        return {
          'success': true,
          'message': response.data is Map<String, dynamic>
              ? response.data['message'] ??
                  'Registration successful. Please login.'
              : 'Registration successful. Please login.',
        };
      }

      return {
        'success': false,
        'message': 'OTP verification failed.',
      };
    } on DioException catch (error) {
      return {
        'success': false,
        'message': _errorMessage(
          error,
          'Invalid OTP. Please try again.',
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'OTP verification failed.',
      };
    }
  }

  static Future<bool> resendRegistrationOtp(String nicNo) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/resend-registration-otp',
        data: {'nicNo': nicNo},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> loginUser(
      String nicNo, String password, String deviceId) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/login',
        data: {
          'nicNo': nicNo,
          'password': password,
          'deviceId': deviceId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['accessToken'];
        await SecureStorage.saveToken(token);
        return {'success': true};
      }
      return {'success': false};
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 &&
          e.response?.data['code'] == 'DEVICE_MISMATCH') {
        return {
          'success': false,
          'isDeviceMismatch': true,
          'email': e.response?.data['email'] ?? '',
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  static Future<bool> forgotPasswordCheck(String nicNo, String email) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/forgot-password-check',
        data: {
          'nicNo': nicNo,
          'email': email,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> verifyResetOtp(String nicNo, String email, String otp) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/verify-reset-otp',
        data: {
          'nicNo': nicNo,
          'email': email,
          'otp': otp,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> resendResetOtp(String nicNo, String email) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/resend-reset-otp',
        data: {
          'nicNo': nicNo,
          'email': email,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> resetPassword(
      String nicNo, String email, String otp, String newPassword) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/reset-password',
        data: {
          'nicNo': nicNo,
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> biometricLogin(
      String nicNo, String deviceId) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/biometric-login',
        data: {
          'nicNo': nicNo,
          'deviceId': deviceId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['accessToken'];
        await SecureStorage.saveToken(token);
        return {'success': true};
      }
      return {'success': false};
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 &&
          e.response?.data['code'] == 'DEVICE_MISMATCH') {
        return {
          'success': false,
          'isDeviceMismatch': true,
          'email': e.response?.data['email'] ?? '',
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> verifyNewDevice(
      String nicNo, String deviceId, String otp) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/verify-device',
        data: {
          'nicNo': nicNo,
          'deviceId': deviceId,
          'otp': otp,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['accessToken'];
        await SecureStorage.saveToken(token);
        await SecureStorage.saveNic(nicNo);
        return {'success': true};
      }
      return {'success': false, 'message': 'Verification failed.'};
    } on DioException catch (e) {
      String errorMsg = 'Invalid OTP. Please try again.';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        errorMsg = e.response?.data['message'] is List
            ? e.response?.data['message'][0]
            : e.response?.data['message'];
      }
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during verification.'
      };
    }
  }

  static Future<bool> resendDeviceOtp(String nicNo, String email) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/resend-device-otp',
        data: {
          'nicNo': nicNo,
          'email': email,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> resendHeadOtp(String username, String email) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/head/resend-otp',
        data: {
          'username': username,
          'email': email,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> resendOfficerOtp(String badgeNo, String email) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/officer/resend-otp',
        data: {
          'badgeNo': badgeNo,
          'email': email,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> headForgotPasswordRequest(
      String username, String email) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/head/forgot-password-request',
        data: {
          'username': username,
          'email': email,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> headVerifyResetOtp(
      String username, String email, String otp) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/head/verify-reset-otp',
        data: {
          'username': username,
          'email': email,
          'otp': otp,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> headResetPassword(
      String username, String email, String otp, String newPassword) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/head/reset-password',
        data: {
          'username': username,
          'email': email,
          'otp': otp,
          'newPasswordStr': newPassword,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> officerForgotPasswordRequest(
      String badgeNo, String email) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/officer/forgot-password-request',
        data: {
          'badgeNo': badgeNo,
          'email': email,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> officerVerifyResetOtp(
      String badgeNo, String email, String otp) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/officer/verify-reset-otp',
        data: {
          'badgeNo': badgeNo,
          'email': email,
          'otp': otp,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> officerResetPassword(
      String badgeNo, String email, String otp, String newPassword) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/officer/reset-password',
        data: {
          'badgeNo': badgeNo,
          'email': email,
          'otp': otp,
          'newPasswordStr': newPassword,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    await SecureStorage.deleteToken();
  }
}
