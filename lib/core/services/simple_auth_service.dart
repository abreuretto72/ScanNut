import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../utils/app_logger.dart';

// Import all services that need secure initialization
import '../services/history_service.dart';
import '../services/meal_history_service.dart';
import '../services/user_profile_service.dart';
import '../../features/pet/services/pet_event_service.dart';
import '../../features/pet/services/vaccine_status_service.dart';
import '../../features/pet/services/pet_profile_service.dart';
import '../../features/pet/services/pet_health_service.dart';
import '../../features/pet/services/meal_plan_service.dart';
import '../../features/food/services/nutrition_service.dart';
import '../../features/plant/services/botany_service.dart';
import '../../features/food/services/workout_service.dart';
import '../../nutrition/data/datasources/nutrition_profile_service.dart';
import '../../nutrition/data/datasources/weekly_plan_service.dart';
import '../../nutrition/data/datasources/meal_log_service.dart';
import '../../nutrition/data/datasources/shopping_list_service.dart';
import '../services/partner_service.dart';

class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  static const String _authBoxName = 'box_auth_local';
  static const String _sessionKey = 'active_session';
  static const String _persistKey = 'persist_session';
  static const String _encryptionKeyName = 'master_encryption_key';
  
  final _storage = const FlutterSecureStorage();
  List<int>? _encryptionKey;

  Future<void> init() async {
    await Hive.openBox(_authBoxName);
    logger.info('🔐 SimpleAuthService initialized');
  }

  /// Retorna a chave de criptografia baseada na sessão atual
  HiveCipher? get encryptionCipher {
    if (_encryptionKey == null) return null;
    return HiveAesCipher(_encryptionKey!);
  }

  Future<bool> checkPersistentSession() async {
    final box = Hive.box(_authBoxName);
    final hasSession = box.get(_sessionKey) != null;
    final shouldPersist = box.get(_persistKey, defaultValue: false);
    
    if (hasSession && shouldPersist) {
      // Tentar recuperar a chave do SecureStorage
      final keyString = await _storage.read(key: _encryptionKeyName);
      if (keyString != null) {
        _encryptionKey = base64Decode(keyString).toList();
        logger.info('🔑 Chave mestra recuperada do Secure Storage');
        
        // Inicializar dados seguros automaticamente
        await initializeSecureData();
        return true;
      }
    }
    return false;
  }

  bool get isUserLoggedIn {
    final box = Hive.box(_authBoxName);
    return box.get(_sessionKey) != null && _encryptionKey != null;
  }

  /// Centraliza a inicialização de todos os serviços que usam criptografia
  Future<void> initializeSecureData() async {
    final cipher = encryptionCipher;
    if (cipher == null) {
      logger.error('❌ Erro: Tentativa de inicializar dados sem chave de criptografia');
      return;
    }

    logger.info('📦 Inicializando todos os serviços com criptografia AES...');
    
    try {
      // Passar o cipher para todos os serviços (precisaremos atualizar seus init())
      await HistoryService().init(cipher: cipher);
      await MealHistoryService().init(cipher: cipher);
      await PetEventService().init(cipher: cipher);
      await VaccineStatusService().init(cipher: cipher);
      await PetProfileService().init(cipher: cipher);
      await PetHealthService().init(cipher: cipher);
      await MealPlanService().init(cipher: cipher);
      await NutritionService().init(cipher: cipher);
      await BotanyService().init(cipher: cipher);
      await WorkoutService().init(cipher: cipher);
      await UserProfileService().init(cipher: cipher);
      await NutritionProfileService().init(cipher: cipher);
      await WeeklyPlanService().init(cipher: cipher);
      await MealLogService().init(cipher: cipher);
      await ShoppingListService().init(cipher: cipher);
      await PartnerService().init(cipher: cipher);
      
      logger.info('🚀 Todos os dados abertos com sucesso!');
    } catch (e) {
      logger.error('❌ Erro crítico ao abrir dados criptografados', error: e);
      rethrow;
    }
  }

  String? get loggedUserEmail {
    final box = Hive.box(_authBoxName);
    return box.get(_sessionKey);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    final box = Hive.box(_authBoxName);
    final users = box.get('users', defaultValue: <String, String>{}) as Map;
    
    final hashedPassword = _hashPassword(password);
    
    if (users.containsKey(email) && users[email] == hashedPassword) {
      // Gera a chave mestra de 32 bytes (256 bits) para o Hive
      final keyBytes = utf8.encode(email + password);
      _encryptionKey = sha256.convert(keyBytes).bytes;
      
      if (rememberMe) {
        // Salva a chave no Secure Storage se o usuário quiser persistir
        await _storage.write(key: _encryptionKeyName, value: base64Encode(_encryptionKey!));
      }

      await box.put(_sessionKey, email);
      await box.put(_persistKey, rememberMe);
      
      // Inicializar dados antes de retornar sucesso
      await initializeSecureData();
      
      logger.info('✅ User $email logged in. Master Key derived and stored.');
      return true;
    }
    
    logger.warning('❌ Login failed for $email');
    return false;
  }

  Future<bool> register(String email, String password) async {
    final box = Hive.box(_authBoxName);
    final users = Map<String, String>.from(box.get('users', defaultValue: <String, String>{}) as Map);
    
    if (users.containsKey(email)) {
      logger.warning('⚠️ Registration failed: User $email already exists');
      return false;
    }
    
    users[email] = _hashPassword(password);
    await box.put('users', users);
    logger.info('✅ User $email registered successfully (hashed)');
    return true;
  }

  Future<void> logout() async {
    final box = Hive.box(_authBoxName);
    await box.delete(_sessionKey);
    await box.delete(_persistKey);
    await _storage.delete(key: _encryptionKeyName);
    _encryptionKey = null; // Limpa a chave da memória
    
    // Opcionalmente: Fechar todas as boxes abertas
    await Hive.close();
    await Hive.initFlutter(); // Re-inicializar para permitir abrir a auth box de novo
    await init();
    
    logger.info('🚪 User logged out. Encryption key and boxes cleared.');
  }
}

final simpleAuthService = SimpleAuthService();
