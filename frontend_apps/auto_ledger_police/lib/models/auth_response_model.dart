import 'officer_model.dart';

class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.officer,
  });

  final String accessToken;
  final OfficerModel officer;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final officerData =
        json['officer'] as Map<String, dynamic>? ??
        json['user'] as Map<String, dynamic>? ??
        <String, dynamic>{};

    return AuthResponseModel(
      accessToken: json['accessToken']?.toString() ??
          json['token']?.toString() ??
          '',
      officer: OfficerModel.fromJson(officerData),
    );
  }
}