import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import 'hive_atomic_manager.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  static const String boxName = 'box_user_profile';
  Box<UserProfile>? _box;

  Future<void> init({HiveCipher? cipher}) async {
    if (_box != null && _box!.isOpen) return;
    try {
      if (!Hive.isAdapterRegistered(23)) {
        Hive.registerAdapter(UserProfileAdapter());
      }
      _box = await HiveAtomicManager()
          .ensureBoxOpen<UserProfile>(boxName, cipher: cipher);
      debugPrint('✅ UserProfileService initialized (Secure).');
    } catch (e) {
      debugPrint('❌ Error initializing Secure UserProfileService: $e');
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await init();
    await _box?.put('current_user', profile);
  }

  Future<UserProfile?> getProfile() async {
    await init();
    return _box?.get('current_user');
  }
}
