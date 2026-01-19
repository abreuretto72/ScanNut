import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/pet_event_model.dart';
import '../services/pet_event_repository.dart';
import 'package:uuid/uuid.dart';

/// 🧠 PET INDEXING ENGINE (MARE Logic)
/// Automatically monitors and indexes pet-related actions into the Global Timeline.
class PetIndexingService {
  static final PetIndexingService _instance = PetIndexingService._internal();
  factory PetIndexingService() => _instance;
  PetIndexingService._internal();

  final _repository = PetEventRepository();
  final _uuid = const Uuid();

  /// 1. AI Analysis Indexing (MARE - Análises de IA)
  Future<void> indexAiAnalysis({
    required String petId,
    required String petName,
    required String analysisType, // e.g., 'Fezes', 'Urina', 'Sangue'
    required String resultId,
    Map<String, dynamic>? rawResult, // 🛡️ V231: Full result payload
    String? imagePath, // 🛡️ V231: Associated image
    String? localizedTitle,
    String? localizedNotes,
  }) async {
    final event = PetEventModel(
      id: 'idx_ai_${_uuid.v4()}',
      petId: petId,
      group: 'health',
      type: 'ai_analysis',
      title: localizedTitle ?? 'Análise de IA: $analysisType ($petName)',
      notes: localizedNotes ?? 'Análise clínica gerada por Inteligência Artificial.',
      timestamp: DateTime.now(),
      data: {
        'pet_name': petName,
        'analysis_type': analysisType,
        'result_id': resultId,
        'deep_link': 'scannut://pet/analysis/$resultId',
        'raw_result': rawResult != null ? jsonEncode(rawResult) : null, // 🛡️ Store JSON
        'image_path': imagePath, // 🛡️ Store Path
        'is_automatic': true,
        'indexing_origin': 'mare_ia',
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.init();
    await _repository.addEvent(event);
    debugPrint('🧠 [PET_INDEXER] AI Analysis indexed for $petName');
  }

  /// 2. Occurrence Indexing (MUO Logic - Interceptar Categorias)
  Future<void> indexOccurrence({
    required String petId,
    required String petName,
    required String group, // health, hygiene, medication, etc.
    required String title,
    String? localizedTitle,
    String? localizedNotes,
    String? notes,
    Map<String, dynamic>? extraData,
  }) async {
    final event = PetEventModel(
      id: 'idx_muo_${_uuid.v4()}',
      petId: petId,
      group: group,
      type: 'occurrence',
      title: localizedTitle ?? title,
      notes: localizedNotes ?? notes ?? '',
      timestamp: DateTime.now(),
      data: {
        'pet_name': petName,
        'is_automatic': true,
        'indexing_origin': 'muo',
        ...?extraData,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.init();
    await _repository.addEvent(event);
    debugPrint('🧠 [PET_INDEXER] Occurrence indexed: $title');
  }

  /// 3. Consultation & Agenda Indexing (Consultas e Agenda)
  Future<void> indexAgendaEvent({
    required String petId,
    required String petName,
    required String attendantName,
    required String eventTitle,
    required DateTime dateTime,
    String? partnerId,
    String? partnerName,
    String? localizedTitle,
  }) async {
    final event = PetEventModel(
      id: 'idx_age_${_uuid.v4()}',
      petId: petId,
      group: 'schedule',
      type: 'appointment',
      title: localizedTitle ?? '$attendantName + $petName',
      notes: eventTitle,
      timestamp: dateTime,
      data: {
        'pet_name': petName,
        'attendant': attendantName,
        'partner_id': partnerId,
        'partner_name': partnerName,
        'is_automatic': true,
        'distance_id': dateTime.millisecondsSinceEpoch.toString(), // For deep linking matching
        'deep_link': 'scannut://agenda/event/${dateTime.millisecondsSinceEpoch}',
        'indexing_origin': 'agenda',
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.init();
    await _repository.addEvent(event);
    debugPrint('🧠 [PET_INDEXER] Agenda item indexed for $petName');
  }

  /// 4. Partner Interaction Indexing (Interação com Parceiros)
  Future<void> indexPartnerInteraction({
    required String petId,
    required String petName,
    required String partnerName,
    required String interactionType, // 'favorited', 'scheduled', 'contacted', 'linked_partner'
    String? partnerId,
    String? localizedTitle,
    String? localizedNotes,
  }) async {
    final String defaultTitle;
    switch (interactionType) {
      case 'favorited':
        defaultTitle = 'Parceiro Favoritado: $partnerName';
        break;
      case 'scheduled':
        defaultTitle = 'Interação agendada com $partnerName';
        break;
      case 'contacted':
        defaultTitle = 'Contato via WhatsApp/GPS: $partnerName';
        break;
      case 'linked_partner':
        defaultTitle = 'Parceiro vinculado ao perfil: $partnerName';
        break;
      default:
        defaultTitle = 'Interação com $partnerName';
    }

    final title = localizedTitle ?? '$petName: $defaultTitle';

    final event = PetEventModel(
      id: 'idx_ptr_${_uuid.v4()}',
      petId: petId,
      group: 'schedule',
      type: 'partner_interaction',
      title: title,
      notes: localizedNotes ?? 'Interação registrada via Radar Geo.',
      timestamp: DateTime.now(),
      data: {
        'pet_name': petName,
        'partner_name': partnerName,
        'partner_id': partnerId,
        'interaction_type': interactionType,
        'is_automatic': true,
        'indexing_origin': 'radar_geo',
        if (partnerId != null) 'deep_link': 'scannut://partners/profile/$partnerId',
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.init();
    await _repository.addEvent(event);
    debugPrint('🧠 [PET_INDEXER] Partner interaction indexed');
  }

  /// 5. Vault / File Management Indexing (Gestão de Arquivos - Vault)
  Future<void> indexVaultUpload({
    required String petId,
    required String petName,
    required String fileName,
    required String vaultPath,
    String? fileType,
    String? localizedTitle,
    String? localizedNotes,
  }) async {
    final event = PetEventModel(
      id: 'idx_vlt_${_uuid.v4()}',
      petId: petId,
      group: 'media',
      type: 'vault_upload',
      title: localizedTitle ?? 'Arquivo: $fileName ($petName)',
      notes: localizedNotes ?? 'Documento indexado no Media Vault.',
      timestamp: DateTime.now(),
      data: {
        'pet_name': petName,
        'file_name': fileName,
        'vault_path': vaultPath,
        'file_type': fileType,
        'is_automatic': true,
        'indexing_origin': 'vault',
        'deep_link': 'scannut://vault/open?path=$vaultPath',
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.init();
    await _repository.addEvent(event);
    debugPrint('🧠 [PET_INDEXER] Vault upload indexed for $petName');
  }

  /// 6. Task Completion Indexing (Agenda -> Saúde)
  Future<void> indexTaskCompletion({
    required String petId,
    required String petName,
    required String taskTitle,
    required String taskId,
    String? localizedTitle,
    String? localizedNotes,
  }) async {
    await _repository.init();

    // 1. Idempotency Check (De-duplication)
    final alreadyExists = _repository.box.values.any((e) => 
      e.data['original_task_id'] == taskId && 
      e.data['indexing_origin'] == 'agenda_completion'
    );

    if (alreadyExists) {
       debugPrint('⚠️ [PET_INDEXER] Duplicate task completion ignored: $taskId');
       return;
    }

    // 2. Smart Title Parsing (Avoid repetitive prefixes)
    // If the title already starts with the localized prefix concept (e.g. "Tarefa concluída"), use it raw.
    // Since we receive localizedTitle which might be "Tarefa concluída: Vacina", 
    // we check if taskTitle (Vacina) was already "Tarefa concluída: ...".
    
    // Simpler approach: If taskTitle starts with "Tarefa" or "Task", assume it's already formatted.
    // However, localizedTitle is constructed in UI. 
    // If taskTitle is "Vacina", localizedTitle is "Tarefa concluída: Vacina".
    // If taskTitle is "Tarefa concluída: Vacina", localizedTitle leads to "Tarefa concluída: Tarefa concluída: Vacina".
    
    final effectiveTitle = (taskTitle.startsWith('Tarefa') || taskTitle.startsWith('Task')) 
        ? taskTitle 
        : (localizedTitle ?? 'Tarefa concluída: $taskTitle');

    final event = PetEventModel(
      id: 'idx_tsk_${_uuid.v4()}',
      petId: petId,
      group: 'health', // Always indexes to health as per requirement
      type: 'occurrence',
      title: effectiveTitle,
      notes: localizedNotes ?? 'Tarefa concluída via Agenda Geral.',
      timestamp: DateTime.now(),
      data: {
        'pet_name': petName,
        'original_task': taskTitle,
        'original_task_id': taskId,
        'is_automatic': true,
        'indexing_origin': 'agenda_completion',
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.addEvent(event);
    debugPrint('🧠 [PET_INDEXER] Task completion indexed: $taskTitle');
  }
}
