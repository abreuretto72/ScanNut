
class MenuCreationParams {
  final int mealsPerDay;
  final String style; // simples, economico, rapido, saudavel
  final List<String> restrictions;
  final bool allowRepetition;

  MenuCreationParams({
    this.mealsPerDay = 4,
    this.style = 'simples',
    this.restrictions = const [],
    this.allowRepetition = true,
  });

  MenuCreationParams copyWith({
    int? mealsPerDay,
    String? style,
    List<String>? restrictions,
    bool? allowRepetition,
  }) {
    return MenuCreationParams(
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      style: style ?? this.style,
      restrictions: restrictions ?? this.restrictions,
      allowRepetition: allowRepetition ?? this.allowRepetition,
    );
  }
}
