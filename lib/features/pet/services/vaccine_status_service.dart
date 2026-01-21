import 'package:hive_flutter/hive_flutter.dart';
import '../models/vaccine_status.dart';
import '../../../core/services/hive_atomic_manager.dart';

class VaccineStatusService {
  static const String _boxName = 'vaccine_status';
  Box<VaccineStatus>? _box;

  Future<void> init({HiveCipher? cipher}) async {
    _box = await HiveAtomicManager().ensureBoxOpen<VaccineStatus>(_boxName, cipher: cipher);
  }

  Box<VaccineStatus> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('VaccineStatusService not initialized. Call init() first.');
    }
    return _box!;
  }

  // Get status for a specific vaccine
  VaccineStatus? getStatus(String petName, String vaccineName) {
    final key = '${petName}_$vaccineName';
    return box.get(key);
  }

  // Check if vaccine is completed
  bool isCompleted(String petName, String vaccineName) {
    final status = getStatus(petName, vaccineName);
    return status?.isCompleted ?? false;
  }

  // Toggle vaccine status
  Future<void> toggleStatus(String petName, String vaccineName) async {
    final key = '${petName}_$vaccineName';
    final existing = box.get(key);
    
    if (existing != null) {
      existing.isCompleted = !existing.isCompleted;
      existing.completedDate = existing.isCompleted ? DateTime.now() : null;
      await existing.save();
    } else {
      final newStatus = VaccineStatus(
        petName: petName,
        vaccineName: vaccineName,
        isCompleted: true,
        completedDate: DateTime.now(),
      );
      await box.put(key, newStatus);
    }
  }

  // Get all completed vaccines for a pet
  List<VaccineStatus> getCompletedVaccines(String petName) {
    return box.values
        .where((status) => status.petName == petName && status.isCompleted)
        .toList();
  }

  // Get completion percentage for a pet
  double getCompletionPercentage(String petName, int totalVaccines) {
    if (totalVaccines == 0) return 0.0;
    final completed = getCompletedVaccines(petName).length;
    return (completed / totalVaccines) * 100;
  }

  // Close
  Future<void> close() async {
    await _box?.close();
  }
}
