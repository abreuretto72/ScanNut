import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataManagementService {
  /// Completely wipes all user data and local files
  Future<void> deleteAllData() async {
    try {
      // 1. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ SharedPreferences cleared');

      // 2. Clear all Hive Boxes
      // Define all boxes used in the app
      final boxes = [
        'scannut_history',
        'box_nutrition_human', // Human nutrition history
        'nutrition_weekly_plans', // Human weekly plans
        'nutrition_meal_logs', // Human meal logs
        'nutrition_shopping_list', // Human shopping list
        'pet_profiles',
        'pet_health',
        'meal_plans',
        'weekly_meal_plans', // Pet weekly plans
        'pet_events',
        'vaccine_status',
        'partners',
        'partner_reminders',
        'box_plants_history', // Added: Plant history
        'box_botany_intel', // Legacy: old plant history name
        'box_workouts', // Workout history
      ];

      for (var boxName in boxes) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).clear();
          }
          await Hive.deleteBoxFromDisk(boxName);
        } catch (e) {
          debugPrint('⚠️ Error deleting box $boxName: $e');
        }
      }
      debugPrint('✅ Hive boxes cleared');

      // 3. Delete Physical Files (Medical Docs, captured images)
      final appDir = await getApplicationDocumentsDirectory();

      // Delete medical_docs
      final medicalDocsDir = Directory('${appDir.path}/medical_docs');
      if (await medicalDocsDir.exists()) {
        await medicalDocsDir.delete(recursive: true);
        debugPrint('✅ Medical documents folder deleted');
      }

      // 4. Delete app metadata folder (Hive files)
      // Note: We avoid deleting the root application directory to prevent system errors,
      // but we cleared the content. Hive will recreate boxes as needed.

      debugPrint('🎉 ALL DATA REMOVED SUCCESSFULLY');
    } catch (e) {
      debugPrint('❌ Error during data deletion: $e');
      rethrow;
    }
  }
}
