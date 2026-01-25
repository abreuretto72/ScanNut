import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
import '../../nutrition/data/datasources/menu_filter_service.dart';
import '../../features/pet/services/pet_event_repository.dart';
import 'hive_atomic_manager.dart';

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
    await HiveAtomicManager().ensureBoxOpen(_authBoxName);
    logger.info('🔐 SimpleAuthService initialized');
  }

  /// Retorna a chave de criptografia baseada na sessão atual
  HiveCipher? get encryptionCipher {
    if (_encryptionKey == null) return null;
    return HiveAesCipher(_encryptionKey!);
  }

  Future<bool> checkPersistentSession() async {
    try {
      debugPrint('🔍 [SimpleAuthService] Checking persistent session...');
      final box = Hive.box(_authBoxName);
      final hasSession = box.get(_sessionKey) != null;
      final shouldPersist = box.get(_persistKey, defaultValue: false);

      debugPrint(
          '🔍 [SimpleAuthService] hasSession: $hasSession, shouldPersist: $shouldPersist');

      if (hasSession && shouldPersist) {
        // Tentar recuperar a chave do SecureStorage
        debugPrint(
            '🔍 [SimpleAuthService] Attempting to read master key from Secure Storage...');
        final keyString = await _storage.read(key: _encryptionKeyName);
        if (keyString != null) {
          debugPrint('🔍 [SimpleAuthService] Key found. Decoding...');
          _encryptionKey = base64Decode(keyString).toList();
          logger.info('🔑 Chave mestra recuperada do Secure Storage');

          // Inicializar dados seguros automaticamente
          await initializeSecureData();
          debugPrint('✅ [SimpleAuthService] Persistent session established.');
          return true;
        } else {
          debugPrint(
              '⚠️ [SimpleAuthService] Persist key was set but not found in Secure Storage.');
        }
      }
    } catch (e, stack) {
      debugPrint(
          '❌ [SimpleAuthService] CRITICAL error in checkPersistentSession: $e');
      debugPrint('Stacktrace: $stack');
    }
    return false;
  }

  bool get isUserLoggedIn {
    try {
      final box = Hive.box(_authBoxName);
      return box.get(_sessionKey) != null && _encryptionKey != null;
    } catch (e) {
      return false;
    }
  }

  /// Centraliza a inicialização de todos os serviços que usam criptografia
  Future<void> initializeSecureData() async {
    final cipher = encryptionCipher;
    if (cipher == null) {
      logger.error(
          '❌ Erro: Tentativa de inicializar dados sem chave de criptografia');
      return;
    }

    logger.info('📦 Inicializando todos os serviços com criptografia AES...');

    try {
      // Helper local para inicializar com log
      Future<void> initService(
          String name, Future<void> Function() initFn) async {
        try {
          debugPrint('🔧 Opening $name...');
          await initFn();
          debugPrint('✅ $name ready.');
        } catch (e, stack) {
          debugPrint('❌ FAILED to open $name: $e');
          debugPrint('Stacktrace: $stack');
          // Tentar recuperar se for erro de Hive
          if (e.toString().contains('HiveError')) {
            debugPrint(
                '⚠️ Critical Hive Error on $name. Attempting next service anyway to avoid total block.');
          }
          // We DON'T rethrow here for individual services during startup
          // so the app can at least open and show partially working state
        }
      }

      await initService(
          'HistoryService', () => HistoryService().init(cipher: cipher));
      await initService('MealHistoryService',
          () => MealHistoryService().init(cipher: cipher));
      await initService(
          'PetEventService', () => PetEventService().init(cipher: cipher));
      await initService('VaccineStatusService',
          () => VaccineStatusService().init(cipher: cipher));
      await initService(
          'PetProfileService', () => PetProfileService().init(cipher: cipher));
      await initService(
          'PetHealthService', () => PetHealthService().init(cipher: cipher));
      await initService(
          'MealPlanService', () => MealPlanService().init(cipher: cipher));
      await initService(
          'NutritionService', () => NutritionService().init(cipher: cipher));
      await initService(
          'BotanyService', () => BotanyService().init(cipher: cipher));
      await initService(
          'WorkoutService', () => WorkoutService().init(cipher: cipher));
      await initService('UserProfileService',
          () => UserProfileService().init(cipher: cipher));
      await initService('NutritionProfileService',
          () => NutritionProfileService().init(cipher: cipher));
      await initService(
          'WeeklyPlanService', () => WeeklyPlanService().init(cipher: cipher));
      await initService(
          'MealLogService', () => MealLogService().init(cipher: cipher));
      await initService('ShoppingListService',
          () => ShoppingListService().init(cipher: cipher));
      await initService(
          'PartnerService', () => PartnerService().init(cipher: cipher));
      await initService(
          'MenuFilterService', () => MenuFilterService().init(cipher: cipher));
      await initService('PetEventRepository',
          () => PetEventRepository().init(cipher: cipher));

      logger.info('🚀 Tentativa de abertura de todos os dados concluída.');
      debugPrint(
          '🏁 [SimpleAuthService] initializeSecureData FINISHED at ${DateTime.now().toIso8601String()}.');
    } catch (e, stack) {
      logger.error('❌ Erro geral ao inicializar serviços seguros', error: e);
      debugPrint('Stacktrace: $stack');
    }
  }

  String? get loggedUserEmail {
    try {
      final box = Hive.box(_authBoxName);
      return box.get(_sessionKey);
    } catch (e) {
      return null;
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> login(String email, String password,
      {bool rememberMe = false}) async {
    final box = Hive.box(_authBoxName);
    final users = box.get('users', defaultValue: <String, String>{}) as Map;

    final hashedPassword = _hashPassword(password);

    if (users.containsKey(email) && users[email] == hashedPassword) {
      // Gera a chave mestra de 32 bytes (256 bits) para o Hive
      final keyBytes = utf8.encode(email + password);
      _encryptionKey = sha256.convert(keyBytes).bytes;

      if (rememberMe || isBiometricEnabled) {
        // Salva a chave no Secure Storage para Auto-Login ou Biometria
        // V127: Força salvamento se Biometria estiver ativada, mesmo que rememberMe seja falso
        await _storage.write(
            key: _encryptionKeyName, value: base64Encode(_encryptionKey!));
        if (isBiometricEnabled) {
          logger.info(
              '🔒 [V127-AUTH] Biometrics is ON: Key persisted automatically.');
        }
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
    final users = Map<String, String>.from(
        box.get('users', defaultValue: <String, String>{}) as Map);

    if (users.containsKey(email)) {
      logger.warning('⚠️ Registration failed: User $email already exists');
      return false;
    }

    // 1. Persist new user in auth box
    users[email] = _hashPassword(password);
    await box.put('users', users);
    logger.info(
        '✅ [V113-AUTH] User $email registered successfully. Starting Auto-Login...');

    // 2. Perform Auto-Login (V113)
    // We default to rememberMe: true to ease the first-run experience
    return await login(email, password, rememberMe: true);
  }

  Future<void> logout() async {
    try {
      final box = Hive.box(_authBoxName);
      await box.delete(_sessionKey);
      await box.delete(_persistKey);
      await _storage.delete(key: _encryptionKeyName);
      _encryptionKey = null; // Limpa a chave da memória

      // 🛡️ [V170] CLOSE HIVE SECURELY
      // Fechamos todas as boxes e o motor para garantir integridade.
      await Hive.close();

      // Reinicializar para permitir operações básicas de Auth
      await Hive.initFlutter();
      await init();

      logger.info(
          '🚪 [V170] User logged out. Encryption key and boxes cleared safely.');
    } catch (e) {
      logger.error('⚠️ Error during logout: $e');
    }
  }

  Future<String?> changePassword(
      String email, String currentPassword, String newPassword) async {
    final box = Hive.box(_authBoxName);
    final users = box.get('users', defaultValue: <String, String>{}) as Map;
    final storedHash = users[email];

    // 1. Validate Current Password
    if (storedHash != _hashPassword(currentPassword)) {
      return 'Senha atual incorreta.';
    }

    // 2. Prepare Keys
    final oldKeyBytes = utf8.encode(email + currentPassword);
    final oldKey = sha256.convert(oldKeyBytes).bytes;
    final oldCipher = HiveAesCipher(oldKey);

    final newKeyBytes = utf8.encode(email + newPassword);
    final newKey = sha256.convert(newKeyBytes).bytes;
    final newCipher = HiveAesCipher(newKey);

    // 3. Re-encrypt Data
    // List of all secure boxes used in the app
    final boxesToRekey = [
      'nutrition_weekly_plans',
      'nutrition_shopping_list',
      'nutrition_user_profile',
      'nutrition_meal_logs',
      'box_nutrition_human',
      'box_plants_history',
      'vaccine_status',
      'pet_events',
      'weekly_meal_plans',
      'box_pets_master',
      'pet_health_records',
      'box_workouts',
      'scannut_history',
      'scannut_meal_history',
      'box_user_profile',
      'partners_box',
      'pet_events_journal'
    ];

    logger.info('🔄 Starting re-encryption for password change...');

    for (final boxName in boxesToRekey) {
      try {
        // Verify if box exists on disk to avoid creating empty ghosts
        if (await Hive.boxExists(boxName)) {
          // Close if open
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).close();
          }

          // Open with OLD Key to read data
          final oldBox =
              await Hive.openBox(boxName, encryptionCipher: oldCipher);

          // Copy data into memory
          final content = Map<dynamic, dynamic>.from(oldBox.toMap());
          await oldBox.close();

          // Delete old encrypted file
          await Hive.deleteBoxFromDisk(boxName);

          // Open with NEW Key and restore data
          final newBox =
              await Hive.openBox(boxName, encryptionCipher: newCipher);
          await newBox.putAll(content);
          await newBox.close();

          logger.info('   ✅ Rekeyed box: $boxName');
        }
      } catch (e) {
        logger.error('   ❌ Failed to rekey box $boxName: $e');
        // Continue to try to save as much as possible
      }
    }

    // 4. Update Auth Hash
    users[email] = _hashPassword(newPassword);
    await box.put('users', users);

    // 5. Update active session key
    _encryptionKey = newKey;

    // Update Secure Persistence if active
    final bool rememberMe = box.get(_persistKey, defaultValue: false);
    if (rememberMe) {
      await _storage.write(
          key: _encryptionKeyName, value: base64Encode(_encryptionKey!));
    }

    // 6. Re-initialize services with new key
    await initializeSecureData();

    logger.info('✅ Password changed successfully for $email');
    return null; // Null means success
  }

  bool getPersistSession() {
    final box = Hive.box(_authBoxName);
    return box.get(_persistKey, defaultValue: false);
  }

  // BIOMETRICS
  static const String _biometricEnabledKey = 'auth_biometric_enabled';
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool get isBiometricEnabled {
    final box = Hive.box(_authBoxName);
    return box.get(_biometricEnabledKey, defaultValue: false);
  }

  /// 🧬 V114: Verifica se o hardware suporta biometria e se já está ativa
  Future<bool> shouldPromptBiometricActivation() async {
    final available = await checkHardwareBiometrics();
    final alreadyEnabled = isBiometricEnabled;
    return available && !alreadyEnabled;
  }

  Future<bool> checkHardwareBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isSupported;
    } catch (e) {
      logger.error('Error checking hardware biometrics: $e');
      return false;
    }
  }

  Future<bool> checkBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      logger.error('Error checking biometrics: $e');
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final box = Hive.box(_authBoxName);
    await box.put(_biometricEnabledKey, enabled);
    logger.info('🧬 Biometric enabled: $enabled');

    // If enabling biometrics, ensure key is in secure storage (similar to persist session)
    if (enabled && _encryptionKey != null) {
      await _storage.write(
          key: _encryptionKeyName, value: base64Encode(_encryptionKey!));
      logger.info('🔒 Biometric active: Key forced into SecureStorage.');
    } else if (enabled && _encryptionKey == null) {
      // Se tentar ativar sem estar logado ou sem chave na memória, isso é um erro lógico
      // mas não podemos recuperar a senha do nada. O usuário terá que logar de novo para salvar a chave.
      final hasKey = await _storage.containsKey(key: _encryptionKeyName);
      if (!hasKey) {
        logger.warning(
            '⚠️ Ativando biometria mas sem chave mestre. Usuário precisará relogar.');
      }
    }

    // If disabling, run setPersistSession logic to clean up if needed
    if (!enabled && !getPersistSession()) {
      await _storage.delete(key: _encryptionKeyName);
      logger
          .info('🔓 Biometric inactive & Session not persistent: Key removed.');
    }
  }

  Future<void> setPersistSession(bool persist) async {
    final box = Hive.box(_authBoxName);
    await box.put(_persistKey, persist);

    if (persist) {
      // Create and store key if we have one in memory
      if (_encryptionKey != null) {
        await _storage.write(
            key: _encryptionKeyName, value: base64Encode(_encryptionKey!));
        logger.info('🔒 Persistent session ACTIVE. Key stored securely.');
      }
    } else {
      // Only delete if biometrics is ALSO disabled
      if (!isBiometricEnabled) {
        await _storage.delete(key: _encryptionKeyName);
        logger
            .info('🔓 Persistent session INACTIVE. Key removed from storage.');
      } else {
        logger.info(
            '⚠️ Persistent session INACTIVE, but Key kept for Biometrics.');
      }
    }
  }

  Future<bool> hasStoredCredentials() async {
    return await _storage.containsKey(key: _encryptionKeyName);
  }

  bool _isAuthenticating = false;

  Future<AuthResult> authenticateWithBiometrics() async {
    if (_isAuthenticating) return AuthResult.unavailable;
    _isAuthenticating = true;

    try {
      final available = await checkBiometricsAvailable();
      if (!available) {
        _isAuthenticating = false;
        return AuthResult.unavailable;
      }

      // V128: Pre-Check for Key
      if (!await hasStoredCredentials()) {
        logger.warning('⚠️ [V128-BIO] No key stored. Cannot authenticate.');
        _isAuthenticating = false;
        return AuthResult.missingKey;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Toque no sensor para entrar no ScanNut',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        debugPrint('✅ [V128-BIO] OS Authentication Succeeded (Handshake).');

        // Retrieve key purely from storage
        final keyString = await _storage.read(key: _encryptionKeyName);
        if (keyString != null) {
          _encryptionKey = base64Decode(keyString).toList();

          // 🚀 V126: RESTORE SESSION STATE
          final box = Hive.box(_authBoxName);
          if (box.get(_sessionKey) == null) {
            await box.put(_sessionKey, "biometric_user@scannut.app");
            debugPrint('⚠️ [V128-BIO] Session resurrected via Biometrics.');
          }

          await initializeSecureData();
          debugPrint(
              '🚀 [V128-BIO] Secure Data Initialized. Returning SUCCESS.');
          _isAuthenticating = false;
          return AuthResult.success;
        } else {
          debugPrint('❌ [V128-BIO] Auth OK but No Key in Storage explicity.');
          _isAuthenticating = false;
          return AuthResult.missingKey;
        }
      }
      _isAuthenticating = false;
      return AuthResult.failed;
    } catch (e) {
      logger.error('Error in bio auth: $e');
      _isAuthenticating = false;
      return AuthResult.failed;
    }
  }

  /// 🛡️ V_SEC: Verify User Identity for sensitive actions (Danger Zone)
  Future<bool> verifyIdentity(
      {String reason = 'Confirme sua identidade para continuar'}) async {
    try {
      final available = await checkBiometricsAvailable();
      if (!available) {
        // If no biometrics/device security, we might want to fail secure or allow.
        // For "Danger Zone", it implies the user OWNS the device.
        // If the device has NO security, we can't verify. Return true or warning?
        // Let's return true but log warning, as we can't lock user out if they don't use phone security.
        logger.warning('⚠️ No security hardware available for verification.');
        return true;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
          biometricOnly: false, // Allow PIN/Pattern
        ),
      );
    } catch (e) {
      logger.error('Error verifying identity: $e');
      return false;
    }
  }

  static Future<AuthResult> authenticate() async {
    return await _instance.authenticateWithBiometrics();
  }
}

enum AuthResult { success, failed, missingKey, unavailable }

final simpleAuthService = SimpleAuthService();
