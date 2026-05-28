import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PoliceSession {
  const PoliceSession({
    required this.accessToken,
    required this.officerId,
    required this.officerName,
    required this.role,
    required this.districtId,
    required this.loginAt,
    required this.tokenExpiresAt,
  });

  final String accessToken;
  final String officerId;
  final String officerName;
  final String role;
  final String districtId;
  final DateTime loginAt;
  final DateTime? tokenExpiresAt;

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
  static const String _officerRoleKey = 'officer_role';
  static const String _districtIdKey = 'district_id';
  static const String _loginAtKey = 'login_at';
  static const String _tokenExpiresAtKey = 'token_expires_at';
  static const String _loggedOutKey = 'logged_out';

  Future<void> saveSession({
    required String accessToken,
    required String officerId,
    required String officerName,
    required String role,
    required String districtId,
  }) async {
    final loginAt = DateTime.now();
    final tokenExpiresAt = _readJwtExpiry(accessToken);

    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _officerIdKey, value: officerId);
    await _storage.write(key: _officerNameKey, value: officerName);
    await _storage.write(key: _officerRoleKey, value: role);
    await _storage.write(key: _districtIdKey, value: districtId);
    await _storage.write(key: _loginAtKey, value: loginAt.toIso8601String());
    await _storage.write(
      key: _tokenExpiresAtKey,
      value: tokenExpiresAt?.toIso8601String() ?? '',
    );
    await _storage.write(key: _loggedOutKey, value: 'false');
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
    final role = await _storage.read(key: _officerRoleKey);
    final districtId = await _storage.read(key: _districtIdKey);
    final loginAtValue = await _storage.read(key: _loginAtKey);
    final tokenExpiresAtValue = await _storage.read(key: _tokenExpiresAtKey);

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

    final tokenExpiresAt = tokenExpiresAtValue == null ||
        tokenExpiresAtValue.trim().isEmpty
        ? null
        : DateTime.tryParse(tokenExpiresAtValue);

    final session = PoliceSession(
      accessToken: accessToken,
      officerId: officerId,
      officerName: officerName,
      role: role,
      districtId: districtId,
      loginAt: loginAt,
      tokenExpiresAt: tokenExpiresAt,
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
    await _storage.delete(key: _officerRoleKey);
    await _storage.delete(key: _districtIdKey);
    await _storage.delete(key: _loginAtKey);
    await _storage.delete(key: _tokenExpiresAtKey);
    await _storage.write(key: _loggedOutKey, value: 'true');
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