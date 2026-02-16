enum RiskAppetite { strict, balanced, aggressive }

class FinancialProfile {
  final String userId;
  final RiskAppetite riskAppetite;
  final double shortTermGoalAmount;
  final DateTime? shortTermGoalDeadline;
  final double longTermGoalAmount;
  final DateTime? longTermGoalDeadline;

  FinancialProfile({
    required this.userId,
    required this.riskAppetite,
    required this.shortTermGoalAmount,
    this.shortTermGoalDeadline,
    required this.longTermGoalAmount,
    this.longTermGoalDeadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'riskAppetite': riskAppetite.toString().split('.').last,
      'shortTermGoalAmount': shortTermGoalAmount,
      'shortTermGoalDeadline': shortTermGoalDeadline?.toIso8601String(),
      'longTermGoalAmount': longTermGoalAmount,
      'longTermGoalDeadline': longTermGoalDeadline?.toIso8601String(),
    };
  }

  factory FinancialProfile.fromMap(Map<String, dynamic> map) {
    return FinancialProfile(
      userId: map['userId'] ?? '',
      riskAppetite: RiskAppetite.values.firstWhere(
        (e) =>
            e.toString().split('.').last == (map['riskAppetite'] ?? 'balanced'),
        orElse: () => RiskAppetite.balanced,
      ),
      shortTermGoalAmount: (map['shortTermGoalAmount'] ?? 0.0).toDouble(),
      shortTermGoalDeadline: map['shortTermGoalDeadline'] != null
          ? DateTime.parse(map['shortTermGoalDeadline'])
          : null,
      longTermGoalAmount: (map['longTermGoalAmount'] ?? 0.0).toDouble(),
      longTermGoalDeadline: map['longTermGoalDeadline'] != null
          ? DateTime.parse(map['longTermGoalDeadline'])
          : null,
    );
  }
}
