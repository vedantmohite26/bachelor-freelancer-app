class Budget {
  final String userId;
  final double monthlyLimit;
  final Map<String, double>
  categoryLimits; // e.g., {'Food': 5000, 'Rent': 10000}
  final double savingsTargetPercent; // 0-100

  Budget({
    required this.userId,
    required this.monthlyLimit,
    required this.categoryLimits,
    required this.savingsTargetPercent,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'monthlyLimit': monthlyLimit,
      'categoryLimits': categoryLimits,
      'savingsTargetPercent': savingsTargetPercent,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      userId: map['userId'] ?? '',
      monthlyLimit: (map['monthlyLimit'] ?? 0.0).toDouble(),
      categoryLimits: Map<String, double>.from(map['categoryLimits'] ?? {}),
      savingsTargetPercent: (map['savingsTargetPercent'] ?? 0.0).toDouble(),
    );
  }
}
