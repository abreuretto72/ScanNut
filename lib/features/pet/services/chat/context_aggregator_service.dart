import '../../models/pet_profile_extended.dart';
import '../pet_profile_service.dart';
import '../pet_event_service.dart';
import '../../../../core/services/partner_service.dart';
import '../../../../core/models/partner_model.dart';

class ContextAggregatorService {
  static Future<String> aggregateForRag(String petIdOrName) async {
    final profileService = PetProfileService();
    final eventService = PetEventService();
    final partnerService = PartnerService();

    await profileService.init();
    await eventService.init();
    await partnerService.init();

    final profileMap = await profileService.getProfile(petIdOrName);
    if (profileMap == null) {
      return "Nenhum dado encontrado para o pet $petIdOrName.";
    }

    final profile = PetProfileExtended.fromJson(profileMap['data']);
    final events = eventService.getEventsByPet(profile.id);

    final partners = profile.linkedPartnerIds
        .map((id) => partnerService.getPartner(id))
        .where((p) => p != null)
        .cast<PartnerModel>()
        .toList();

    StringBuffer context = StringBuffer();
    context.writeln("Contexto do Pet: ${profile.petName}");

    // Identidade
    context.writeln("\n=== ABA: IDENTIDADE ===");
    context.writeln("Raça: ${profile.raca ?? 'Não informada'}");
    context.writeln("Espécie: ${profile.especie ?? 'Não informada'}");
    context.writeln("Idade: ${profile.idadeExata ?? 'Não informada'}");
    context.writeln(
        "Peso: ${profile.pesoAtual ?? '---'}kg (Ideal: ${profile.pesoIdeal ?? '---'}kg)");
    context.writeln("Microchip: ${profile.microchip ?? 'Nenhum'}");
    context.writeln("Sexo: ${profile.sex ?? 'Não informado'}");
    context.writeln(
        "Status Reprodutivo: ${profile.statusReprodutivo ?? 'Não informado'}");
    if (profile.observacoesIdentidade.isNotEmpty) {
      context.writeln(
          "OBSERVAÇÕES DE IDENTIDADE:\n${profile.observacoesIdentidade}");
    }

    // Saúde
    context.writeln("\n=== ABA: SAÚDE ===");
    context.writeln(
        "Última V8/V10: ${profile.dataUltimaV10?.toIso8601String() ?? 'N/A'}");
    context.writeln(
        "Última Antirrábica: ${profile.dataUltimaAntirrabica?.toIso8601String() ?? 'N/A'}");

    if (profile.observacoesSaude.isNotEmpty) {
      context.writeln("OBSERVAÇÕES DE SAÚDE:\n${profile.observacoesSaude}");
    }

    final healthEvents = events
        .where((e) =>
            e.type.toString().contains('health') ||
            e.type.toString().contains('medical'))
        .toList();
    if (healthEvents.isNotEmpty) {
      context.writeln("\nHistórico de Eventos Médicos:");
      for (var event in healthEvents.take(10)) {
        context.writeln(
            "- ${event.dateTime.toIso8601String()}: ${event.title} (${event.completed ? 'Concluído' : 'Pendente'})");
      }
    }

    // DETALHE DOS EXAMES LABORATORIAIS
    if (profile.labExams.isNotEmpty) {
      context.writeln("\nDETALHES DE EXAMES LABORATORIAIS:");
      for (var examMap in profile.labExams) {
        context.writeln(
            "--- Exame: ${examMap['category']} (${examMap['upload_date']}) ---");
        if (examMap['ai_explanation'] != null &&
            examMap['ai_explanation'].toString().isNotEmpty) {
          context.writeln("ANÁLISE IA: ${examMap['ai_explanation']}");
        }
        if (examMap['extracted_text'] != null &&
            examMap['extracted_text'].toString().isNotEmpty) {
          context.writeln("TEXTO EXTRAÍDO (OCR): ${examMap['extracted_text']}");
        }
      }
    }

    // Nutrição
    context.writeln("\n=== ABA: NUTRIÇÃO ===");
    context.writeln(
        "Alergias: ${profile.alergiasConhecidas.isEmpty ? 'Nenhuma registrada' : profile.alergiasConhecidas.join(', ')}");
    context.writeln(
        "Restrições: ${profile.restricoes.isEmpty ? 'Nenhuma registrada' : profile.restricoes.join(', ')}");
    context.writeln(
        "Preferências: ${profile.preferencias.isEmpty ? 'Nenhuma registrada' : profile.preferencias.join(', ')}");

    if (profile.observacoesNutricao.isNotEmpty) {
      context
          .writeln("OBSERVAÇÕES DE NUTRIÇÃO:\n${profile.observacoesNutricao}");
    }

    if (profile.rawAnalysis?['weight_analysis'] != null) {
      context.writeln(
          "Análise de Peso IA: ${profile.rawAnalysis!['weight_analysis']}");
    }

    // Viagem
    context.writeln("\n=== ABA: VIAGEM ===");
    if (profile.travelPreferences.isNotEmpty) {
      context.writeln("Preferências de Viagem: ${profile.travelPreferences}");
    }
    context.writeln(
        "Observações de Viagem (Galeria): ${profile.observacoesGaleria}");

    // Planos
    context.writeln("\n=== ABA: PLANOS ===");
    context
        .writeln("Plano de Saúde: ${profile.healthPlan?['nome'] ?? 'Nenhum'}");
    context.writeln(
        "Seguro de Vida: ${profile.lifeInsurance?['nome'] ?? 'Nenhum'}");
    context
        .writeln("Plano FUNERAL: ${profile.funeralPlan?['nome'] ?? 'Nenhum'}");
    if (profile.observacoesPlanos.isNotEmpty) {
      context.writeln("OBSERVAÇÕES DE PLANOS:\n${profile.observacoesPlanos}");
    }

    // PRAC
    context.writeln("\n=== ABA: PRAC (Acompanhamento Comportamental) ===");
    if (profile.observacoesPrac.isNotEmpty) {
      context.writeln("OBSERVAÇÕES PRAC:\n${profile.observacoesPrac}");
    }

    // Parceiros
    context.writeln("\n=== REDE DE APOIO (HOSPITAIS/VETS) ===");
    if (partners.isNotEmpty) {
      for (var p in partners) {
        context.writeln(
            "- ${p.name} (Categoria: ${p.category}, Local: ${p.address ?? 'Não informado'})");
      }
    }

    return context.toString();
  }
}
