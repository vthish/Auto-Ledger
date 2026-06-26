import 'package:dio/dio.dart';
import 'api_service.dart';
import '../utils/secure_storage.dart';

class AuthService {
  static Future<bool> registerUser(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.dio.post('/auth/user/register', data: data);
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException {
      rethrow;
    }
  }

  static Future<bool> verifyRegistration(String nicNo) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/verify-registration',
        data: {'nicNo': nicNo},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['accessToken'];
        await SecureStorage.saveToken(token);
        return true;
      }
      return false;
    } on DioException {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> loginUser(String nicNo, String password, String deviceId) async {
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
      if (e.response?.statusCode == 403 && e.response?.data['code'] == 'DEVICE_MISMATCH') {
        return {
          'success': false,
          'isDeviceMismatch': true,
          'phone': e.response?.data['phone']
        };
      }
      rethrow;
    }
  }

  static Future<bool> verifyNewDevice(String nicNo, String deviceId) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/verify-device',
        data: {
          'nicNo': nicNo,
          'deviceId': deviceId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['accessToken'];
        await SecureStorage.saveToken(token);
        return true;
      }
      return false;
    } on DioException {
      rethrow;
    }
  }

  static Future<bool> forgotPasswordCheck(String nicNo, String phone) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/forgot-password-check',
        data: {
          'nicNo': nicNo,
          'mobilePhoneNo': phone,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      rethrow;
    }
  }

  static Future<bool> resetPassword(String nicNo, String phone, String newPassword) async {
    try {
      final response = await ApiService.dio.post(
        '/auth/user/reset-password',
        data: {
          'nicNo': nicNo,
          'mobilePhoneNo': phone,
          'newPassword': newPassword,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> biometricLogin(String nicNo, String deviceId) async {
    try {
      print('🌐 [AuthService] Calling Biometric Login API for NIC: $nicNo');
      final response = await ApiService.dio.post(
        '/auth/user/biometric-login',
        data: {
          'nicNo': nicNo,
          'deviceId': deviceId,
        },
      );
      print('📡 [AuthService] Biometric API Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['accessToken'];
        await SecureStorage.saveToken(token);
        print('✅ [AuthService] Biometric Login Success. Token saved.');
        return {'success': true};
      }
      print('⚠️ [AuthService] Biometric Login returned non-success status.');
      return {'success': false};
    } on DioException catch (e) {
      print('❌ [AuthService] Biometric API Error: ${e.message}');
      print('❌ [AuthService] Response Data: ${e.response?.data}');
      rethrow;
    }
  }
}