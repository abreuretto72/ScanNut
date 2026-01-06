import 'menu_creation_params.dart';

class MenuCreationResult {
  final MenuCreationParams params;
  final String selectedPeriodId;

  MenuCreationResult({
    required this.params,
    required this.selectedPeriodId,
  });
}
