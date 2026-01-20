import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/widgets/cumulative_observations_field.dart';

class GalleryFragment extends StatelessWidget {
  final List<File> docs;
  final File? profileImage;
  final String observacoesGaleria;
  
  final Function(File) onDeleteAttachment;
  final VoidCallback onAddAttachment;
  final Function(String) onObservacoesChanged;
  final Widget actionButtons;

  const GalleryFragment({
    Key? key,
    required this.docs,
    this.profileImage,
    required this.observacoesGaleria,
    required this.onDeleteAttachment,
    required this.onAddAttachment,
    required this.onObservacoesChanged,
    required this.actionButtons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasProfile = profileImage != null && profileImage!.existsSync();
    final totalCount = docs.length + (hasProfile ? 1 : 0);
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          '📸 ${l10n.petGallery}',
          style: GoogleFonts.poppins(color: AppDesign.petPink, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.petEmptyGalleryDesc,
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 20),

        if (totalCount == 0)
          Container(
            padding: const EdgeInsets.all(40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Icon(Icons.perm_media_outlined, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                Text(l10n.petEmptyGallery, style: GoogleFonts.poppins(color: Colors.white38)),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: totalCount,
            itemBuilder: (context, index) {
              File file;
              bool isProfile = false;
              
              if (hasProfile && index == 0) {
                 file = profileImage!;
                 isProfile = true;
              } else {
                 file = docs[index - (hasProfile ? 1 : 0)];
              }
              
              final isVideo = file.path.toLowerCase().endsWith('.mp4') || file.path.toLowerCase().endsWith('.mov');
              
              return InkWell(
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isProfile ? 'Foto de Perfil' : (l10n.commonFilePrefix + path.basename(file.path)))));
                },
                onLongPress: isProfile ? null : () => onDeleteAttachment(file),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppDesign.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    image: !isVideo ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null,
                    border: isProfile ? Border.all(color: AppDesign.petPink, width: 2) : null,
                  ),
                  child: Stack(
                    children: [
                       if (isVideo) 
                         const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32)),
                       if (isProfile)
                         Positioned(
                           bottom: 0, left: 0, right: 0,
                           child: Container(
                             color: AppDesign.petPink.withOpacity(0.8),
                             padding: const EdgeInsets.symmetric(vertical: 2),
                             child: const Text('Perfil', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                           ),
                         ),
                    ],
                  ),
                ),
              );
            },
          ),
        
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAddAttachment,
            icon: const Icon(Icons.add_a_photo),
            label: Text(l10n.petAddToGallery),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: const BorderSide(color: AppDesign.petPink),
              foregroundColor: AppDesign.petPink,
            ),
          ),
        ),

        const SizedBox(height: 24),
        CumulativeObservationsField(
          sectionName: 'Galeria',
          initialValue: observacoesGaleria,
          onChanged: onObservacoesChanged,
          icon: Icons.photo_library,
          accentColor: Colors.purple,
        ),

         actionButtons,
      ],
      ),
    );
  }
}
