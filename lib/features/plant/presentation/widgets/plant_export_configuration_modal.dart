import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_design.dart';
import '../../models/botany_history_item.dart';

class PlantExportConfigurationModal extends StatefulWidget {
  final List<BotanyHistoryItem> allItems;
  final Function(List<BotanyHistoryItem>) onGenerate;

  const PlantExportConfigurationModal({
    super.key,
    required this.allItems,
    required this.onGenerate,
  });

  @override
  State<PlantExportConfigurationModal> createState() =>
      _PlantExportConfigurationModalState();
}

class _PlantExportConfigurationModalState
    extends State<PlantExportConfigurationModal> {
  String _filterMode = 'all'; // 'all', 'toxic', 'safe', 'diseased', 'manual'
  final Set<String> _selectedIds = {};
  DateTimeRange? _selectedDateRange;

  List<BotanyHistoryItem> get _filteredItems {
    var items = widget.allItems;

    // Apply date filter first
    if (_selectedDateRange != null) {
      items = items.where((item) {
        return item.timestamp.isAfter(_selectedDateRange!.start
                .subtract(const Duration(seconds: 1))) &&
            item.timestamp
                .isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Then apply category filter
    switch (_filterMode) {
      case 'toxic':
        return items.where((item) => item.toxicityStatus != 'safe').toList();
      case 'safe':
        return items.where((item) => item.toxicityStatus == 'safe').toList();
      case 'diseased':
        return items
            .where((item) =>
                item.diseaseDiagnosis != null &&
                item.diseaseDiagnosis!.isNotEmpty)
            .toList();
      case 'manual':
        return items;
      case 'all':
      default:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredItems;
    final int count = _filterMode == 'manual'
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
                  Expanded(
                      child: Text('Exportar Inteligência Botânica',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold))),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),

              // DATE FILTER
              InkWell(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppDesign.plantGreen, size: 20),
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

              // FILTER OPTIONS
              Text('Filtrar por:',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),

              _buildFilterOption(
                  'Todas as Plantas', 'all', Icons.local_florist),
              const SizedBox(height: 8),
              _buildFilterOption(
                  'Apenas Tóxicas', 'toxic', Icons.warning_amber_rounded),
              const SizedBox(height: 8),
              _buildFilterOption(
                  'Apenas Seguras', 'safe', Icons.check_circle_outline),
              const SizedBox(height: 8),
              _buildFilterOption(
                  'Apenas com Doenças', 'diseased', Icons.healing),
              const SizedBox(height: 8),
              _buildFilterOption('Seleção Manual', 'manual', Icons.checklist),

              const SizedBox(height: 20),

              // MANUAL SELECTION LIST
              if (_filterMode == 'manual') ...[
                Text('Selecione os itens:',
                    style:
                        GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8)),
                  child: filteredList.isEmpty
                      ? const Center(
                          child: Text('Nenhuma planta encontrada.',
                              style: TextStyle(color: Colors.white30)))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final isSelected = _selectedIds.contains(item.id);
                            final isToxic = item.toxicityStatus != 'safe';
                            return CheckboxListTile(
                              title: Text(item.plantName,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13)),
                              subtitle: Row(
                                children: [
                                  Text(
                                      DateFormat('dd/MM HH:mm')
                                          .format(item.timestamp),
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 11)),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isToxic
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline,
                                    size: 14,
                                    color: isToxic
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                  ),
                                ],
                              ),
                              value: isSelected,
                              activeColor: AppDesign.plantGreen,
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
                const SizedBox(height: 20),
              ],

              ElevatedButton(
                onPressed: count > 0 ? _onGeneratePressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.plantGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.white10,
                ),
                child: Text(
                  'Gerar PDF ($count plantas)',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: count > 0 ? Colors.white : Colors.white30),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value, IconData icon) {
    final isSelected = _filterMode == value;
    return InkWell(
      onTap: () {
        setState(() {
          _filterMode = value;
          if (value == 'manual' && _selectedIds.isEmpty) {
            _selectedIds.addAll(_filteredItems.map((i) => i.id));
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppDesign.plantGreen.withValues(alpha: 0.2)
              : Colors.white10,
          border: Border.all(
            color: isSelected ? AppDesign.plantGreen : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppDesign.plantGreen : Colors.white54,
                size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? AppDesign.plantGreen : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
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
              primary: AppDesign.plantGreen,
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
        if (_filterMode == 'manual') {
          _selectedIds.clear();
          final newFiltered = _filteredItems;
          _selectedIds.addAll(newFiltered.map((e) => e.id));
        }
      });
    }
  }

  void _onGeneratePressed() {
    List<BotanyHistoryItem> finalItems = _filteredItems;

    if (_filterMode == 'manual') {
      finalItems =
          finalItems.where((i) => _selectedIds.contains(i.id)).toList();
    }

    // Caller handles closing
    widget.onGenerate(finalItems);
  }
}
