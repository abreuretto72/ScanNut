import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../models/walk_models.dart';
import '../../../models/pet_profile_extended.dart';
import '../../../services/scan_walk_service.dart';
import '../../screens/walk_detail_screen.dart';

class WalksFragment extends StatefulWidget {
  final PetProfileExtended petProfile;

  const WalksFragment({
    super.key,
    required this.petProfile,
  });

  @override
  State<WalksFragment> createState() => _WalksFragmentState();
}

class _WalksFragmentState extends State<WalksFragment> {
  final ScanWalkService _walkService = ScanWalkService();
  List<WalkSession>? _sessions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    // 🛡️ [LEI DE FERRO] Isola dados via PetID
    final history = await _walkService.getHistoryForPet(widget.petProfile.id);

    if (mounted) {
      setState(() {
        _sessions = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppDesign.petPink));
    }

    if (_sessions == null || _sessions!.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _sessions!.length,
      itemBuilder: (context, index) {
        return _buildWalkCard(_sessions![index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_walk,
              size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "Nenhum passeio registrado ainda.",
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkCard(WalkSession session) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(session.startTime);
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : Duration.zero;

    // Count event types for badges
    final Map<WalkEventType, int> counts = {};
    for (var e in session.events) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WalkDetailScreen(
                session: session, petProfile: widget.petProfile),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppDesign.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // MINI MAP AREA
            _buildMiniMapHeader(session),

            // STATS & BADGES
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateStr,
                          style: GoogleFonts.robotoMono(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const Icon(Icons.chevron_right, color: Colors.white30),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatItem(Icons.timer_outlined, "${duration.inMinutes}m"),
                      const SizedBox(width: 16),
                      _StatItem(Icons.route,
                          "${session.distanceKm.toStringAsFixed(2)} km"),
                      const Spacer(),
                      _StatItem(Icons.local_fire_department,
                          "${session.caloriesBurned} kcal",
                          color: Colors.orangeAccent),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // EVENT BADGES
                  if (session.events.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: counts.entries.map((entry) {
                        return _buildEventBadge(entry.key, entry.value, l10n);
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMapHeader(WalkSession session) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(double.infinity, 100),
            painter: _MiniMapPainter(),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Icon(Icons.location_on,
                color: AppDesign.petPink.withValues(alpha: 0.5), size: 16),
          )
        ],
      ),
    );
  }

  Widget _buildEventBadge(
      WalkEventType type, int count, AppLocalizations l10n) {
    Color color = Colors.grey;
    IconData icon = Icons.pets;

    switch (type) {
      case WalkEventType.pee:
        color = Colors.blue;
        icon = Icons.water_drop;
        break;
      case WalkEventType.poo:
        color = Colors.brown;
        icon = Icons.circle;
        break;
      case WalkEventType.water:
        color = Colors.lightBlue;
        icon = Icons.local_drink;
        break;
      case WalkEventType.friend:
        color = Colors.purple;
        icon = Icons.person_add;
        break;
      case WalkEventType.bark:
        color = Colors.green;
        icon = Icons.graphic_eq;
        break;
      case WalkEventType.hazard:
        color = Colors.orange;
        icon = Icons.warning_amber;
        break;
      case WalkEventType.fight:
        color = Colors.red;
        icon = Icons.bolt;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(count.toString(),
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatItem(this.icon, this.label, {this.color = Colors.white54});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height * 0.2);
    path.lineTo(size.width * 0.6, size.height * 0.8);
    path.lineTo(size.width * 0.9, size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
