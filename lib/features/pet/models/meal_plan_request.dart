import '../../../l10n/app_localizations.dart';

enum PetDietType {
  general,
  renal,
  hepatic,
  gastrointestinal,
  hypoallergenic,
  obesity,
  diabetes,
  cardiac,
  urinary,
  muscle_gain,
  pediatric,
  growth,
  other,
}

extension PetDietTypeX on PetDietType {
  String get id => name;

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case PetDietType.general:
        return l10n.petDietGeneral ?? 'Geral';
      case PetDietType.renal:
        return l10n.dietRenal;
      case PetDietType.hepatic:
        return l10n.dietHepatic;
      case PetDietType.gastrointestinal:
        return l10n.dietGastrointestinal;
      case PetDietType.hypoallergenic:
        return l10n.dietHypoallergenic;
      case PetDietType.obesity:
        return l10n.dietObesity;
      case PetDietType.diabetes:
        return l10n.dietDiabetes;
      case PetDietType.cardiac:
        return l10n.dietCardiac;
      case PetDietType.urinary:
        return l10n.dietUrinary;
      case PetDietType.muscle_gain:
        return l10n.dietMuscleGain;
      case PetDietType.pediatric:
        return l10n.dietPediatric;
      case PetDietType.growth:
        return l10n.dietGrowth;
      case PetDietType.other:
        return l10n.dietOther;
    }
  }
}

enum PetFoodType { kibble, natural, mixed }

extension PetFoodTypeX on PetFoodType {
  String get id => name;
  String localizedLabel(AppLocalizations l10n) {
    if (this == PetFoodType.kibble) return 'Ração Seca/Úmida';
    if (this == PetFoodType.natural) return 'Alimentação Natural';
    return 'Mista (Ração + Natural)';
  }
}

class MealPlanRequest {
  final String petId;
  final String mode; // weekly, monthly, custom
  final DateTime startDate;
  final DateTime endDate;
  final PetDietType dietType;
  final PetFoodType foodType; // New: Kibble vs Natural
  final String? otherNote;
  final String locale;
  final String source; // Safety restriction source
  final Map<String, dynamic> profileData;

  const MealPlanRequest({
    required this.petId,
    required this.mode,
    required this.startDate,
    required this.endDate,
    required this.dietType,
    this.foodType = PetFoodType.mixed, // Default
    required this.locale,
    required this.profileData,
    this.source = 'Unknown',
    this.otherNote,
  });

  Map<String, dynamic> toJson() => {
        'petId': petId,
        'mode': mode,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'dietType': dietType.id,
        'foodType': foodType.id,
        'otherNote': otherNote,
        'locale': locale,
        // Note: profileData is already a map
      };

  void validateOrThrow() {
    if (petId.trim().isEmpty) throw ArgumentError('petId obrigatório');
    if (profileData.isEmpty) throw ArgumentError('profileData obrigatório');

    // 🛡️ mandatory Fields (Source: PetProfile DB)
    final species = profileData['especie'] ?? profileData['species'];
    final breed = profileData['raca'] ?? profileData['breed'];
    final age = profileData['idade_exata'] ?? profileData['age'];
    final weight = profileData['peso_atual'] ?? profileData['weight'];
    final size = profileData['porte'] ?? profileData['size'];

    if (species == null || species.toString().isEmpty) {
      throw ArgumentError('Espécie obrigatória');
    }
    if (breed == null || breed.toString().isEmpty) {
      throw ArgumentError('Raça obrigatória');
    }
    if (age == null || age.toString().isEmpty) {
      throw ArgumentError('Idade obrigatória');
    }
    if (weight == null ||
        weight.toString() == '0.0' ||
        weight.toString().isEmpty) {
      throw ArgumentError('Peso obrigatório');
    }
    if (size == null || size.toString().isEmpty) {
      throw ArgumentError('Porte/Tamanho obrigatório');
    }

    if (!['weekly', 'monthly', 'custom'].contains(mode)) {
      throw ArgumentError('mode inválido');
    }

    final days = endDate.difference(startDate).inDays + 1;
    if (days <= 0) throw ArgumentError('Data final deve ser após a inicial');

    // Strict rules for modes
    if (mode == 'weekly' && days != 7) {
      throw ArgumentError('Modo semanal requer exatamente 7 dias');
    }
    if (mode == 'monthly' && days != 28) {
      throw ArgumentError('Modo mensal requer exatamente 28 dias');
    }
    if (mode == 'custom' && days > 60) {
      throw ArgumentError('Limite máximo de 60 dias para modo personalizado');
    }

    if (dietType == PetDietType.other &&
        (otherNote == null || otherNote!.trim().isEmpty)) {
      throw ArgumentError('Nota obrigatória para dieta do tipo "Outra"');
    }
  }
}
