
import 'package:flutter/material.dart';
import '../services/session_guard.dart';
import 'screens/scan_walk_fullscreen.dart';

class PetRouter {
  PetRouter._();

  static Future<void> startScanWalk(BuildContext context) async {
    final guard = SessionGuard();
    final pet = await guard.validatePetSession(context);

    if (pet == null) {
      // Guard already handles error feedback
      return;
    }

    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ScanWalkFullscreen(activePet: pet),
        ),
      );
    }
  }
}
