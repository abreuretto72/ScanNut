import 'package:flutter/material.dart';

/// Model for Lab Exam with OCR and AI analysis
class LabExam {
  final String id;
  final String category; // 'blood', 'urine', 'feces', 'other'
  final String filePath;
  final DateTime uploadDate;
  final String? extractedText; // OCR result
  final String? aiExplanation; // AI-generated explanation
  final bool isProcessing;

  LabExam({
    required this.id,
    required this.category,
    required this.filePath,
    required this.uploadDate,
    this.extractedText,
    this.aiExplanation,
    this.isProcessing = false,
  });

  factory LabExam.fromJson(Map<String, dynamic> json) {
    return LabExam(
      id: json['id'] as String,
      category: json['category'] as String,
      filePath: json['file_path'] as String,
      uploadDate: DateTime.parse(json['upload_date'] as String),
      extractedText: json['extracted_text'] as String?,
      aiExplanation: json['ai_explanation'] as String?,
      isProcessing: json['is_processing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'file_path': filePath,
      'upload_date': uploadDate.toIso8601String(),
      if (extractedText != null) 'extracted_text': extractedText,
      if (aiExplanation != null) 'ai_explanation': aiExplanation,
      'is_processing': isProcessing,
    };
  }

  LabExam copyWith({
    String? id,
    String? category,
    String? filePath,
    DateTime? uploadDate,
    String? extractedText,
    String? aiExplanation,
    bool? isProcessing,
  }) {
    return LabExam(
      id: id ?? this.id,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      uploadDate: uploadDate ?? this.uploadDate,
      extractedText: extractedText ?? this.extractedText,
      aiExplanation: aiExplanation ?? this.aiExplanation,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// Exam category metadata
class ExamCategory {
  final String id;

  final IconData icon;
  final Color color;

  const ExamCategory({
    required this.id,
    required this.icon,
    required this.color,
  });

  static const blood = ExamCategory(
    id: 'blood',
    icon: Icons.bloodtype,
    color: Color(0xFFE53935),
  );

  static const urine = ExamCategory(
    id: 'urine',
    icon: Icons.water_drop,
    color: Color(0xFFFDD835),
  );

  static const feces = ExamCategory(
    id: 'feces',
    icon: Icons.medication,
    color: Color(0xFF8D6E63),
  );

  static const other = ExamCategory(
    id: 'other',
    icon: Icons.add_to_photos,
    color: Color(0xFF00E676),
  );

  static List<ExamCategory> get all => [blood, urine, feces, other];
  
  static ExamCategory fromId(String id) {
    return all.firstWhere((cat) => cat.id == id, orElse: () => other);
  }
}
