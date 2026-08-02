import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static const String adminLogin = '/auth/admin/login';
  static const String headLogin = '/auth/head/login';
  static const String officerLogin = '/auth/officer/login';
  static const String changePassword = '/auth/change-password';
  static const String headForgotPasswordRequest = '/auth/head/forgot-password-request';
  static const String headResetPassword = '/auth/head/reset-password';
  static const String officerForgotPasswordRequest = '/auth/officer/forgot-password-request';
  static const String officerResetPassword = '/auth/officer/reset-password';

  static const String userRegister = '/auth/user/register';
  static const String userVerifyRegistration = '/auth/user/verify-registration';
  static const String userLogin = '/auth/user/login';
  static const String userBiometricLogin = '/auth/user/biometric-login';
  static const String userVerifyDevice = '/auth/user/verify-device';
  static const String userForgotPasswordCheck = '/auth/user/forgot-password-check';
  static const String userResetPassword = '/auth/user/reset-password';
  static const String userChangePassword = '/auth/user/change-password';

  static const String licenseBase = '/license';
  static const String createLicense = '/license';
  static const String myLicense = '/license/my-license';
  static const String searchLicenseByNIC = '/license/search';
  static const String getAllLicenses = '/license/all';
  static const String getLicensesWithFines = '/license/with-fines';
  static const String getUploadUrl = '/license/get-upload-url';
  static const String revokedLicenses = '/license/revoked';
  static const String resolveRevokedLicense = '/license';

  static const String qrGenerate = '/qr/generate';
  static const String qrScan = '/qr/scan/';
  static const String qrStatus = '/qr/status';

  static const String officersBase = '/officers';
  static const String createDivision = '/officers/division';
  static const String createHead = '/officers/head';
  static const String registerOfficer = '/officers/officer';
  static const String assignShift = '/officers/shift';
  static const String districtOfficers = '/officers/my-division';
  static const String divisions = '/officers/divisions';
  static const String divisionalHeads = '/officers/divisional-heads';
  static const String officerShifts = '/officers';
  static const String officerTransfer = '/officers/transfer';

  static const String finesBase = '/fines';
  static const String issueFine = '/fines';
  static const String myFines = '/fines/my-fines';
  static const String officerFines = '/fines/officer-fines';
  static const String fineHistory = '/fines/officer-fines';
  static const String courtCases = '/fines/court-cases';
  static const String districtCourtCases = '/fines/court-cases';
  static const String dashboardStats = '/fines/dashboard-stats';
  static const String districtStatistics = '/fines/dashboard-stats';
  static const String resolveCourtCasePrefix = '/fines';
  static const String offenses = '/fines/offenses';
  static const String allFines = '/fines/dmt/all-fines';
  static const String problematicLicenses = '/fines/dmt/problematic-licenses';

  static const String usersBase = '/users';
  static const String userProfile = '/users/profile';
  static const String updateDevice = '/users/device';
  static const String verifyPhone = '/users/verify-phone';
}