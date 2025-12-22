import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/lab_exam.dart';
import '../../../../core/services/gemini_service.dart';

/// Service for processing lab exams with OCR and AI explanation
class LabExamService {
  final GeminiService _geminiService = GeminiService();
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Process exam file: extract text using Google ML Kit OCR
  Future<LabExam> processExam(LabExam exam) async {
    try {
      debugPrint('🔍 Iniciando OCR do exame...');
      
      // Extract text using Google ML Kit
      final extractedText = await _extractTextFromImage(exam.filePath);
      
      debugPrint('✅ OCR concluído. Texto extraído: ${extractedText.length} caracteres');
      
      // Update exam with extracted text
      final examWithText = exam.copyWith(
        extractedText: extractedText,
        isProcessing: false,
      );
      
      return examWithText;
    } catch (e) {
      debugPrint('❌ Erro no OCR: $e');
      return exam.copyWith(
        isProcessing: false,
        extractedText: 'Erro ao extrair texto. Tente novamente com uma imagem mais nítida.',
      );
    }
  }

  /// Generate AI explanation for exam results using Gemini
  Future<String> generateExplanation(LabExam exam) async {
    if (exam.extractedText == null || exam.extractedText!.isEmpty) {
      return 'Não foi possível extrair texto do exame.';
    }
    
    if (exam.extractedText!.contains('Erro ao extrair')) {
      return exam.extractedText!;
    }

    try {
      debugPrint('🤖 Gerando explicação com IA...');
      
      final prompt = _buildExplanationPrompt(exam);
      
      // Use Gemini API for real explanation
      final explanation = await _geminiService.generatePlainText(prompt);
      
      debugPrint('✅ Explicação gerada com sucesso');
      
      return explanation;
      
    } catch (e) {
      debugPrint('❌ Erro ao gerar explicação: $e');
      return 'Erro ao gerar explicação. Verifique sua conexão com a internet e tente novamente.';
    }
  }

  /// Extract text from image using Google ML Kit
  Future<String> _extractTextFromImage(String filePath) async {
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return 'Nenhum texto foi detectado na imagem. Certifique-se de que a imagem está nítida e bem iluminada.';
      }
      
      return recognizedText.text;
    } catch (e) {
      debugPrint('❌ Erro no Google ML Kit: $e');
      throw Exception('Falha no reconhecimento de texto: $e');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }

  String _buildExplanationPrompt(LabExam exam) {
    final categoryContext = _getCategoryContext(exam.category);
    
    return '''
Você é um assistente veterinário especializado em explicar exames laboratoriais para tutores de pets.

CONTEXTO: Este é um ${categoryContext['name']} de um animal de estimação.

TEXTO EXTRAÍDO DO EXAME:
${exam.extractedText}

INSTRUÇÕES:
1. Identifique os principais parâmetros mencionados no exame
2. Para cada parâmetro relevante, explique:
   - O que é esse parâmetro
   - O que ele indica sobre a saúde do pet
   - Se os valores parecem estar dentro ou fora do normal (se mencionados)
3. Use linguagem simples e acessível para tutores leigos
4. Seja objetivo e direto
5. Mencione apenas os parâmetros que realmente aparecem no texto
6. Limite a resposta a 300 palavras

IMPORTANTE: Esta é apenas uma análise informativa. Sempre recomende consultar o veterinário para interpretação completa.

Forneça a explicação em português brasileiro, de forma clara e organizada:
''';
  }

  Map<String, String> _getCategoryContext(String category) {
    switch (category) {
      case 'blood':
        return {
          'name': 'exame de sangue (hemograma ou bioquímico)',
          'focus': 'hemoglobina, leucócitos, plaquetas, enzimas hepáticas, função renal',
        };
      case 'urine':
        return {
          'name': 'exame de urina (EAS - Elementos Anormais e Sedimentoscopia)',
          'focus': 'densidade, pH, proteínas, glicose, cristais, células',
        };
      case 'feces':
        return {
          'name': 'exame de fezes (parasitológico)',
          'focus': 'parasitas, ovos, larvas, protozoários',
        };
      default:
        return {
          'name': 'exame laboratorial',
          'focus': 'parâmetros gerais de saúde',
        };
    }
  }

  /// Medical terms dictionary for quick reference
  static const Map<String, String> medicalTerms = {
    // Blood tests
    'hemoglobina': 'Proteína que transporta oxigênio no sangue',
    'hemácias': 'Glóbulos vermelhos, células que carregam oxigênio',
    'leucócitos': 'Glóbulos brancos, células de defesa do organismo',
    'plaquetas': 'Células responsáveis pela coagulação do sangue',
    'hematócrito': 'Percentual de células vermelhas no sangue',
    'neutrófilos': 'Tipo de glóbulo branco que combate infecções bacterianas',
    'linfócitos': 'Glóbulos brancos que combatem vírus e produzem anticorpos',
    'creatinina': 'Indicador da função renal',
    'ureia': 'Produto do metabolismo de proteínas, indica função renal',
    'alt': 'Enzima hepática, indica saúde do fígado',
    'ast': 'Enzima que indica lesão hepática ou muscular',
    
    // Urine tests
    'densidade': 'Concentração da urina, indica hidratação e função renal',
    'ph': 'Acidez ou alcalinidade da urina',
    'proteínas': 'Presença pode indicar problema renal',
    'glicose': 'Açúcar na urina, pode indicar diabetes',
    'cristais': 'Podem formar cálculos renais se em excesso',
    
    // Feces tests
    'parasitas': 'Organismos que vivem às custas do hospedeiro',
    'ovos': 'Ovos de parasitas intestinais',
    'larvas': 'Forma jovem de parasitas',
    'protozoários': 'Parasitas microscópicos unicelulares',
    'giárdia': 'Protozoário que causa diarreia',
    'ancilóstomo': 'Verme que se fixa no intestino',
  };
}
