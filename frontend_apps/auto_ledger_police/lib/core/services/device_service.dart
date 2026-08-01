import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceService {
  static const String _deviceIdKey = 'device_id';
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedId = prefs.getString(_deviceIdKey);
    
    if (cachedId != null && cachedId.isNotEmpty) {
      return cachedId;
    }

    String newDeviceId = await _generateDeviceId();
    await prefs.setString(_deviceIdKey, newDeviceId);
    return newDeviceId;
  }

  static Future<String> _generateDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id ?? 'android_${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        return 'web_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}