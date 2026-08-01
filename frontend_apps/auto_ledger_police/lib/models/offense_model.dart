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
    final offenseData = json['offenceCategory'] as Map<String, dynamic>? ?? json;

    final name = _readString(
      offenseData,
      const ['name', 'title', 'offenseName', 'offenseTitle'],
    );
    final description = _readString(
      offenseData,
      const ['description', 'details'],
      fallback: name,
    );

    return OffenseModel(
      id: _readString(
        offenseData,
        const ['offense_Id', 'id', 'offenseId', 'offense_id'],
      ),
      code: _readString(
        offenseData,
        const ['code', 'offenseCode', 'offense_code'],
      ),
      name: name,
      description: description,
      amount: _readDouble(offenseData['amount'] ?? offenseData['fee'] ?? offenseData['price']),
      points: _readInt(offenseData['points_Value'] ?? offenseData['points'] ?? offenseData['demeritPoints']),
      isCourtCase: offenseData['is_Court_Case'] == true ||
          offenseData['isCourtCase'] == true ||
          offenseData['courtCase'] == true ||
          offenseData['is_court_case'] == true,
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
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