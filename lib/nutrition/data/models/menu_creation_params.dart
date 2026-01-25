class MenuCreationParams {
  final int mealsPerDay;
  final String style; // simples, economico, rapido, saudavel
  final List<String> restrictions;
  final bool allowRepetition;
  final String periodType; // weekly | monthly
  final String objective; // maintenance | emagrecimento
  final DateTime? startDate;
  final int? customDays;

  MenuCreationParams({
    this.mealsPerDay = 4,
    this.style = 'simples',
    this.restrictions = const [],
    this.allowRepetition = true,
    this.periodType = 'weekly',
    this.objective = 'maintenance',
    this.startDate,
    this.customDays,
  });

  MenuCreationParams copyWith({
    int? mealsPerDay,
    String? style,
    List<String>? restrictions,
    bool? allowRepetition,
    String? periodType,
    String? objective,
    DateTime? startDate,
    int? customDays,
  }) {
    return MenuCreationParams(
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      style: style ?? this.style,
      restrictions: restrictions ?? this.restrictions,
      allowRepetition: allowRepetition ?? this.allowRepetition,
      periodType: periodType ?? this.periodType,
      objective: objective ?? this.objective,
      startDate: startDate ?? this.startDate,
      customDays: customDays ?? this.customDays,
    );
  }

  static MenuCreationParams fromMap(Map<String, dynamic> map) {
    return MenuCreationParams(
      mealsPerDay: map['mealsPerDay'] ?? 4,
      style: map['style'] ?? 'simples',
      restrictions:
          (map['restrictions'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      allowRepetition: map['allowRepetition'] ?? true,
      periodType: map['periodType'] ?? 'weekly',
      objective: map['objective'] ?? 'maintenance',
      customDays: map['customDays'],
    );
  }
}
