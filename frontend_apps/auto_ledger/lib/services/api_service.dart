import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/secure_storage.dart';
import '../utils/device_info.dart';
import '../utils/settings_util.dart';
import '../screens/login_screen.dart';
import 'navigation_service.dart';
import 'session_service.dart';

class ApiService {
  static const Set<String> _loginManagedDeviceMismatchPaths = {
    '/auth/user/login',
    '/auth/user/biometric-login',
    '/auth/user/verify-device',
    '/auth/user/resend-device-otp',
  };

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_URL'] ?? 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static bool _isLoginManagedDeviceMismatch(String path) {
    return _loginManagedDeviceMismatchPaths.any(path.endsWith);
  }

  static bool _isAuthenticationRequest(String path) {
    return path.startsWith('/auth/');
  }

  static void init() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        try {
          final deviceId = await DeviceInfoUtil.getDeviceId();
          options.headers['device-id'] = deviceId;
        } catch (_) {}

        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        final path = error.requestOptions.path;
        final isDeviceMismatch = error.response?.statusCode == 403 &&
            error.response?.data['code'] == 'DEVICE_MISMATCH';
        final isHandledByLoginScreen =
            _isLoginManagedDeviceMismatch(path);

        if (isDeviceMismatch && !isHandledByLoginScreen) {
          await SecureStorage.deleteToken();
          await SecureStorage.deleteNic();
          await SettingsUtil.setBiometricEnabled(false);
          NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          return handler.next(error);
        }

        final isUnauthorized = error.response?.statusCode == 401;
        if (isUnauthorized && !_isAuthenticationRequest(path)) {
          await SessionService.instance.expireNow();
        }

        return handler.next(error);
      },
    ));
  }

  static Dio get dio => _dio;
}
