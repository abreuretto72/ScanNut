import 'dart:io';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/enums/scannut_mode.dart';

class PetVisionService {
  final GeminiService _geminiService;

  PetVisionService({GeminiService? geminiService}) 
      : _geminiService = geminiService ?? GeminiService();

  /// Processa a análise da foto do pet (Espécie, Raça, Linhagem)
  /// Retorna um Map com os dados brutos da análise
  Future<Map<String, dynamic>> analisarFotoPet(File imageFile, String locale, {String? knownSpecies, String? knownBreed}) async {
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
        mode: ScannutMode.petIdentification, // Note: This might need to be dynamic depending on what we are doing, but for now we follow existing logic.
        // Wait, if we are diagnosing, we should use petDiagnosis? 
        // The original code used ScannutMode.petIdentification for everything? 
        // Let's check edit_pet_form.dart usage. It seems so.
        // Actually, if we are doing diagnosis, edit_pet_form usually calls specific methods.
        // But let's stick to the signature change first.
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
