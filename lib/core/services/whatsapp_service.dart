import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> abrirChat({
    required String telefone,
    required String mensagem,
  }) async {
    // Remove caracteres não numéricos do telefone
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');

    // Se o número não começar com o código do país, assume 55 (Brasil)
    if (numeroLimpo.length <= 11) {
      numeroLimpo = '55$numeroLimpo';
    }

    // Codifica a mensagem para URL
    String url =
        "https://wa.me/$numeroLimpo?text=${Uri.encodeComponent(mensagem)}";

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Não foi possível abrir o WhatsApp';
    }
  }

  /// Gera mensagem contextual para Veterinário
  static String gerarMensagemVeterinario({
    required String petName,
    required String raca,
    String? statusSaude,
  }) {
    String msg = "Olá, sou tutor do $petName (Raça: $raca). ";
    if (statusSaude != null && statusSaude.isNotEmpty) {
      msg +=
          "Ele realizou um scan de saúde no ScanNut que indicou: $statusSaude. ";
    }
    msg += "Gostaria de agendar uma consulta.";
    return msg;
  }

  /// Gera mensagem contextual para Pet Shop/Alimentação
  static String gerarMensagemNutricao({
    required String petName,
    required List<String> ingredientes,
  }) {
    final lista = ingredientes.join(", ");
    return "Olá, gostaria de saber se vocês têm os ingredientes para a dieta natural do meu pet ($petName): $lista.";
  }

  /// Gera mensagem contextual para Banho e Tosa
  static String gerarMensagemEstetica({
    required String petName,
    required String raca,
    required String sugestaoTosa,
  }) {
    return "Olá, gostaria de agendar um banho e tosa para o $petName ($raca). A IA do ScanNut sugeriu o estilo: $sugestaoTosa.";
  }
}
