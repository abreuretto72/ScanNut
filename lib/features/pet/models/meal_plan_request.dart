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
      case PetDietType.general: return l10n.petDietGeneral ?? 'Geral';
      case PetDietType.renal: return l10n.dietRenal;
      case PetDietType.hepatic: return l10n.dietHepatic;
      case PetDietType.gastrointestinal: return l10n.dietGastrointestinal;
      case PetDietType.hypoallergenic: return l10n.dietHypoallergenic;
      case PetDietType.obesity: return l10n.dietObesity;
      case PetDietType.diabetes: return l10n.dietDiabetes;
      case PetDietType.cardiac: return l10n.dietCardiac;
      case PetDietType.urinary: return l10n.dietUrinary;
      case PetDietType.muscle_gain: return l10n.dietMuscleGain;
      case PetDietType.pediatric: return l10n.dietPediatric;
      case PetDietType.growth: return l10n.dietGrowth;
      case PetDietType.other: return l10n.dietOther;
    }
  }
}

class MealPlanRequest {
  final String petId;
  final String mode; // weekly, monthly, custom
  final DateTime startDate;
  final DateTime endDate;
  final PetDietType dietType;
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
    'otherNote': otherNote,
    'locale': locale,
    // Note: profileData is already a map
  };

  void validateOrThrow() {
    if (petId.trim().isEmpty) throw ArgumentError('petId obrigatório');
    if (profileData.isEmpty) throw ArgumentError('profileData obrigatório');
    if (!['weekly', 'monthly', 'custom'].contains(mode)) throw ArgumentError('mode inválido');
    
    final days = endDate.difference(startDate).inDays;
    if (days < 0) throw ArgumentError('Data final deve ser após a inicial');
    if (mode == 'custom' && days > 60) throw ArgumentError('Limite máximo de 60 dias para modo personalizado');
    
    if (dietType == PetDietType.other && (otherNote == null || otherNote!.trim().isEmpty)) {
      throw ArgumentError('Nota obrigatória para dieta do tipo "Outra"');
    }
  }
}
