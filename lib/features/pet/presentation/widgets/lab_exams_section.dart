import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../../models/lab_exam.dart';

/// Expanded Lab Exams Section with Categories, OCR, and AI Explanation
class LabExamsSection extends StatefulWidget {
  final List<LabExam> exams;
  final Function(LabExam) onAddExam;
  final Function(String examId) onDeleteExam;
  final Function(String examId) onExplainExam;
  final VoidCallback onMarkDirty;

  const LabExamsSection({
    Key? key,
    required this.exams,
    required this.onAddExam,
    required this.onDeleteExam,
    required this.onExplainExam,
    required this.onMarkDirty,
  }) : super(key: key);

  @override
  State<LabExamsSection> createState() => _LabExamsSectionState();
}

class _LabExamsSectionState extends State<LabExamsSection> {
  String? _expandedCategory;

  List<LabExam> _getExamsForCategory(String categoryId) {
    return widget.exams.where((exam) => exam.category == categoryId).toList()
      ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.science, color: Color(0xFF00E676), size: 20),
            const SizedBox(width: 8),
            Text(
              '🧪 Exames Laboratoriais',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Organize exames por categoria e obtenha explicações assistidas por IA',
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 16),
        
        // Categories
        ...ExamCategory.all.map((category) {
          final categoryExams = _getExamsForCategory(category.id);
          final isExpanded = _expandedCategory == category.id;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: categoryExams.isNotEmpty 
                    ? category.color.withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: Key(category.id),
                initiallyExpanded: isExpanded,
                onExpansionChanged: (expanded) {
                  setState(() => _expandedCategory = expanded ? category.id : null);
                },
                leading: Icon(category.icon, color: category.color, size: 22),
                title: Row(
                  children: [
                    Text(
                      category.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (categoryExams.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${categoryExams.length}',
                          style: TextStyle(
                            color: category.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00E676)),
                  onPressed: () => _showAddExamDialog(category),
                  tooltip: 'Adicionar ${category.name}',
                ),
                iconColor: category.color,
                collapsedIconColor: Colors.white30,
                children: [
                  if (categoryExams.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Nenhum exame anexado ainda',
                        style: GoogleFonts.poppins(
                          color: Colors.white30,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...categoryExams.map((exam) => _buildExamCard(exam, category)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildExamCard(LabExam exam, ExamCategory category) {
    final file = File(exam.filePath);
    final isPdf = exam.filePath.toLowerCase().endsWith('.pdf');
    final hasExplanation = exam.aiExplanation != null && exam.aiExplanation!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: category.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thumbnail/Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf_rounded : Icons.image,
                  color: isPdf ? Colors.red : Colors.blueAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path.basename(exam.filePath),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(exam.uploadDate),
                      style: const TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                color: Colors.grey[900],
                onSelected: (value) {
                  if (value == 'delete') {
                    widget.onDeleteExam(exam.id);
                  } else if (value == 'view') {
                    _viewExam(exam);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text('Visualizar', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Processing Indicator
          if (exam.isProcessing) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              color: Color(0xFF00E676),
              backgroundColor: Colors.white10,
            ),
            const SizedBox(height: 4),
            Text(
              'Processando OCR e análise...',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
            ),
          ],
          
          // Explain Button
          if (!exam.isProcessing && exam.extractedText != null) ...[
            const SizedBox(height: 12),
            if (!hasExplanation)
              ElevatedButton.icon(
                onPressed: () => widget.onExplainExam(exam.id),
                icon: const Icon(Icons.psychology, size: 16),
                label: const Text('Explicar Exame'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: category.color.withOpacity(0.2),
                  foregroundColor: category.color,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
          ],
          
          // AI Explanation
          if (hasExplanation) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Color(0xFF00E676), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Análise Assistida',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00E676),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exam.aiExplanation!,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Esta análise é informativa e baseada em processamento automático. Consulte sempre o veterinário vinculado na aba Parc. para um diagnóstico preciso.',
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddExamDialog(ExamCategory category) {
    // Create a template exam with the selected category
    final templateExam = LabExam(
      id: '', // Will be set by parent
      category: category.id,
      filePath: '', // Will be set by parent
      uploadDate: DateTime.now(),
    );
    
    // Call parent to handle file picking and processing
    widget.onAddExam(templateExam);
  }

  void _viewExam(LabExam exam) {
    // TODO: Implement file viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Visualizar: ${path.basename(exam.filePath)}')),
    );
  }
}
