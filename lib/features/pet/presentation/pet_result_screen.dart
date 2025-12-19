import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/presentation/home_view.dart';
import '../models/pet_analysis_result.dart';
import '../services/pet_analysis_service.dart';

final petResultProvider = StateProvider<PetAnalysisResult?>((ref) => null);

class PetResultScreen extends ConsumerStatefulWidget {
  final File imageFile;

  const PetResultScreen({super.key, required this.imageFile});

  @override
  ConsumerState<PetResultScreen> createState() => _PetResultScreenState();
}

class _PetResultScreenState extends ConsumerState<PetResultScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      final service = ref.read(petAnalysisServiceProvider);
      final result = await service.analyzePet(widget.imageFile);
      
      if (mounted) {
        ref.read(petResultProvider.notifier).state = result;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(petResultProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Análise Veterinária', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : result == null
              ? const Center(child: Text('Nenhum resultado.', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          widget.imageFile,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Urgency Card
                      _buildUrgencyCard(result),
                      
                      const SizedBox(height: 16),
                      
                      // Details Card
                      _buildInfoCard(
                        title: 'Identificação',
                        content: result.especie,
                        icon: Icons.search,
                      ),
                      _buildInfoCard(
                        title: 'Padrões Visuais',
                        content: result.descricaoVisual,
                        icon: Icons.visibility,
                      ),
                      _buildInfoCard(
                        title: 'Possíveis Causas',
                        content: result.possiveisCausas.join('\n• '),
                        icon: Icons.list,
                        isList: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Disclaimer Footer
                      const Text(
                        'Nota: Esta é uma análise feita por IA e não substitui um diagnóstico clínico.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUrgencyCard(PetAnalysisResult result) {
    Color color;
    IconData icon;
    String title;

    switch (result.urgenciaNivel) {
      case 'Vermelho':
        color = Colors.redAccent;
        icon = Icons.warning_amber_rounded;
        title = 'Urgência Veterinária';
        break;
      case 'Amarelo':
        color = Colors.orangeAccent;
        icon = Icons.info_outline;
        title = 'Atenção Necessária';
        break;
      case 'Verde':
      default:
        color = Colors.greenAccent;
        icon = Icons.check_circle_outline;
        title = 'Observação';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (result.urgenciaNivel == 'Vermelho') ...[
            const SizedBox(height: 12),
            const Text(
              'SINAIS CRÍTICOS IDENTIFICADOS.\nProcure um Veterinário Imediatamente.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          const Text(
            'Orientação Imediata:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            result.orientacaoImediata,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content, required IconData icon, bool isList = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00E676), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isList ? '• $content' : content,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
