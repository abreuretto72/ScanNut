import 'package:flutter/foundation.dart';

// Analysis State Management
@immutable
abstract class AnalysisState {}

class AnalysisIdle extends AnalysisState {}

class AnalysisLoading extends AnalysisState {
  final String message;
  AnalysisLoading({this.message = 'Analisando...'});
}

class AnalysisSuccess<T> extends AnalysisState {
  final T data;
  AnalysisSuccess(this.data);
}

class AnalysisError extends AnalysisState {
  final String message;
  AnalysisError(this.message);
}
