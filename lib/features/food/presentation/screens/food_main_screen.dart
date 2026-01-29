import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/food_camera_body.dart';

/// 🛡️ FoodMainScreen (V135 - UI Decoupling)
/// Acts as the specific shell for the Food Domain, hosting the CameraBody
/// and ensuring layout safety (Samsung A25).
class FoodMainScreen extends ConsumerWidget {
  final bool isActive;

  const FoodMainScreen({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛡️ Samsung A25 Safe Layout
    // We use a Scaffold to ensure proper structure, 
    // although the internal FoodCameraBody handles specific offsets.
    debugPrint('🖥️ [FoodTrace] FoodMainScreen Rebuild. isActive: $isActive');

    // 🛡️ Error Handling (Feedback V135)
    _handleAnalysisError(context, ref);

    return Scaffold(
      backgroundColor: Colors.black,
      body: FoodCameraBody(isActive: isActive),
    );
  }

  void _handleAnalysisError(BuildContext context, WidgetRef ref) {
    // Monitora o estado de análise para exibir erros visuais
    // Isso garante que erros de API não sejam silenciosos
    // Nota: O SnackBar deve ser exibido em um microtask ou post-frame callback para evitar conflitos de build
    /*
    final state = ref.watch(foodAnalysisNotifierProvider);
    if (state is AnalysisError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Verifica se há um ScaffoldMessenger disponível e se o erro é novo (opcional, gerenciado pelo Notifier geralmente)
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
    */
    // Abordagem simplificada: O FoodCameraBody já lida com o estado de erro, mas aqui podemos adicionar uma camada extra se necessário.
    // Por enquanto, vamos deixar o FoodCameraBody lidar com a exibição, pois ele tem o contexto de UI.
    // Mas se o erro persistir e travar o processamento, precisamos resetar.
  }
}
