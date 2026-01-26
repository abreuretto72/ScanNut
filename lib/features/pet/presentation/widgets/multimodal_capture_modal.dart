import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/walk_models.dart';
import '../../services/friend_service.dart';
import './friend_registration_form.dart';

/// 🎯 Multimodal Capture Modal (Enhanced with Bristol Scale and Manual Friend Registration)
class MultimodalCaptureModal extends StatefulWidget {
  final WalkEventType eventType;
  final Function(Map<String, dynamic>?) onCapturePhoto;
  final Function(Map<String, dynamic>?) onRecordVoice;
  final Function(Map<String, dynamic>?) onCaptureSound;
  final Function(Map<String, dynamic>?) onQuickLog;
  final bool isRecording;

  const MultimodalCaptureModal({
    super.key,
    required this.eventType,
    required this.onCapturePhoto,
    required this.onRecordVoice,
    required this.onCaptureSound,
    required this.onQuickLog,
    this.isRecording = false,
  });

  @override
  State<MultimodalCaptureModal> createState() => _MultimodalCaptureModalState();
}

class _MultimodalCaptureModalState extends State<MultimodalCaptureModal> {
  double _bristolScore = 3.0; // Normal/Ideal start
  String? _manualDescription;

  Map<String, dynamic> get _currentData {
    final data = <String, dynamic>{};
    if (widget.eventType == WalkEventType.poo) {
      data['bristol_score'] = _bristolScore.toInt();
    }
    if (_manualDescription != null) {
      data['description'] = _manualDescription;
    }
    return data;
  }

  void _showManualFriendForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FriendRegistrationForm(
        onSave: (friend) async {
          final service = FriendService();
          await service.init();
          await service.saveFriend(friend);
          
          if (mounted) {
            setState(() {
              _manualDescription =
                  'Manual: ${friend.name} (${friend.breed}) - Tutor: ${friend.ownerName}';
            });



            // Registra os dados mas mantém o modal aberto para o usuário ver ou adicionar foto
            widget.onQuickLog(_currentData);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.friendSaveSuccess),
                backgroundColor: AppDesign.success,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eventLabel = _getEventLabel(context, widget.eventType);
    final eventColor = _getEventColor(widget.eventType);
    final eventIcon = _getEventIcon(widget.eventType);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: AppDesign.surfaceDark.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border:
                Border.all(color: eventColor.withValues(alpha: 0.5), width: 2),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: eventColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: eventColor),
                      ),
                      child: Icon(eventIcon, color: eventColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registrar $eventLabel',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.loadingMsgWait.replaceAll('...', ''), // "Escolha como documentar" localized or similar
                            style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 💩 PROMPT FECES (Bristol Scale)
                if (widget.eventType == WalkEventType.poo) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.brown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.brown.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text("${l10n.walkBristolScore}: ${_bristolScore.toInt()}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Slider(
                          value: _bristolScore,
                          min: 1,
                          max: 7,
                          divisions: 6,
                          activeColor: Colors.brown,
                          inactiveColor: Colors.white10,
                          label: _getBristolLabel(context, _bristolScore.toInt()),
                          onChanged: (val) =>
                              setState(() => _bristolScore = val),
                        ),
                        Text(
                          _getBristolLabel(context, _bristolScore.toInt()),
                          style:
                              TextStyle(color: Colors.brown[200], fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Capture Options
                if (widget.eventType == WalkEventType.friend) ...[
                  // 1. Tirar foto do amigo
                  _buildCaptureOption(
                    icon: Icons.camera_alt,
                    label: l10n.walkFriendPhoto,
                    description: 'Evidência visual do encontro',
                    color: Colors.blue,
                    onTap: () {
                      // Navigator.pop(context); // Mantém o modal aberto para retorno
                      widget.onCapturePhoto(_currentData);
                    },
                  ),
                  const SizedBox(height: 12),
                  // 2. Cadastrar o amigo e tutor
                  _buildCaptureOption(
                    icon: Icons.edit_note,
                    label: l10n.walkFriendManualFull,
                    description: l10n.walkFriendManualDesc,
                    color: Colors.pinkAccent,
                    onTap: _showManualFriendForm,
                  ),
                  const SizedBox(height: 12),
                  // 3. Ditar ocorrências
                  _buildCaptureOption(
                    icon: Icons.mic,
                    label: l10n.walkFriendVoice,
                    description: _getVoiceDescription(context, widget.eventType),
                    color: Colors.purple,
                    onTap: () {
                      // Navigator.pop(context); // Mantém o modal aberto para retorno
                      widget.onRecordVoice(_currentData);
                    },
                    isRecording: widget.isRecording,
                  ),
                  const SizedBox(height: 12),
                  // 4. Gravar latidos / miados do amigo
                  _buildCaptureOption(
                    icon: Icons.graphic_eq,
                    label: l10n.walkFriendSound,
                    description: l10n.walkAnalysisBark,
                    color: Colors.orange,
                    onTap: () {
                      // Navigator.pop(context); // Mantém o modal aberto para retorno
                      widget.onCaptureSound(_currentData);
                    },
                  ),
                ] else ...[
                  // Standard Generic Options
                  _buildCaptureOption(
                    icon: Icons.camera_alt,
                    label: l10n.btn_capture_photo,
                    description: 'Evidência visual do evento',
                    color: Colors.blue,
                    onTap: () {
                      // Navigator.pop(context); // Mantém o modal aberto para retorno
                      widget.onCapturePhoto(_currentData);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCaptureOption(
                    icon: Icons.mic,
                    label: l10n.btn_voice_note,
                    description: _getVoiceDescription(context, widget.eventType),
                    color: Colors.purple,
                    onTap: () {
                      // Navigator.pop(context); // Mantém o modal aberto para retorno
                      widget.onRecordVoice(_currentData);
                    },
                    isRecording: widget.isRecording,
                  ),
                  const SizedBox(height: 12),
                  _buildCaptureOption(
                    icon: Icons.graphic_eq,
                    label: l10n.btn_capture_sound,
                    description: widget.eventType == WalkEventType.bark
                        ? l10n.walkAnalysisBark
                        : 'Captura de áudio ambiente',
                    color: Colors.orange,
                    onTap: () {
                      // Navigator.pop(context); // Mantém o modal aberto para retorno
                      widget.onCaptureSound(_currentData);
                    },
                  ),
                ],

                const Divider(color: Colors.white10, height: 32),

                // Quick Log Option
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Aqui o pop é necessário para finalizar
                      widget.onQuickLog(_currentData);
                    },
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: Text(l10n.btn_quick_reg),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureOption({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
    bool isRecording = false,
  }) {
    return InkWell(
      onTap: isRecording ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRecording
              ? Colors.red.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecording ? Colors.red : color.withValues(alpha: 0.3),
            width: isRecording ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRecording
                    ? Colors.red.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isRecording ? Colors.red : color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isRecording ? Icons.fiber_manual_record : Icons.arrow_forward_ios,
              color: isRecording ? Colors.red : Colors.white30,
              size: isRecording ? 20 : 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getBristolLabel(BuildContext context, int score) {
    final l10n = AppLocalizations.of(context)!;
    switch (score) {
      case 1:
        return "Tipo 1: Caroços duros separados";
      case 2:
        return "Tipo 2: Forma de salsicha, encaroçado";
      case 3:
        return "Tipo 3: Salsicha com fissuras (Ideal)";
      case 4:
        return "Tipo 4: Salsicha lisa e mole (Ideal)";
      case 5:
        return "Tipo 5: Pedaços moles com bordas nítidas";
      case 6:
        return "Tipo 6: Pedaços aerados, bordas irregulares";
      case 7:
        return "Tipo 7: Líquido, sem pedaços sólidos";
      default:
        return "";
    }
  }

  String _getVoiceDescription(BuildContext context, WalkEventType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case WalkEventType.friend:
        return l10n.walkVoicePromptFriend;
      case WalkEventType.fight:
        return l10n.walkVoicePromptFight;
      default:
        return 'Descreva o que observou';
    }
  }

  String _getEventLabel(BuildContext context, WalkEventType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case WalkEventType.pee:
        return l10n.walkXixi;
      case WalkEventType.poo:
        return l10n.walkFezes;
      case WalkEventType.water:
        return l10n.walkAgua;
      case WalkEventType.others:
        return l10n.walkOutros;
      case WalkEventType.friend:
        return l10n.walkAmigo;
      case WalkEventType.bark:
        return l10n.walkLatido;
      case WalkEventType.hazard:
        return l10n.walkPerigo;
      case WalkEventType.fight:
        return l10n.walkBrigas;
      default:
        return 'Evento';
    }
  }

  Color _getEventColor(WalkEventType type) {
    switch (type) {
      case WalkEventType.pee:
        return Colors.yellow;
      case WalkEventType.poo:
        return Colors.brown;
      case WalkEventType.water:
        return Colors.blue;
      case WalkEventType.others:
        return Colors.teal;
      case WalkEventType.friend:
        return Colors.purple;
      case WalkEventType.bark:
        return Colors.red;
      case WalkEventType.hazard:
        return Colors.orange;
      case WalkEventType.fight:
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(WalkEventType type) {
    switch (type) {
      case WalkEventType.pee:
        return Icons.water_drop_outlined;
      case WalkEventType.poo:
        return Icons.circle;
      case WalkEventType.water:
        return Icons.local_drink;
      case WalkEventType.others:
        return Icons.more_horiz;
      case WalkEventType.friend:
        return Icons.person_add;
      case WalkEventType.bark:
        return Icons.graphic_eq;
      case WalkEventType.hazard:
        return Icons.warning;
      case WalkEventType.fight:
        return Icons.pets;
      default:
        return Icons.event;
    }
  }
}
