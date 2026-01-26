import 'package:hive_flutter/hive_flutter.dart';
import '../models/friend_model.dart';
import '../../../../core/services/hive_atomic_manager.dart';

class FriendService {
  static const String boxName = 'scannut_friends';

  Future<void> init() async {
    await HiveAtomicManager().ensureBoxOpen(boxName);
  }

  Future<void> saveFriend(FriendModel friend) async {
    final box = await HiveAtomicManager().ensureBoxOpen(boxName);
    await box.put(friend.id, friend.toJson());
  }

  Future<List<FriendModel>> getAllFriends() async {
    final box = await HiveAtomicManager().ensureBoxOpen(boxName);
    return box.values
        .map((e) => FriendModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> deleteFriend(String id) async {
    final box = await HiveAtomicManager().ensureBoxOpen(boxName);
    await box.delete(id);
  }
}
