import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // Ensure share_plus is in pubspec, or use Printing
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:scannut/l10n/app_localizations.dart';

import '../../pet/models/pet_profile_extended.dart';
import '../../pet/services/pet_profile_service.dart';
import '../../../core/services/export_service.dart';

class BackupOptimizeDialog extends StatefulWidget {
  const BackupOptimizeDialog({Key? key}) : super(key: key);

  @override
  State<BackupOptimizeDialog> createState() => _BackupOptimizeDialogState();
}

class _BackupOptimizeDialogState extends State<BackupOptimizeDialog> {
  bool _isLoading = false;
  List<String> _petNames = [];
  String? _selectedPetName;
  final PetProfileService _profileService = PetProfileService();

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    await _profileService.init();
    final names = await _profileService.getAllPetNames();
    if (mounted) {
      setState(() {
        _petNames = names;
        if (names.isNotEmpty) _selectedPetName = names.first;
      });
    }
  }

  Future<void> _performBackupAndOptimize() async {
    if (_selectedPetName == null) return;
    final strings = AppLocalizations.of(context)!;
    
    setState(() => _isLoading = true);

    try {
      // 1. Load Profile
      final profileMap = await _profileService.getProfile(_selectedPetName!);
      if (profileMap == null) throw Exception('Perfil não encontrado');

      // Ensure we have a valid Map structure for fromHiveEntry
      // It expects the wrapper map with 'data' key? 
      // getProfile returns the raw map? No, getProfile returns map with 'pet_name', 'data', etc.
      // PetProfileExtended.fromHiveEntry handles { 'pet_name': ..., 'data': {...} }
      final profile = PetProfileExtended.fromHiveEntry(profileMap);

      // 2. Generate Full PDF
      final pdfDoc = await ExportService().generatePetProfileReport(
        profile: profile,
        strings: strings,
        // All sections true
        selectedSections: {
          'identity': true,
          'health': true,
          'nutrition': true,
          'gallery': true,
          'parc': true,
        },
      );
      final pdfBytes = await pdfDoc.save();

      // 3. Save/Share PDF
      final fileName = 'ScanNut_Backup_${profile.petName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      
      // We use Printing.sharePdf which works cross-platform to save/share
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);

      // 4. Offer Optimization
      if (!mounted) return;
      
      // Close this dialog and show confirmation for cleaning
      Navigator.pop(context); // Close backup dialog
      _showCleanConfirmation(profile);

    } catch (e) {
      debugPrint('Error in backup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCleanConfirmation(PetProfileExtended profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Otimização de Armazenamento', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          'Backup PDF gerado com sucesso!\n\nDeseja remover registros com mais de 2 anos (Observações e Feridas) para liberar espaço no dispositivo? O histórico antigo permanecerá salvo no PDF que você acabou de exportar.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Manter Tudo', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              Navigator.pop(ctx);
              await _cleanOldData(profile);
            },
            child: Text('Limpar Antigos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _cleanOldData(PetProfileExtended profile) async {
    try {
      final twoYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 2));
      bool changed = false;

      // Clean Text Fields (Regex Parse)
      String cleanText(String text) {
        if (text.isEmpty) return text;
        final entries = text.split('\n\n');
        final keptEntries = <String>[];
        final dateRegex = RegExp(r'\[(\d{2}/\d{2}/\d{4}) - \d{2}:\d{2}\]');

        for (final entry in entries) {
           final match = dateRegex.firstMatch(entry);
           if (match != null) {
              try {
                // Parse date dd/MM/yyyy
                final dateStr = match.group(1)!;
                final date = DateFormat('dd/MM/yyyy').parse(dateStr);
                if (date.isAfter(twoYearsAgo)) {
                   keptEntries.add(entry);
                }
                // If before, prune (don't add)
              } catch (e) {
                 keptEntries.add(entry); // Keep invalid format
              }
           } else {
              keptEntries.add(entry); // Keep unformatted text
           }
        }
        return keptEntries.join('\n\n');
      }

      final currentObsSaude = profile.observacoesSaude;
      final currentObsPrac = profile.observacoesPrac;
      final currentWoundHistory = List<Map<String, dynamic>>.from(profile.woundAnalysisHistory); // Mutable Copy

      final newObsSaude = cleanText(currentObsSaude);
      final newObsPrac = cleanText(currentObsPrac);
      
      if (newObsSaude.length != currentObsSaude.length) changed = true;
      if (newObsPrac.length != currentObsPrac.length) changed = true;

      // Clean Wound Analysis
      final originalWoundCount = currentWoundHistory.length;
      currentWoundHistory.removeWhere((w) {
         try {
           final date = DateTime.parse(w['date']);
           return date.isBefore(twoYearsAgo);
         } catch(e) { return false; }
      });
      if (currentWoundHistory.length != originalWoundCount) changed = true;


      if (changed) {
         final updatedProfile = profile.copyWith(
            observacoesSaude: newObsSaude,
            observacoesPrac: newObsPrac,
            woundAnalysisHistory: currentWoundHistory,
         );

         await _profileService.saveOrUpdateProfile(updatedProfile.petName, updatedProfile.toJson());
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Limpeza concluída! App otimizado.'), backgroundColor: Colors.green));
         }
      } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nenhum dado antigo encontrado para limpeza.'), backgroundColor: Colors.blue));
         }
      }

    } catch (e) {
       debugPrint('Error cleaning data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Backup e Otimização', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gera um PDF completo com todo o histórico do pet (incluindo fotos e anexos) e permite limpar registros antigos para liberar espaço.',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (_petNames.isEmpty)
             const Text('Nenhum pet encontrado.', style: TextStyle(color: Colors.white54))
          else
             DropdownButtonFormField<String>(
               value: _selectedPetName,
               dropdownColor: Colors.grey[800],
               style: GoogleFonts.poppins(color: Colors.white),
               decoration: InputDecoration(
                 labelText: 'Selecione o Pet',
                 labelStyle: TextStyle(color: Colors.white54),
                 enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                 focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
               ),
               items: _petNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
               onChanged: (val) => setState(() => _selectedPetName = val),
             ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
          onPressed: _isLoading || _selectedPetName == null ? null : _performBackupAndOptimize,
          icon: _isLoading 
             ? Container(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
             : Icon(Icons.cleaning_services, color: Colors.black, size: 18),
          label: Text(_isLoading ? 'Processando...' : 'Gerar e Otimizar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
