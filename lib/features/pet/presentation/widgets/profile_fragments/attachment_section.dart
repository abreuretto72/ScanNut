import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';

class AttachmentSection extends StatelessWidget {
  final String title;
  final List<File> files;
  final VoidCallback onAdd;
  final Function(File) onDelete;

  const AttachmentSection({
    Key? key,
    required this.title,
    required this.files,
    required this.onAdd,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  if (files.isNotEmpty) 
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppDesign.petPink, shape: BoxShape.circle),
                      child: Text('${files.length}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              IconButton( // Small Add Button
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline, color: AppDesign.petPink, size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                tooltip: l10n.commonAdd,
              ),
            ],
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 90, 
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: files.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final file = files[index];
                  final isPdf = file.path.toLowerCase().endsWith('.pdf');
                  final filename = path.basenameWithoutExtension(file.path);
                  
                  // Clean name for display
                  final displayName = filename.replaceFirst(RegExp(r'^(identity|nutrition|health_\w+|gallery)_'), '');
                  
                  return InkWell(
                    onTap: () async {
                      try {
                        debugPrint('📂 Opening file: ${file.path}');
                        final result = await OpenFilex.open(file.path);

                        if (result.type != ResultType.done) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao abrir arquivo: ${result.message}'),
                              backgroundColor: AppDesign.error,
                            )
                          );
                        }
                      } catch (e) {
                        debugPrint('❌ Error opening file: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao abrir arquivo: $e'),
                            backgroundColor: AppDesign.error,
                          )
                        );
                      }
                    },
                    onLongPress: () => onDelete(file),
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPdf ? Icons.picture_as_pdf : Icons.image,
                                color: isPdf ? Colors.redAccent.withOpacity(0.7) : Colors.blueAccent.withOpacity(0.7),
                                size: 30,
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  displayName,
                                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          // Small delete icon on top right (alternative to long press for clarity)
                          Positioned(
                             top: 2, right: 2,
                             child: GestureDetector(
                                onTap: () => onDelete(file),
                                child: Container(
                                   padding: const EdgeInsets.all(2),
                                   decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                   child: const Icon(Icons.close, size: 10, color: Colors.white70),
                                ),
                             ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
