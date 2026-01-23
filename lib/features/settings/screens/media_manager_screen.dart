import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_design.dart';
import '../../../core/utils/snackbar_helper.dart';

class MediaManagerScreen extends StatefulWidget {
  const MediaManagerScreen({super.key});

  @override
  State<MediaManagerScreen> createState() => _MediaManagerScreenState();
}

class _MediaManagerScreenState extends State<MediaManagerScreen> {
  bool _isLoading = true;
  List<FileSystemEntity> _files = [];
  final Set<String> _selectedFiles = {};

  @override
  void initState() {
    super.initState();
    _scanMediaFiles();
  }

  Future<void> _scanMediaFiles() async {
    setState(() => _isLoading = true);
    
    final List<File> allFiles = [];
    final Set<String> processedPaths = {};

    try {
      // 1. Define roots
      final roots = <Directory>[];
      try { roots.add(await getApplicationDocumentsDirectory()); } catch(e) {/* ignore */}
      try {
         final ext = await getExternalStorageDirectory();
         if(ext != null) roots.add(ext); 
      } catch(e) {/* ignore */}

      // 2. Define targets
      final targets = ['Pets', 'Food', 'Plants', 'Vault', 'media_vault', 'scannut_media', 'PetPhotos', 'PlantAnalyses', 'ExamsVault'];

      // 3. Recursive Helper
      Future<void> scanDir(Directory dir) async {
         try {
             if(await dir.exists()) {
                 final entities = dir.listSync(recursive: true); // Recursive
                 for(var e in entities) {
                     if(e is File) {
                        final path = e.path.toLowerCase();
                        if(path.endsWith('.jpg') || path.endsWith('.png') || path.endsWith('.jpeg') || path.endsWith('.pdf')) {
                            if(!processedPaths.contains(e.path)) {
                               allFiles.add(e);
                               processedPaths.add(e.path);
                            }
                        }
                     }
                 }
             }
         } catch(e) { /* Permission or access denied */ }
      }

      // 4. Execute Scan
      for(var root in roots) {
          // Scan specific subfolders
          for(var target in targets) {
             await scanDir(Directory('${root.path}/$target'));
          }
          // Also scan root recursively? 
          // If we scan root recursively we might hit cache or build artifacts.
          // Let's stick to root + targets as primary heuristic. 
          // If the previous simple scan failed, a recursive root scan is safer but slower.
          // Let's do a shallow scan of root for loose files
          try {
             final entities = root.listSync();
             for(var e in entities) {
                 if(e is File) {
                    final path = e.path.toLowerCase();
                    if((path.endsWith('.jpg') || path.endsWith('.png') || path.endsWith('.jpeg') || path.endsWith('.pdf')) 
                        && !processedPaths.contains(e.path)) {
                        allFiles.add(e);
                        processedPaths.add(e.path);
                    }
                 }
             }
          } catch(e) {}
      }
      
    } catch(e) {
       debugPrint('Scan Error: $e');
    }

    if(mounted) {
       setState(() {
         _files = allFiles;
         _isLoading = false;
       });
    }
  }

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return '?';
    }
  }
  
  void _toggleSelection(String path) {
     setState(() {
        if (_selectedFiles.contains(path)) {
           _selectedFiles.remove(path);
        } else {
           _selectedFiles.add(path);
        }
     });
  }

  Future<void> _deleteSelected() async {
     if (_selectedFiles.isEmpty) return;
     
     final count = _selectedFiles.length;
     final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
           backgroundColor: AppDesign.surfaceDark,
           title: Text('Excluir $count arquivos?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
           content: Text('Os registros na agenda NÃO serão apagados, mas os arquivos físicos serão removidos para liberar espaço.', style: GoogleFonts.poppins(color: Colors.white70)),
           actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              TextButton(
                 onPressed: () => Navigator.pop(context, true),
                 child: Text('EXCLUIR', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
           ],
        ),
     );
     
     if (confirm == true) {
        for (var path in _selectedFiles) {
           try {
              final file = File(path);
              if (await file.exists()) await file.delete();
           } catch (e) {
              debugPrint('Error deleting $path: $e');
           }
        }
        
        if (mounted) SnackBarHelper.showSuccess(context, 'Espaço liberado com sucesso!');
        _selectedFiles.clear();
        _scanMediaFiles();
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
         backgroundColor: AppDesign.surfaceDark,
         title: Text('Gerenciar Mídia', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
         leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
         actions: [
            IconButton(
               icon: const Icon(Icons.refresh, color: Colors.white),
               onPressed: _scanMediaFiles,
               tooltip: 'Atualizar Lista',
            ),
            if (_selectedFiles.isNotEmpty)
              Container(
                 margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                 child: FloatingActionButton.extended(
                    onPressed: _deleteSelected,
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    label: Text('${_selectedFiles.length}'),
                    icon: const Icon(Icons.delete_outline),
                    elevation: 0,
                 ),
              )
         ],
      ),
      body: _isLoading 
         ? Center(
             child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const CircularProgressIndicator(color: AppDesign.accent),
                   const SizedBox(height: 16),
                   Text('Escaneando anexos e arquivos...', style: GoogleFonts.poppins(color: Colors.white70)),
                ],
             ),
           )
         : _files.isEmpty
            ? Center(child: Text('Nenhum arquivo físico encontrado para gerenciar', style: GoogleFonts.poppins(color: Colors.white54)))
            : GridView.builder(
               padding: const EdgeInsets.all(12),
               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
               ),
               itemCount: _files.length,
               itemBuilder: (context, index) {
                  final file = _files[index] as File;
                  final isSelected = _selectedFiles.contains(file.path);
                  
                  return GestureDetector(
                     onLongPress: () => _toggleSelection(file.path),
                     onTap: () {
                        if (_selectedFiles.isNotEmpty) _toggleSelection(file.path);
                        // else open preview (omitted for now)
                     },
                     child: Stack(
                        fit: StackFit.expand,
                        children: [
                           ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(file, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey.shade900, child: const Icon(Icons.insert_drive_file, color: Colors.white54))),
                           ),
                           if (isSelected)
                              Container(
                                 decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red, width: 2),
                                 ),
                                 child: const Center(child: Icon(Icons.check_circle, color: Colors.red, size: 32)),
                              ),
                           Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                 decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                 child: Text(_getFileSize(file), style: const TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                           ),
                        ],
                     ),
                  );
               },
            ),
    );
  }
}
