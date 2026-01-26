import '../models/food_analysis_model.dart';

abstract class FoodAnalysisState {}

class FoodInitial extends FoodAnalysisState {}

class FoodLoading extends FoodAnalysisState {
  final String message;
  FoodLoading(this.message);
}

class FoodSuccess extends FoodAnalysisState {
  final FoodAnalysisModel result;
  FoodSuccess(this.result);
}

class FoodError extends FoodAnalysisState {
  final String message;
  FoodError(this.message);
}
