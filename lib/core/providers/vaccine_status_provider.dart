import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/pet/services/vaccine_status_service.dart';

final vaccineStatusServiceProvider = Provider<VaccineStatusService>((ref) {
  return VaccineStatusService();
});
