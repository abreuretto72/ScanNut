import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/pet/services/pet_event_service.dart';

final petEventServiceProvider = FutureProvider<PetEventService>((ref) async {
  final service = PetEventService();
  await service.init();
  return service;
});
