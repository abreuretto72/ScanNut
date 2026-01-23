import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import '../../../../../core/theme/app_design.dart';
import '../../../../../l10n/app_localizations.dart';

class AttachmentSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<File> files;
  final VoidCallback onAdd;
  final Function(File) onDelete;

  const AttachmentSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.files,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bool hasFiles = files.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasFiles 
            ? Colors.green.withValues(alpha: 0.1) 
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFiles 
              ? Colors.green.withValues(alpha: 0.2) 
              : Colors.white10
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasFiles ? Icons.check_circle : Icons.attach_file, 
                          color: hasFiles ? Colors.greenAccent : Colors.white54, 
                          size: 16
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title, 
                            style: GoogleFonts.poppins(
                              color: hasFiles ? Colors.white : Colors.white70, 
                              fontSize: 13, 
                              fontWeight: FontWeight.w600
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasFiles) 
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.3), 
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Text(
                              '${files.length}', 
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                            ),
                          ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton( // Small Add Button
                onPressed: onAdd,
                icon: Icon(
                  hasFiles ? Icons.add_circle : Icons.add_circle_outline, 
                  color: hasFiles ? Colors.greenAccent : AppDesign.petPink, 
                  size: 22
                ),
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
                        color: Colors.white.withValues(alpha: 0.03),
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
                                color: isPdf ? Colors.redAccent.withValues(alpha: 0.7) : Colors.blueAccent.withValues(alpha: 0.7),
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
                                   decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
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
