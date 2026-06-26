import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async =>
      await _storage.write(key: 'jwt_token', value: token);

  static Future<String?> getToken() async =>
      await _storage.read(key: 'jwt_token');

  static Future<void> deleteToken() async =>
      await _storage.delete(key: 'jwt_token');

  static Future<void> saveNic(String nic) async =>
      await _storage.write(key: 'nic_no', value: nic);

  static Future<String?> getNic() async =>
      await _storage.read(key: 'nic_no');

  static Future<void> deleteNic() async =>
      await _storage.delete(key: 'nic_no');
}