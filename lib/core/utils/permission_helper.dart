import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

class PermissionHelper {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await _showRationaleDialog(
        context,
        l10n.permissionCameraDisclosureTitle,
        l10n.permissionCameraDisclosureBody,
        Icons.camera_alt,
      );

      if (confirmed) {
        final newStatus = await Permission.camera.request();
        return newStatus.isGranted;
      }
    }
    return false;
  }

  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await _showRationaleDialog(
        context,
        l10n.permissionMicrophoneDisclosureTitle,
        l10n.permissionMicrophoneDisclosureBody,
        Icons.mic,
      );

      if (confirmed) {
        final newStatus = await Permission.microphone.request();
        return newStatus.isGranted;
      }
    }
    return false;
  }

  static Future<bool> _showRationaleDialog(
    BuildContext context,
    String title,
    String body,
    IconData icon,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF00E676), width: 1),
            ),
            icon: Icon(icon, color: const Color(0xFF00E676), size: 40),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l10n.petNamePromptCancel,
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  l10n.continueButton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
