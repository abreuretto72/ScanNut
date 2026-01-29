import '../l10n/app_localizations.dart';

class FoodPdfLabels {
  final String title;
  final String date;
  final String nutrientsTable;
  final String qty;
  final String dailyGoal;
  final String calories;
  final String proteins;
  final String carbs;
  final String fats;
  final String healthRating;
  final String clinicalRec;
  final String disclaimer;
  final String recipesTitle;
  final String justificationLabel;
  final String difficultyLabel;
  final String instructionsLabel;
  final FoodLocalizations? strings; // Optional if not always passed, but useful for footer

  const FoodPdfLabels({
    required this.title,
    required this.date,
    required this.nutrientsTable,
    required this.qty,
    required this.dailyGoal,
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.healthRating,
    required this.clinicalRec,
    required this.disclaimer,
    required this.recipesTitle,
    required this.justificationLabel,
    required this.difficultyLabel,
    required this.instructionsLabel,
    this.strings,
  });

  // Getter to provide a locale, defaulting to 'pt_BR' if strings absent
  String get locale => strings?.localeName ?? 'pt_BR';
}
