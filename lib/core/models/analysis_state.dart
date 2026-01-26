import 'package:flutter/foundation.dart';

// Analysis State Management
@immutable
abstract class AnalysisState {}

class AnalysisIdle extends AnalysisState {}

class AnalysisLoading extends AnalysisState {
  final String message;
  final String? imagePath;
  AnalysisLoading({this.message = 'Analisando...', this.imagePath});
}

class AnalysisSuccess<T> extends AnalysisState {
  final T data;
  AnalysisSuccess(this.data);
}

class AnalysisError extends AnalysisState {
  final String message;
  final String? visualFeedback; // 🛡️ V231: feedback visual (ex: 'critico' para fundo vermelho)
  AnalysisError(this.message, {this.visualFeedback});
}
