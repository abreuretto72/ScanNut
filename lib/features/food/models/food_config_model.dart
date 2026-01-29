class FoodConfigModel {
  final String activeModel;
  final String apiEndpoint;
  final bool enforceOrangeTheme;
  final int recipesPerRequest;

  FoodConfigModel({
    required this.activeModel,
    required this.apiEndpoint,
    required this.enforceOrangeTheme,
    required this.recipesPerRequest,
  });

  factory FoodConfigModel.fromJson(Map<String, dynamic> json) {
    return FoodConfigModel(
      activeModel: json['active_model'] ?? 'gemini-2.0-flash', // Fallback seguro
      apiEndpoint: json['api_endpoint'] ?? 'https://generativelanguage.googleapis.com/v1beta/models/',
      enforceOrangeTheme: json['enforce_orange_theme'] ?? true,
      recipesPerRequest: json['recipes_per_request'] ?? 3,
    );
  }

  // Fallback Invariável conforme Lei de Ferro
  factory FoodConfigModel.defaultConfig() {
    return FoodConfigModel(
      activeModel: 'gemini-2.0-flash',
      apiEndpoint: 'https://generativelanguage.googleapis.com/v1beta/models/',
      enforceOrangeTheme: true,
      recipesPerRequest: 3,
    );
  }
}
