import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pet_profile_extended.dart';
import 'pet_profile_service.dart';
import 'scan_walk_service.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';

/// 🛡️ SESSION GUARD: Inteligência de Entrada ScanWalk
/// Gerencia a seleção de pet (Zero Fricção) e inicialização de sessão.
class SessionGuard {
  static final SessionGuard _instance = SessionGuard._internal();
  factory SessionGuard() => _instance;
  SessionGuard._internal();

  final PetProfileService _petService = PetProfileService();
  final ScanWalkService _walkService = ScanWalkService();

  /// Valida a quantidade de pets e define o activePet da sessão.
  /// Retorna o Pet selecionado ou null se cancelado/erro.
  Future<PetProfileExtended?> validatePetSession(BuildContext context) async {
    // 1. Carregar Perfis com Sincronização Forçada
    debugPrint("🔍 [ScanWalk Guard] Iniciando validação de sessão...");
    await _petService.syncWithDisk();

    var profilesRaw = await _petService.getAllProfiles();

    // 🧬 [Auto-Cura Genética] - Se estiver vazio, tenta uma sincronização nuclear antes de desistir
    if (profilesRaw.isEmpty) {
      debugPrint(
          "🧬 [ScanWalk Guard] Box vazia! Acionando Auto-Cura (Nuclear Re-read)...");
      await _petService.syncWithDisk();
      profilesRaw = await _petService.getAllProfiles();
      debugPrint(
          "📊 [ScanWalk Guard] Pós-Cura: Pets encontrados: ${profilesRaw.length}");
    }

    if (profilesRaw.isEmpty) {
      debugPrint(
          "⚠️ ScanWalk: Realmente não há pets cadastrados no disco físico.");
      _showNoPetAlert(context);
      return null;
    }

    final List<PetProfileExtended> pets =
        profilesRaw.map((p) => PetProfileExtended.fromJson(p)).toList();

    PetProfileExtended? selectedPet;

    // 2. Lógica Zero Fricção (Cenário Pet Único)
    if (pets.length == 1) {
      selectedPet = pets.first;
      debugPrint(
          "🚀 ScanWalk Guard: Pet único detectado (${selectedPet.petName}). Pulando seleção.");
    } else {
      // 3. Cenário Multi-Pet: Modal de Seleção Rápida
      selectedPet = await _showQuickSelectionModal(context, pets);
    }

    if (selectedPet != null) {
      // 4. Sessão de Dados: Inicializar box vinculada ao PetID
      // 🛡️ RE-VALIDAÇÃO FÍSICA (Lei de Ferro): Recupera do disco p/ garantir persistência real
      final verified = await _petService.getProfile(selectedPet.id);
      if (verified == null) {
        debugPrint(
            "❌ [ScanWalk Guard] CRÍTICO: Pet Fantasma detectado! ID=${selectedPet.id} não consta no box.");
        if (context.mounted) _showNoPetAlert(context);
        return null;
      }

      await _walkService.init();
      debugPrint(
          "✅ Sessão ScanWalk inicializada para: ${selectedPet.petName} (ID=${selectedPet.id})");
    }

    return selectedPet;
  }

  Future<PetProfileExtended?> _showQuickSelectionModal(
    BuildContext context,
    List<PetProfileExtended> pets,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    return showModalBottomSheet<PetProfileExtended>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: AppDesign.backgroundDark.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: AppDesign.petPink.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),

              Text(
                "Quem vai no passeio?",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Selecione o pet ativo para o monitoramento",
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // Grid de Pets Premium
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: pets
                        .map((pet) => _PetSelectionTile(
                              pet: pet,
                              onTap: () => Navigator.pop(context, pet),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoPetAlert(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.scanWalkNoPetError,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "SINCRONIZAR",
          textColor: Colors.white,
          onPressed: () async {
            // ☢️ NUCLEAR RECOVERY: Forçar o Hive a ler novamente do disco
            final ps = PetProfileService();
            await ps.syncWithDisk();
            debugPrint(
                "☢️ [ScanWalk Guard] Sincronização manual acionada pelo usuário.");
          },
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.4,
          left: 20,
          right: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _PetSelectionTile extends StatelessWidget {
  final PetProfileExtended pet;
  final VoidCallback onTap;

  const _PetSelectionTile({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 85,
            height: 85,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppDesign.petPink,
                  AppDesign.petPink.withValues(alpha: 0.3)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A1A1A),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: pet.imagePath != null
                    ? Image.file(File(pet.imagePath!), fit: BoxFit.cover)
                    : const Icon(Icons.pets,
                        color: AppDesign.petPink, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pet.petName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
