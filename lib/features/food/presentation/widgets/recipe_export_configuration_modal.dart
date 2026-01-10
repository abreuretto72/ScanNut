import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_design.dart';
import '../../models/recipe_history_item.dart';

class RecipeExportConfigurationModal extends StatefulWidget {
  final List<RecipeHistoryItem> allItems;
  final Function(List<RecipeHistoryItem>) onGenerate;

  const RecipeExportConfigurationModal({
    Key? key,
    required this.allItems,
    required this.onGenerate,
  }) : super(key: key);

  @override
  State<RecipeExportConfigurationModal> createState() => _RecipeExportConfigurationModalState();
}

class _RecipeExportConfigurationModalState extends State<RecipeExportConfigurationModal> {
  DateTimeRange? _selectedDateRange;
  bool _manualSelectionMode = false;
  final Set<String> _selectedIds = {}; // Only used if manualSelectionMode is true

  // Computed property to get items filtered by DATE
  List<RecipeHistoryItem> get _dateFilteredItems {
    if (_selectedDateRange == null) return widget.allItems;
    return widget.allItems.where((item) {
      return item.timestamp.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
             item.timestamp.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))); // Inclusive end day
    }).toList();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _dateFilteredItems;
    final int count = _manualSelectionMode 
        ? filteredList.where((i) => _selectedIds.contains(i.id)).length 
        : filteredList.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(child: Text('Exportar Livro de Receitas', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                   IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              
              // 1. DATE FILTER
              InkWell(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppDesign.foodOrange, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _selectedDateRange == null 
                            ? 'Todo o período' 
                            : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
    
              // 2. MANUAL SELECTION TOGGLE
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Seleção Manual', style: GoogleFonts.poppins(color: Colors.white)),
                activeColor: AppDesign.foodOrange,
                value: _manualSelectionMode,
                onChanged: (val) {
                  setState(() {
                    _manualSelectionMode = val;
                    if (val && _selectedIds.isEmpty) {
                       _selectedIds.addAll(filteredList.map((i) => i.id));
                    }
                  });
                },
              ),
              
              // 3. LIST PREVIEW (If space allows, or if manual mode)
              if (_manualSelectionMode) ...[
                 const SizedBox(height: 10),
                 Text('Selecione os itens:', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                 const SizedBox(height: 8),
                 Container(
                   height: 200, 
                   decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                   child: filteredList.isEmpty 
                       ? const Center(child: Text('Nenhuma receita neste período.', style: TextStyle(color: Colors.white30)))
                       : ListView.builder(
                           shrinkWrap: true,
                           physics: const ClampingScrollPhysics(),
                           itemCount: filteredList.length,
                           itemBuilder: (context, index) {
                             final item = filteredList[index];
                             final isSelected = _selectedIds.contains(item.id);
                             return CheckboxListTile(
                               title: Text(item.recipeName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                               subtitle: Text(DateFormat('dd/MM HH:mm').format(item.timestamp), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                               value: isSelected,
                               activeColor: AppDesign.foodOrange,
                               checkColor: Colors.black,
                               dense: true,
                               onChanged: (v) {
                                 setState(() {
                                   if (v == true) {
                                     _selectedIds.add(item.id);
                                   } else {
                                     _selectedIds.remove(item.id);
                                   }
                                 });
                               },
                             );
                           },
                       ),
                 ),
              ],
              
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: count > 0 ? _onGeneratePressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.foodOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.white10,
                ),
                child: Text(
                  'Gerar PDF ($count receitas)',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: count > 0 ? Colors.white : Colors.white30),
                ),
              ),
              const SizedBox(height: 20), // Extra bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppDesign.foodOrange,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedDateRange = result;
        if (_manualSelectionMode) {
           _selectedIds.clear();
           final newFiltered = _dateFilteredItems;
           _selectedIds.addAll(newFiltered.map((e) => e.id));
        }
      });
    }
  }

  void _onGeneratePressed() {
    List<RecipeHistoryItem> finalItems = _dateFilteredItems;
    
    if (_manualSelectionMode) {
      finalItems = finalItems.where((i) => _selectedIds.contains(i.id)).toList();
    }
    
    Navigator.pop(context);
    widget.onGenerate(finalItems);
  }
}
