import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PoliceSession {
  const PoliceSession({
    required this.accessToken,
    required this.officerId,
    required this.officerName,
    required this.officerBadgeNumber,
    required this.role,
    required this.districtId,
    required this.loginAt,
    required this.tokenExpiresAt,
    required this.email,
    required this.divisionName,
    required this.divisionalHeadName,
    this.dutyLocation = '',
  });

  final String accessToken;
  final String officerId;
  final String officerName;
  final String officerBadgeNumber;
  final String role;
  final String districtId;
  final DateTime loginAt;
  final DateTime? tokenExpiresAt;
  final String email;
  final String divisionName;
  final String divisionalHeadName;
  final String dutyLocation;

  bool get isValid {
    final now = DateTime.now();
    final threeDayExpiry = loginAt.add(const Duration(days: 3));

    if (now.isAfter(threeDayExpiry)) {
      return false;
    }

    if (tokenExpiresAt != null && now.isAfter(tokenExpiresAt!)) {
      return false;
    }

    return true;
  }
}

class TokenStorage {
  const TokenStorage();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _officerIdKey = 'officer_id';
  static const String _officerNameKey = 'officer_name';
  static const String _officerBadgeNumberKey = 'officer_badge_number';
  static const String _officerRoleKey = 'officer_role';
  static const String _districtIdKey = 'district_id';
  static const String _loginAtKey = 'login_at';
  static const String _tokenExpiresAtKey = 'token_expires_at';
  static const String _loggedOutKey = 'logged_out';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _deviceIdKey = 'device_id';
  static const String _emailKey = 'email';
  static const String _divisionNameKey = 'division_name';
  static const String _divisionalHeadNameKey = 'divisional_head_name';
  static const String _dutyLocationKey = 'duty_location';

  Future<void> saveSession({
    required String accessToken,
    required String officerId,
    required String officerName,
    required String officerBadgeNumber,
    required String role,
    required String districtId,
    required String email,
    required String divisionName,
    required String divisionalHeadName,
    String dutyLocation = '',
  }) async {
    final loginAt = DateTime.now();
    final tokenExpiresAt = _readJwtExpiry(accessToken);

    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _officerIdKey, value: officerId);
    await _storage.write(key: _officerNameKey, value: officerName);
    await _storage.write(
      key: _officerBadgeNumberKey,
      value: officerBadgeNumber,
    );
    await _storage.write(key: _officerRoleKey, value: role);
    await _storage.write(key: _districtIdKey, value: districtId);
    await _storage.write(key: _loginAtKey, value: loginAt.toIso8601String());
    await _storage.write(
      key: _tokenExpiresAtKey,
      value: tokenExpiresAt?.toIso8601String() ?? '',
    );
    await _storage.write(key: _loggedOutKey, value: 'false');
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _divisionNameKey, value: divisionName);
    await _storage.write(key: _divisionalHeadNameKey, value: divisionalHeadName);
    await _storage.write(key: _dutyLocationKey, value: dutyLocation.trim());
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<PoliceSession?> getSession() async {
    final loggedOut = await _storage.read(key: _loggedOutKey);

    if (loggedOut == 'true') {
      return null;
    }

    final accessToken = await _storage.read(key: _accessTokenKey);
    final officerId = await _storage.read(key: _officerIdKey);
    final officerName = await _storage.read(key: _officerNameKey);
    final officerBadgeNumber = await _storage.read(key: _officerBadgeNumberKey);
    final role = await _storage.read(key: _officerRoleKey);
    final districtId = await _storage.read(key: _districtIdKey);
    final loginAtValue = await _storage.read(key: _loginAtKey);
    final tokenExpiresAtValue = await _storage.read(key: _tokenExpiresAtKey);
    final email = await _storage.read(key: _emailKey);
    final divisionName = await _storage.read(key: _divisionNameKey);
    final divisionalHeadName = await _storage.read(key: _divisionalHeadNameKey);
    final dutyLocation = await _storage.read(key: _dutyLocationKey);

    if (accessToken == null ||
        officerId == null ||
        officerName == null ||
        role == null ||
        districtId == null ||
        loginAtValue == null) {
      return null;
    }

    final loginAt = DateTime.tryParse(loginAtValue);

    if (loginAt == null) {
      return null;
    }

    final tokenExpiresAt =
        tokenExpiresAtValue == null || tokenExpiresAtValue.trim().isEmpty
            ? null
            : DateTime.tryParse(tokenExpiresAtValue);

    final session = PoliceSession(
      accessToken: accessToken,
      officerId: officerId,
      officerName: officerName,
      officerBadgeNumber: officerBadgeNumber ?? '',
      role: role,
      districtId: districtId,
      loginAt: loginAt,
      tokenExpiresAt: tokenExpiresAt,
      email: email ?? '',
      divisionName: divisionName ?? '',
      divisionalHeadName: divisionalHeadName ?? '',
      dutyLocation: dutyLocation ?? '',
    );

    if (!session.isValid) {
      await clearSession();
      return null;
    }

    return session;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _officerIdKey);
    await _storage.delete(key: _officerNameKey);
    await _storage.delete(key: _officerBadgeNumberKey);
    await _storage.delete(key: _officerRoleKey);
    await _storage.delete(key: _districtIdKey);
    await _storage.delete(key: _loginAtKey);
    await _storage.delete(key: _tokenExpiresAtKey);
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _deviceIdKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _divisionNameKey);
    await _storage.delete(key: _divisionalHeadNameKey);
    await _storage.delete(key: _dutyLocationKey);
    await _storage.write(key: _loggedOutKey, value: 'true');
  }

  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  Future<String?> getDeviceId() async {
    return _storage.read(key: _deviceIdKey);
  }

  Future<void> saveBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  Future<bool> getBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  DateTime? _readJwtExpiry(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = jsonDecode(decodedPayload);

      if (payloadMap is! Map<String, dynamic>) {
        return null;
      }

      final exp = payloadMap['exp'];

      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}