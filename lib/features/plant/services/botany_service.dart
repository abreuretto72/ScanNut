// ═══════════════════════════════════════════════════════════════════════════════
// 🚫 MÓDULO BLINDADO E CONGELADO - NÃO ALTERAR SEM AUTORIZAÇÃO EXPLÍCITA
// Data de Congelamento: 29/12/2025
// Este serviço gerencia a persistência e histórico de análises botânicas.
// Alterações podem causar perda de dados ou inconsistências no histórico.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/botany_history_item.dart';
import '../models/plant_analysis_model.dart';
import '../../../core/services/file_upload_service.dart';

class BotanyService {
  static final BotanyService _instance = BotanyService._internal();
  factory BotanyService() => _instance;
  BotanyService._internal();

  static const String boxName = 'box_botany_intel';
  Box<BotanyHistoryItem>? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    try {
      if (!Hive.isAdapterRegistered(21)) {
        Hive.registerAdapter(BotanyHistoryItemAdapter());
      }
      _box = await Hive.openBox<BotanyHistoryItem>(boxName);
      debugPrint('✅ BotanyService initialized.');
    } catch (e) {
      debugPrint('❌ Error initializing BotanyService: $e');
    }
  }

  ValueListenable<Box<BotanyHistoryItem>>? get listenable => _box?.listenable();

  Future<void> savePlantAnalysis(PlantAnalysisModel analysis, File? image) async {
    await init();
    if (_box == null) return;

    String? savedPath;
    if (image != null) {
      savedPath = await FileUploadService().saveAnalysisImage(
        file: image,
        type: 'plant',
        name: analysis.identificacao.nomeCientifico,
      );
    }

    // Determine toxicity status from analysis keywords
    String tox = 'safe';
    final toxInfo = analysis.segurancaBiofilia.segurancaDomestica.toString().toLowerCase();
    if (toxInfo.contains('toxic') || toxInfo.contains('tóxica') || toxInfo.contains('perigo')) {
      tox = 'toxic';
    } else if (toxInfo.contains('pet') || toxInfo.contains('cachorro') || toxInfo.contains('gato')) {
      tox = 'harmful_pets';
    }

    // Determine survival semaphore
    String semaphore = 'verde';
    if (analysis.saude.condicao.toLowerCase().contains('crítico') || analysis.saude.urgencia.toLowerCase() == 'high') {
      semaphore = 'vermelho';
    } else if (analysis.saude.condicao.toLowerCase().contains('atenção') || analysis.saude.urgencia.toLowerCase() == 'medium') {
      semaphore = 'amarelo';
    }

    final item = BotanyHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      plantName: analysis.identificacao.nomesPopulares.isNotEmpty 
          ? analysis.identificacao.nomesPopulares.first 
          : analysis.identificacao.nomeCientifico,
      healthStatus: analysis.saude.condicao,
      diseaseDiagnosis: analysis.saude.detalhes != 'N/A' ? analysis.saude.detalhes : null,
      recoveryPlan: analysis.saude.planoRecuperacao,
      survivalSemaphore: semaphore,
      lightWaterSoilNeeds: {
        'luz': analysis.sobrevivencia.luminosidade['ideal']?.toString() ?? 'N/A',
        'agua': analysis.sobrevivencia.regimeHidrico['frequencia']?.toString() ?? 'N/A',
        'solo': analysis.sobrevivencia.soloENutricao['tipo_solo']?.toString() ?? 'N/A',
      },
      fengShuiTips: analysis.lifestyle.simbolismo,
      imagePath: savedPath,
      toxicityStatus: tox,
      rawMetadata: analysis.toJson(),
    );

    await _box!.add(item);
  }

  Future<List<BotanyHistoryItem>> getHistory() async {
    await init();
    return _box?.values.toList().reversed.toList() ?? [];
  }

  /// Quick check for toxicity alerts
  Future<List<BotanyHistoryItem>> getToxicPlants() async {
    await init();
    return _box?.values.where((p) => p.toxicityStatus != 'safe').toList() ?? [];
  }
}
