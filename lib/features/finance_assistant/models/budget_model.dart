class Budget {
  final String userId;
  final double monthlyLimit;
  final Map<String, double> categoryLimits;
  final double savingsTargetPercent;
  final double monthlyIncome;
  final double recurringExpenses;

  Budget({
    required this.userId,
    required this.monthlyLimit,
    required this.categoryLimits,
    required this.savingsTargetPercent,
    this.monthlyIncome = 0.0,
    this.recurringExpenses = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'monthlyLimit': monthlyLimit,
      'categoryLimits': categoryLimits,
      'savingsTargetPercent': savingsTargetPercent,
      'monthlyIncome': monthlyIncome,
      'recurringExpenses': recurringExpenses,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      userId: map['userId'] ?? '',
      monthlyLimit: (map['monthlyLimit'] ?? 0.0).toDouble(),
      categoryLimits: Map<String, double>.from(map['categoryLimits'] ?? {}),
      savingsTargetPercent: (map['savingsTargetPercent'] ?? 0.0).toDouble(),
      monthlyIncome: (map['monthlyIncome'] ?? 0.0).toDouble(),
      recurringExpenses: (map['recurringExpenses'] ?? 0.0).toDouble(),
    );
  }
}
