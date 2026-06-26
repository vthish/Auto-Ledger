import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> checkBiometricsAvailable() async {
    try {
      print('🔍 [BiometricService] Checking biometric availability...');

      final isDeviceSupported = await _auth.isDeviceSupported();
      print('📱 [BiometricService] isDeviceSupported: $isDeviceSupported');

      if (!isDeviceSupported) {
        print('❌ [BiometricService] Device does NOT support biometrics.');
        return false;
      }

      final canCheck = await _auth.canCheckBiometrics;
      print('🔍 [BiometricService] canCheckBiometrics: $canCheck');

      if (canCheck) {
        final availableBiometrics = await _auth.getAvailableBiometrics();
        print('🔑 [BiometricService] Available Biometrics: $availableBiometrics');
        // availableBiometrics should contain [BiometricType.fingerprint] or [BiometricType.face] etc.
      }

      return canCheck;
    } catch (e, stacktrace) {
      print('❌ [BiometricService] checkBiometricsAvailable Error: $e');
      print(stacktrace);
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      print('🔐 [BiometricService] Starting authentication...');

      final isDeviceSupported = await _auth.isDeviceSupported();
      print('📱 [BiometricService] (Auth) isDeviceSupported: $isDeviceSupported');

      if (!isDeviceSupported) {
        print('❌ [BiometricService] Device does NOT support biometrics for auth.');
        return false;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to login to Auto-Ledger',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      print('✅ [BiometricService] Authentication result: $authenticated');
      return authenticated;
    } catch (e, stacktrace) {
      print('❌ [BiometricService] Authentication Error: $e');
      print(stacktrace);
      return false;
    }
  }
}