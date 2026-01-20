import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'hive_atomic_manager.dart';

import '../../features/pet/services/pet_profile_service.dart';
import '../../features/pet/services/pet_event_service.dart';
import '../../features/plant/services/botany_service.dart';
import '../../features/food/services/nutrition_service.dart';

import '../../features/pet/models/pet_event.dart';
import '../../features/plant/models/botany_history_item.dart';
import '../../features/food/models/nutrition_history_item.dart';
import 'simple_auth_service.dart';

class DataSeedService {
  static final DataSeedService _instance = DataSeedService._internal();
  factory DataSeedService() => _instance;
  DataSeedService._internal();

  final _random = Random();

  int _sequence = 0;
  String _uniqueId(String prefix) {
      _sequence++;
      // Return a string that is guaranteed unique within this batch
      return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$_sequence';
  }

  Future<void> seedAll() async {
    try {
      debugPrint('🌱 Starting Data Seeding (V52)...');
      _sequence = 0;
      
      // 1. Create Dummy Files
      await _seedPhysicalFiles();

      // 2. Seed Pets
      await _seedPets();

      // 3. Seed Botany
      await _seedBotany();

      // 4. Seed Nutrition
      await _seedNutrition();
      
      // 5. Seed Events
      await _seedEvents();

      debugPrint('✅ Data Seeding Completed!');
    } catch (e, stack) {
      debugPrint('❌ Seeding Failed: $e');
      debugPrint(stack.toString());
    }
  }

  // --- 1. PHYSICAL FILES ---
  Future<void> _seedPhysicalFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    final folders = ['PetPhotos', 'PlantAnalyses', 'ExamsVault', 'media_vault/Pets', 'media_vault/Botany'];
    
    for (var folder in folders) {
      final dir = Directory('${appDir.path}/$folder');
      if (!await dir.exists()) await dir.create(recursive: true);
      
      // Create 3 dummy files per folder
      for (var i = 1; i <= 3; i++) {
        final file = File('${dir.path}/dummy_seed_${_uniqueId("file")}.jpg');
        await file.writeAsString('DUMMY CONTENT FOR TESTING');
      }
    }
    debugPrint('📁 Dummy physical files created.');
  }

  // --- 2. PETS ---
  Future<void> _seedPets() async {
    final service = PetProfileService();
    await service.init();
    
    // (1) PROTOCOLO DE ABERTURA FORÇADA
    await HiveAtomicManager().ensureBoxOpen('box_pets_master', cipher: SimpleAuthService().encryptionCipher);

    // Thor & Luna
    final pets = [
      {'name': 'Thor', 'species': 'Canina', 'breed': 'Golden Retriever', 'sex': 'Macho', 'fixedId': '001'},
      {'name': 'Luna', 'species': 'Felina', 'breed': 'Siames', 'sex': 'Fêmea', 'fixedId': '002'},
    ];

    for (var p in pets) {
      final data = {
        'id': p['fixedId'], // (2) ID Fixo
        'name': p['name'],
        'species': p['species'],
        'breed': p['breed'],
        'sex': p['sex'],
        'birthDate': DateTime.now().subtract(const Duration(days: 365 * 3)).toIso8601String(),
        'image_path': null,
      };
      
      await service.saveOrUpdateProfile(p['name']!, data);
    }
    
    // (2) NOTIFICAÇÃO INTERNA
    debugPrint('[DEBUG] Seed: Pets gravados com sucesso.');
  }

  // --- 3. BOTANY ---
  Future<void> _seedBotany() async {
    final service = BotanyService();
    await service.init(cipher: SimpleAuthService().encryptionCipher);
    final box = await HiveAtomicManager().ensureBoxOpen<BotanyHistoryItem>(BotanyService.boxName, cipher: SimpleAuthService().encryptionCipher);
    
    for (var i = 0; i < 5; i++) {
       final isSafe = _random.nextBool();
       
       final item = BotanyHistoryItem(
          id: _uniqueId('botany'),
          timestamp: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
          plantName: isSafe ? 'Samambaia Fictícia $i' : 'Comigo-Ninguém-Pode Teste $i',
          healthStatus: isSafe ? 'Saudável' : 'Doente',
          recoveryPlan: 'Regar mais e colocar no sol.',
          survivalSemaphore: isSafe ? 'verde' : 'vermelho',
          lightWaterSoilNeeds: {'luz': 'Média', 'agua': 'Alta', 'solo': 'Rico'},
          fengShuiTips: 'Boa sorte no teste.',
          toxicityStatus: isSafe ? 'safe' : 'toxic',
          locale: 'pt_BR',
       );
       await box.add(item);
    }
    debugPrint('🌿 Botany history seeded.');
  }

  // --- 4. NUTRITION ---
  Future<void> _seedNutrition() async {
    final service = NutritionService();
    await service.init(cipher: SimpleAuthService().encryptionCipher);
    final box = await HiveAtomicManager().ensureBoxOpen<NutritionHistoryItem>(NutritionService.boxName, cipher: SimpleAuthService().encryptionCipher);
    
    for (var i = 0; i < 5; i++) {
       final item = NutritionHistoryItem(
          id: _uniqueId('food'),
          timestamp: DateTime.now().subtract(Duration(days: _random.nextInt(10))),
          foodName: 'Prato Teste #$i',
          calories: (500 + _random.nextDouble() * 200).toInt(),
          proteins: '20g',
          carbs: '50g',
          fats: '15g',
          isUltraprocessed: i % 3 == 0,
          biohackingTips: ['Comer antes do treino'],
          recipesList: [],
       );
       await box.add(item);
    }
    debugPrint('🍎 Nutrition history seeded.');
  }

  // --- 5. EVENTS ---
  Future<void> _seedEvents() async {
    final service = PetEventService();
    await service.init(cipher: SimpleAuthService().encryptionCipher);
    
    // (1) PROTOCOLO DE ABERTURA FORÇADA
    await HiveAtomicManager().ensureBoxOpen('pet_events', cipher: SimpleAuthService().encryptionCipher);
    
    final types = EventType.values;
    final petNames = ['Thor', 'Luna'];
    
    // 5 Events in CURRENT MONTH (Jan 2026)
    // Using current date 2026-01-09 as ref, let's span the month.
    for (var i = 1; i <= 5; i++) {
       final date = DateTime(2026, 1, i + 2, 9 + i, 0); // Jan 3, 4, 5, 6, 7
       final type = types[i % types.length];
       final pet = petNames[i % petNames.length];
       final completed = i % 2 == 0;
       
       await _createEvent(service, pet, type, date, completed);
    }
    
    // 10 Events in 2025 (Retro)
    for (var i = 1; i <= 10; i++) {
       final month = _random.nextInt(12) + 1;
       final day = _random.nextInt(28) + 1;
       final date = DateTime(2025, month, day, 10, 00);
       final type = types[i % types.length];
       final pet = petNames[i % petNames.length];
       
       await _createEvent(service, pet, type, date, true); // Past events completed
    }
    
    debugPrint('📅 Events seeded (Current & Retro).');
  }
  
  Future<void> _createEvent(PetEventService service, String petName, EventType type, DateTime date, bool completed) async {
       final event = PetEvent(
          id: _uniqueId('evt'),
          petId: petName,
          petName: petName,
          title: 'Teste V52: ${type.toString().split('.').last}',
          type: type,
          dateTime: date,
          notes: 'Gerado automaticamente (Massa de Teste)',
          completed: completed,
       );
       await service.addEvent(event);
  }

  // --- DATE GENERATOR (Legacy, unused now but kept if needed helper) ---
  DateTime _getRandomDate() {
    return DateTime.now().subtract(Duration(days: _random.nextInt(90)));
  }
}
