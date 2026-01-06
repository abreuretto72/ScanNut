import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/local_backup_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/theme/app_design.dart';
import '../../../l10n/app_localizations.dart';

class LocalBackupWidget extends StatefulWidget {
  const LocalBackupWidget({Key? key}) : super(key: key);

  @override
  State<LocalBackupWidget> createState() => _LocalBackupWidgetState();
}

class _LocalBackupWidgetState extends State<LocalBackupWidget> {
  bool _isExporting = false;
  bool _isSharing = false;
  bool _isImporting = false;
  final _backupService = LocalBackupService();

  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);
    final success = await _backupService.shareBackup();
    setState(() => _isSharing = false);

    if (mounted && !success) {
      // Se o usuário cancelar não mostramos erro, apenas se falhar tecnicamente
      // mas o share_plus geralmente não retorna erro se o usuário cancelar
    }
  }

  Future<void> _handleExport() async {
    // Solicitar permissões
    if (Theme.of(context).platform == TargetPlatform.android) {
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
      
      final status = await Permission.storage.request();
      if (status.isDenied && (await Permission.manageExternalStorage.isDenied)) {
        if (mounted) SnackBarHelper.showError(context, l10n.backupPermissionError);
        return;
      }
    }

    setState(() => _isExporting = true);
    try {
      final success = await _backupService.exportBackup();
      setState(() => _isExporting = false);

      if (mounted) {
        if (success) {
          // Mostrar Dialog de Sucesso
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey.shade900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.backupSuccessTitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                l10n.backupSuccessBody,
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.backupExcellent, style: GoogleFonts.poppins(color: const Color(0xFF00E676), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else {
          SnackBarHelper.showError(context, l10n.backupErrorGeneric);
        }
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: Text(l10n.backupTechnicalErrorTitle, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Text(
                l10n.backupTechnicalErrorBody(e.toString()),
                style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: GoogleFonts.poppins(color: Colors.white)),
              )
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleImport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          l10n.backupRestoreConfirmTitle,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.backupRestoreConfirmBody,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel, style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Restaurar', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isImporting = true);
    final success = await _backupService.importBackup();
    setState(() => _isImporting = false);

    if (mounted) {
      if (success) {
        SnackBarHelper.showSuccess(context, l10n.backupRestoreSuccess);
        // Opcionalmente força um reload/restart aqui se houver um utilitário pra isso
      } else {
        SnackBarHelper.showError(context, l10n.backupRestoreError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storage, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.backupLocalTitle,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.backupDescriptionText,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.indigoAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.backupSecurityNotice,
                    style: GoogleFonts.poppins(color: Colors.indigoAccent.shade100, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _handleShare,
                  icon: _isSharing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.share, size: 18),
                  label: Text(l10n.backupShare),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesign.primary.withOpacity(0.3), // Darker purple background
                    foregroundColor: AppDesign.primaryLight, // Light purple text
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _handleExport,
                  icon: _isExporting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_file, size: 18),
                  label: Text(l10n.backupSave),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesign.primaryLight.withOpacity(0.2), // Lighter purple background
                    foregroundColor: AppDesign.primaryLight, // Light purple text
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : _handleImport,
              icon: _isImporting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.file_download, size: 18),
              label: Text(l10n.backupImport),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.accent.withOpacity(0.25), // Accent purple background
                foregroundColor: AppDesign.primaryLight, // Light purple text
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
