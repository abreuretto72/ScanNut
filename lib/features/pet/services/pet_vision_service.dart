import 'dart:io';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/enums/scannut_mode.dart';

class PetVisionService {
  final GeminiService _geminiService;

  PetVisionService({GeminiService? geminiService}) 
      : _geminiService = geminiService ?? GeminiService();

  /// Processa a análise da foto do pet (Espécie, Raça, Linhagem)
  /// Retorna um Map com os dados brutos da análise
  Future<Map<String, dynamic>> analisarFotoPet(File imageFile, String locale, {String? knownSpecies, String? knownBreed, ScannutMode mode = ScannutMode.petIdentification}) async {
    try {
      
      Map<String, String>? contextData;
      if (knownSpecies != null || knownBreed != null) {
          contextData = {
              'species': knownSpecies ?? 'Unknown',
              'breed': knownBreed ?? 'Unknown'
          };
      }

      final result = await _geminiService.analyzeImage(
        imageFile: imageFile, 
        mode: mode, // 🛡️ V139: Dynamic Mode (Diagnosis vs Identification)
        locale: locale,
        contextData: contextData,
      );

      // 🛡️ SHIELDING: Enforce Source of Truth
      final mutableResult = Map<String, dynamic>.from(result);
      
      // Phase 4: Debug Logging of restricted fields
      if (knownSpecies != null || knownBreed != null) {
          final aiSpecies = result['species'] ?? result['identification']?['species'];
          final aiBreed = result['breed'] ?? result['identification']?['breed'];
          
          if (aiSpecies != null && aiSpecies.toString().toLowerCase() != 'n/a') {
              // ignore: avoid_print
              print('🛡️ DEBUG: [SOURCE OF TRUTH BREACH] AI attempted to return species: $aiSpecies');
          }
          if (aiBreed != null && aiBreed.toString().toLowerCase() != 'n/a') {
              // ignore: avoid_print
              print('🛡️ DEBUG: [SOURCE OF TRUTH BREACH] AI attempted to return breed: $aiBreed');
          }
      }

      if (knownSpecies != null) mutableResult['species'] = knownSpecies;
      if (knownBreed != null) mutableResult['breed'] = knownBreed;
      
      // Also clean nested identification if exists
      if (mutableResult.containsKey('identification') && mutableResult['identification'] is Map) {
          if (knownSpecies != null) mutableResult['identification']['species'] = knownSpecies;
          if (knownBreed != null) mutableResult['identification']['breed'] = knownBreed;
      }
      
      return mutableResult;
    } catch (e) {
      // Aqui poderíamos ter log de erro específico
      rethrow;
    }
  }

  /// Método para processar OCR de exames ou documentos
  Future<String> realizarOCR(File documentFile) async {
    // Implementação futura ou delegação para LabExamService se necessário.
    // Atualmente retorna vazio conforme refatoração inicial.
    return "";
  }
}
