class ApiConstants {
  static const String emulatorBaseUrl = 'http://10.0.2.2:3000';
  static const String phoneBaseUrl = 'http://127.0.0.1:3000';
  static const String baseUrl = phoneBaseUrl;

  static const String login = '/auth/login';
  static const String registerOfficer = '/officers/register';
  static const String districtOfficers = '/officers/my-district';
  static const String assignShift = '/officers/shift';

  static const String districtCourtCases = '/fines/district/court-cases';
  static const String resolveCourtCasePrefix = '/fines/court';
  static const String districtStatistics = '/fines/district/statistics';

  static const String offenses = '/fines/offenses';
  static const String verifyLicensePrefix = '/fines/verify-license';
  static const String issueFine = '/fines/issue';
  static const String fineHistory = '/fines/history';
}