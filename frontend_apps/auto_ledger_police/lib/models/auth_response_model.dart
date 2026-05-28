import 'officer_model.dart';

class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.officer,
  });

  final String accessToken;
  final OfficerModel officer;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken']?.toString() ?? '',
      officer: OfficerModel.fromJson(
        (json['officer'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}