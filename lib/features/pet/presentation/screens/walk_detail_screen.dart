import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../services/reports/occurrences_report_engine.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/walk_models.dart';
import '../../models/pet_profile_extended.dart';

class WalkDetailScreen extends StatelessWidget {
  final WalkSession session;
  final PetProfileExtended? petProfile;

  const WalkDetailScreen({
    super.key,
    required this.session,
    this.petProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // 1. STICKY HEADER WITH MINI MAP
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A1A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildMapHeader(context),
            ),
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.picture_as_pdf, color: AppDesign.petPink),
                onPressed: () async {
                  final pdf = await OccurrencesReportEngine.generateWalkReport(
                    profile: petProfile!,
                    session: session,
                    l10n: l10n,
                  );
                  await Printing.layoutPdf(onLayout: (format) => pdf.save());
                },
              ),
            ],
          ),

          // 2. STATS OVERVIEW
          SliverToBoxAdapter(
            child: _buildStatsBanner(l10n),
          ),

          // 3. TIMELINE OF EVENTS
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final event = session.events[index];
                  return _buildTimelineItem(
                      context, event, index == session.events.length - 1, l10n);
                },
                childCount: session.events.length,
              ),
            ),
          ),

          // EMPTY STATE
          if (session.events.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  "Nenhum evento registrado",
                  style: GoogleFonts.poppins(color: Colors.white38),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildMapHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF151515),
      child: Stack(
        children: [
          // Mock Path Drawing
          CustomPaint(
            size: Size.infinite,
            painter: _DetailsMapPainter(),
          ),
          // User Pulsing dot at start/end
          const Center(
            child: Icon(Icons.location_on, color: AppDesign.petPink, size: 30),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Title
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(session.startTime),
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "${DateFormat('HH:mm').format(session.startTime)} - ${session.endTime != null ? DateFormat('HH:mm').format(session.endTime!) : '--:--'}",
                  style:
                      GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatsBanner(AppLocalizations l10n) {
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : Duration.zero;
    final durStr = "${duration.inMinutes}m ${duration.inSeconds % 60}s";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: const Border.symmetric(
            horizontal: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDetailStat(l10n.scanWalkDistance,
              "${session.distanceKm.toStringAsFixed(2)} km", Icons.route),
          _buildDetailStat(l10n.scanWalkDuration, durStr, Icons.timer_outlined),
          _buildDetailStat("Calorias", "${session.caloriesBurned} kcal",
              Icons.local_fire_department),
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppDesign.petPink.withValues(alpha: 0.5), size: 20),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: Colors.white30, fontSize: 10, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, WalkEvent event, bool isLast,
      AppLocalizations l10n) {
    final config = _getEventConfig(event.type, l10n);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator & Line
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: config.color.withValues(alpha: 0.3)),
                ),
                child: Icon(config.icon, color: config.color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.white10,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(config.label,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(DateFormat('HH:mm').format(event.timestamp),
                          style: GoogleFonts.robotoMono(
                              color: Colors.white30, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description / Audio Transcript
                  if (event.description != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        event.description!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ),

                  // Bristol Score Badge
                  if (event.type == WalkEventType.poo &&
                      event.bristolScore != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _buildBristolBadge(event.bristolScore!, l10n),
                    ),

                  // Photos
                  if (event.photoPath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildPhotoGallery(context, event.photoPath!),
                    ),

                  // Audio Visualizer Mock (if has audio)
                  if (event.audioPath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildAudioControl(event.audioPath!),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBristolBadge(int score, AppLocalizations l10n) {
    // 3, 4, 5 = healthy (Green)
    final bool isHealthy = score >= 3 && score <= 5;
    final Color color = isHealthy ? Colors.greenAccent : Colors.redAccent;
    final String label = isHealthy
        ? l10n.walkBristolIdeal
        : (score <= 2 ? l10n.walkBristolConstipated : l10n.walkBristolLiquid);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, color: color, size: 14),
          const SizedBox(width: 6),
          Text("Bristol $score: $label",
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(BuildContext context, String path) {
    return GestureDetector(
      onTap: () => _showImageFullscreen(context, path),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(path),
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 100,
            color: Colors.white.withValues(alpha: 0.05),
            child: const Icon(Icons.broken_image, color: Colors.white24),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioControl(String path) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_arrow, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.white12]),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text("Gravação de voz",
              style: TextStyle(color: Colors.blueAccent, fontSize: 11)),
        ],
      ),
    );
  }

  void _showImageFullscreen(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black54),
                ),
              ),
            ),
            Center(child: Image.file(File(path), fit: BoxFit.contain)),
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context)),
            )
          ],
        ),
      ),
    );
  }

  void _showPdfPlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              "Relatório PDF do Passeio (9º Relatório) em desenvolvimento...")),
    );
  }

  _EventConfig _getEventConfig(WalkEventType type, AppLocalizations l10n) {
    switch (type) {
      case WalkEventType.pee:
        return _EventConfig(l10n.walkXixi, Icons.water_drop, Colors.blue);
      case WalkEventType.poo:
        return _EventConfig(l10n.walkFezes, Icons.circle, Colors.brown);
      case WalkEventType.water:
        return _EventConfig(l10n.walkAgua, Icons.local_drink, Colors.lightBlue);
      case WalkEventType.friend:
        return _EventConfig(l10n.walkAmigo, Icons.person_add, Colors.purple);
      case WalkEventType.bark:
        return _EventConfig(l10n.walkLatido, Icons.graphic_eq, Colors.green);
      case WalkEventType.hazard:
        return _EventConfig(
            l10n.walkPerigo, Icons.warning_amber, Colors.orange);
      case WalkEventType.fight:
        return _EventConfig(l10n.walkBrigas, Icons.bolt, Colors.red);
      default:
        return _EventConfig("Evento", Icons.pets, Colors.grey);
    }
  }
}

class _EventConfig {
  final String label;
  final IconData icon;
  final Color color;
  _EventConfig(this.label, this.icon, this.color);
}

class _DetailsMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppDesign.petPink.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.2,
        size.width * 0.8, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.9,
        size.width * 0.3, size.height * 0.7);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
