class OffenseModel {
  const OffenseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.amount,
    required this.points,
    required this.isCourtCase,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final double amount;
  final int points;
  final bool isCourtCase;

  factory OffenseModel.fromJson(Map<String, dynamic> json) {
    final description = json['description']?.toString() ?? '';
    final name = json['name']?.toString() ?? description;

    return OffenseModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: name,
      description: description,
      amount: _readDouble(json['amount']),
      points: _readInt(json['points']),
      isCourtCase: json['isCourtCase'] == true,
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}