import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

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
      _box = await Hive.openBox<UserProfile>(boxName, encryptionCipher: cipher);
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
