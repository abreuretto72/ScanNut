import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:scannut/l10n/app_localizations.dart';
import '../../../../core/widgets/pdf_action_button.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/widgets/pdf_preview_screen.dart';
import '../../services/pet_profile_service.dart';
import '../../services/meal_plan_service.dart';
import 'edit_pet_form.dart'; // Import to link back

class WeeklyMenuScreen extends StatefulWidget {
  final List<Map<String, dynamic>> currentWeekPlan;
  final String? generalGuidelines;
  final String petName;
  final String raceName;

  const WeeklyMenuScreen({Key? key, required this.currentWeekPlan, this.generalGuidelines, required this.petName, required this.raceName}) : super(key: key);

  @override
  State<WeeklyMenuScreen> createState() => _WeeklyMenuScreenState();
}

class _WeeklyMenuScreenState extends State<WeeklyMenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Buckets
  List<Map<String, dynamic>> _pastPlan = [];
  List<Map<String, dynamic>> _currentPlan = [];
  List<Map<String, dynamic>> _nextPlan = [];
  String? _guidelines;
  String? _dietType;
  String? _kcalTarget;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Start at Current
    _loadMenuFromService();
  }

  DateTime? _savedStartDate;
  DateTime? _savedEndDate;

  Future<void> _loadMenuFromService() async {
      setState(() => _isLoading = true);
      try {
          final service = PetProfileService();
          await service.init();
          final profile = await service.getProfile(widget.petName.trim());
          
          List<Map<String, dynamic>> allItems = [];
          
          if (profile != null && profile['data'] != null) {
              final pData = profile['data'];
              _dietType = pData['tipo_dieta']?.toString() ?? AppLocalizations.of(context)!.petNotOffice;
              
              if (pData['nutricao'] != null && pData['nutricao']['metaCalorica'] != null) {
                  final meta = pData['nutricao']['metaCalorica'];
                  // Pega a meta de adulto como padrão ou a primeira disponível
                  _kcalTarget = meta['kcal_adulto'] ?? meta['kcal_filhote'] ?? meta['kcal_senior'];
              }

              if (pData != null) {
                  final rawPlan = (pData['plano_semanal'] ?? pData['raw_analysis']?['plano_semanal']) as List?;
                  _guidelines = (pData['orientacoes_gerais'] ?? pData['raw_analysis']?['orientacoes_gerais']) as String?;
                  
                  // Contextual dates
                  final startStr = pData['data_inicio_semana'] ?? pData['raw_analysis']?['data_inicio_semana'];
                  final endStr = pData['data_fim_semana'] ?? pData['raw_analysis']?['data_fim_semana'];
                  
                  if (startStr != null) _savedStartDate = DateTime.tryParse(startStr);
                  if (endStr != null) _savedEndDate = DateTime.tryParse(endStr);

                  if (rawPlan != null) {
                      allItems = rawPlan.map((e) => Map<String, dynamic>.from(e)).toList();
                  }
              }
          }
          
          if (allItems.isEmpty && widget.currentWeekPlan.isNotEmpty) {
             allItems = widget.currentWeekPlan.map((e) => Map<String, dynamic>.from(e)).toList();
             _guidelines ??= widget.generalGuidelines;
          }

          // AGORA: Suplementar com dados do MealPlanService (Usando petId = petName norm)
          try {
              final mealPlanService = MealPlanService();
              await mealPlanService.init();
              final historicalPlans = await mealPlanService.getPlansForPet(widget.petName.trim().toLowerCase());
              
              for (var plan in historicalPlans) {
                  // Converter model para o formato Map esperado pela UI/Export
                  for (var m in plan.meals) {
                      final itemDate = plan.startDate.add(Duration(days: m.dayOfWeek - 1));
                      final dayKey = DateFormat('dd/MM').format(itemDate);
                      
                      // Só adicionar se ainda não tivermos esse dia no allItems ou for de semana diferente
                      // Simplificação: vamos adicionar todos os históricos que não conflitem exatamente
                      allItems.add({
                          'dia': "${DateFormat('EEEE', AppLocalizations.of(context)!.localeName).format(itemDate)} - $dayKey",
                          'refeicoes': [
                              {'hora': m.time, 'titulo': m.title, 'descricao': m.description}
                          ],
                          'beneficio': m.benefit,
                      });
                  }
              }
          } catch (e) {
              debugPrint('Error loading historical plans: $e');
          }

          _splitPlanByWeeks(allItems);

      } catch (e) {
          debugPrint('Error loading menu: $e');
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
  }

  void _splitPlanByWeeks(List<Map<String, dynamic>> allItems) {
      _pastPlan = [];
      _currentPlan = [];
      _nextPlan = [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Calculate Current Week boundaries (Monday to Sunday)
      final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
      
      // FALLBACK: Se não temos data salva no perfil, assumimos que o cardápio atual começa na segunda desta semana
      _savedStartDate ??= currentWeekStart;
      
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      
      final List<Map<String, dynamic>> sortedItems = [];
      
      for (int i = 0; i < allItems.length; i++) {
          final item = Map<String, dynamic>.from(allItems[i]);
          String diaOriginal = item['dia']?.toString() ?? '';
          
          DateTime? itemDate;
          
          // 1. Tentar extrair de DD/MM no campo 'dia'
          final regex = RegExp(r'(\d{1,2})\s*/\s*(\d{1,2})');
          final match = regex.firstMatch(diaOriginal);
          
          if (match != null) {
              final day = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              int year = today.year;
              
              if (_savedStartDate != null) {
                  year = _savedStartDate!.year;
                  if (month < _savedStartDate!.month && (_savedStartDate!.month - month) > 6) year++;
                  if (month > _savedStartDate!.month && (month - _savedStartDate!.month) > 6) year--;
              } else {
                  if (today.month == 12 && month == 1) year++;
                  if (today.month == 1 && month == 12) year--;
              }
              itemDate = DateTime(year, month, day);
          } 
          // 2. Se não encontrou, mas temos data_inicio_semana e o item é novo
          else if (_savedStartDate != null) {
              itemDate = _savedStartDate!.add(Duration(days: i));
              // Corrigir o label se estiver faltando a data
              if (!diaOriginal.contains('/')) {
                  final weekDayName = DateFormat('EEEE', AppLocalizations.of(context)!.localeName).format(itemDate);
                  final weekDayCap = weekDayName[0].toUpperCase() + weekDayName.substring(1);
                  item['dia'] = "$weekDayCap - ${DateFormat('dd/MM').format(itemDate)}";
              }
          } else {
              itemDate = today; // Fallback
          }

          if (itemDate.isBefore(currentWeekStart)) {
              _pastPlan.add(item);
          } else if (itemDate.isAfter(currentWeekEnd)) {
              _nextPlan.add(item);
          } else {
              _currentPlan.add(item);
          }
      }
      
      // Ordenar cada balde por data
      _pastPlan.sort((a,b) => _extractDate(a).compareTo(_extractDate(b)));
      _currentPlan.sort((a,b) => _extractDate(a).compareTo(_extractDate(b)));
      _nextPlan.sort((a,b) => _extractDate(a).compareTo(_extractDate(b)));
  }

  DateTime _extractDate(Map<String, dynamic> item) {
      final dia = item['dia']?.toString() ?? '';
      final regex = RegExp(r'(\d{1,2})\s*/\s*(\d{1,2})');
      final match = regex.firstMatch(dia);
      if (match != null) {
          return DateTime(DateTime.now().year, int.parse(match.group(2)!), int.parse(match.group(1)!));
      }
      return DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.menuTitle(widget.petName),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.raceName,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          PdfActionButton(onPressed: () => _generateMenuPDF()),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.menuLastWeek),
            Tab(text: AppLocalizations.of(context)!.menuCurrentWeek),
            Tab(text: AppLocalizations.of(context)!.menuNextWeek),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
        : TabBarView(
            controller: _tabController,
            children: [
               _buildPeriodView(_pastPlan, AppLocalizations.of(context)!.menuNoHistory),
               _buildPeriodView(_currentPlan, AppLocalizations.of(context)!.menuNoCurrent),
               _buildPeriodView(_nextPlan, AppLocalizations.of(context)!.menuNoFuture),
            ],
        ),
    );
  }

  Widget _buildPeriodView(List<Map<String, dynamic>> plan, String emptyMsg) {
      if (plan.isEmpty) {
          return Center(
             child: Padding(
               padding: const EdgeInsets.all(32.0),
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.event_busy, size: 64, color: Colors.white.withOpacity(0.2)),
                   const SizedBox(height: 24),
                   Text(
                     emptyMsg,
                     style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 16),
                   if (emptyMsg.contains("futuro") || emptyMsg.contains("semana"))
                   ElevatedButton.icon(
                      onPressed: () async {
                          final service = PetProfileService();
                          await service.init();
                          final pData = await service.getProfile(widget.petName);
                          if (pData != null && pData['data'] != null && mounted) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => EditPetForm(
                                  petData: pData['data'],
                                  onSave: (p) async {
                                      await service.saveOrUpdateProfile(p.petName, {'data': p.toJson()});
                                      Navigator.pop(context);
                                      _loadMenuFromService();
                                  }
                              )));
                          }
                      },
                      icon: const Icon(Icons.edit_calendar, color: Colors.black),
                      label: Text(AppLocalizations.of(context)!.menuGenerateEdit),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                   ),
                 ],
               ),
             ),
          );
      }

      return SingleChildScrollView(
         padding: const EdgeInsets.all(16),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                if (_guidelines != null)
                   Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                      child: Row(
                         children: [
                            const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_guidelines!, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic))),
                         ],
                      ),
                   ),
                ...plan.asMap().entries.map((entry) => _buildMealCard(entry.value, entry.key, plan == _pastPlan ? -1 : (plan == _currentPlan ? 0 : 1))).toList(),
                const SizedBox(height: 40),
            ],
         ),
      );
  }

  Widget _buildMealCard(Map<String, dynamic> item, int index, int periodType) {
      String dia = item['dia']?.toString() ?? '??';
      
      // FORÇAR DATA DINÂMICA SE TIVERMOS DATA DE INÍCIO
      if (_savedStartDate != null) {
          // Precisamos calcular o offset baseado no tipo de período (-1, 0, 1)
          final dateForDay = _savedStartDate!.add(Duration(days: index + (periodType * 7))); 
          final dateStr = DateFormat('dd/MM').format(dateForDay);
          final weekDayName = DateFormat('EEEE', AppLocalizations.of(context)!.localeName).format(dateForDay);
          final weekDayCap = weekDayName[0].toUpperCase() + weekDayName.substring(1);
          dia = "$weekDayCap - $dateStr";
      }
      
      List<Map<String, dynamic>> refeicoes = [];
      if (item.containsKey('refeicoes') && item['refeicoes'] is List) {
          refeicoes = (item['refeicoes'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
          final keysRaw = ['manha', 'manhã', 'tarde', 'noite', 'jantar', 'refeicao'];
          for (var k in keysRaw) {
             if (item[k] != null) {
                refeicoes.add({'hora': k.toUpperCase(), 'titulo': AppLocalizations.of(context)!.pdfRefeicao, 'descricao': item[k].toString()});
             }
          }
      }

      return Card(
        color: Colors.white.withOpacity(0.05),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        child: Padding(
           padding: const EdgeInsets.all(16),
           child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                    children: [
                       Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.restaurant, color: Color(0xFF00E676), size: 16),
                       ),
                       const SizedBox(width: 12),
                       Text(dia, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                 ),
                 const SizedBox(height: 12),
                 ...refeicoes.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                                Row(
                                   children: [
                                      Text('${r['hora'] ?? '--:--'}', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(width: 8),
                                      Text(r['titulo'] ?? AppLocalizations.of(context)!.pdfRefeicao, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                   ],
                                ),
                                if (_kcalTarget != null)
                                   Text('$_kcalTarget', style: GoogleFonts.poppins(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                             ],
                          ),
                          // New Requirement: Principais Nutrientes Row
                          if (_kcalTarget != null) ...[
                             const SizedBox(height: 4),
                             Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                   Text(AppLocalizations.of(context)!.menuMainNutrients, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                                   Text('$_kcalTarget', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 12)),
                                ],
                             ),
                          ],
                          Padding(
                             padding: const EdgeInsets.only(left: 4, top: 4),
                             child: Text(r['descricao'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3)),
                          ),
                          if (refeicoes.indexOf(r) < refeicoes.length - 1)
                             const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(color: Colors.white10, height: 1)),
                       ],
                    ),
                 )).toList(),
                 if (refeicoes.isEmpty)
                   Text(AppLocalizations.of(context)!.menuNoDetails, style: const TextStyle(color: Colors.white24, fontSize: 12)),
              ],
           ),
        ),
      );
  }

  Future<void> _generateMenuPDF() async {
    // 1. Mostrar Modal de Filtro
    bool includePast = false;
    bool includeCurrent = true;
    bool includeNext = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF00E676))),
          title: Text(AppLocalizations.of(context)!.menuExportTitle, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.menuExportSelectPeriod, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              Theme(
                data: ThemeData.dark(),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: Text(AppLocalizations.of(context)!.menuLastWeek),
                      activeColor: const Color(0xFF00E676),
                      value: includePast,
                      onChanged: (v) => setModalState(() => includePast = v!),
                    ),
                    CheckboxListTile(
                      title: Text(AppLocalizations.of(context)!.menuCurrentWeek),
                      activeColor: const Color(0xFF00E676),
                      value: includeCurrent,
                      onChanged: (v) => setModalState(() => includeCurrent = v!),
                    ),
                    CheckboxListTile(
                      title: Text(AppLocalizations.of(context)!.menuNextWeek),
                      activeColor: const Color(0xFF00E676),
                      value: includeNext,
                      onChanged: (v) => setModalState(() => includeNext = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.btnCancel, style: const TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _proceedWithPDF(includePast, includeCurrent, includeNext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
              child: Text(AppLocalizations.of(context)!.menuExportReport),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedWithPDF(bool past, bool current, bool next) {
    try {
        final List<Map<String, dynamic>> finalPlan = [];
        if (past) finalPlan.addAll(_pastPlan);
        if (current) finalPlan.addAll(_currentPlan);
        if (next) finalPlan.addAll(_nextPlan);

        if (finalPlan.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.menuNoPeriodSelected)));
            return;
        }

        // NORMALIZATION: Ensure 'refeicoes' list exists for the PDF service
        final List<Map<String, dynamic>> normalizedPlan = finalPlan.map((day) {
            final Map<String, dynamic> d = Map<String, dynamic>.from(day);
            if (!d.containsKey('refeicoes') || d['refeicoes'] is! List) {
                final List<Map<String, dynamic>> refs = [];
                final keysRaw = ['manha', 'manhã', 'tarde', 'noite', 'jantar', 'refeicao'];
                for (var k in keysRaw) {
                    if (d[k] != null) {
                        refs.add({'hora': k.toUpperCase(), 'titulo': AppLocalizations.of(context)!.pdfRefeicao, 'descricao': d[k].toString()});
                    }
                }
                d['refeicoes'] = refs;
            }
            return d;
        }).toList();

        // Calculate period for header
        String periodDesc = AppLocalizations.of(context)!.menuPeriodCustom;
        if (past && !current && !next) periodDesc = AppLocalizations.of(context)!.menuLastWeek;
        else if (!past && current && !next) periodDesc = AppLocalizations.of(context)!.menuCurrentWeek;
        else if (!past && !current && next) periodDesc = AppLocalizations.of(context)!.menuNextWeek;
        else if (past && current && next) periodDesc = AppLocalizations.of(context)!.menuPeriodFull;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              title: '${AppLocalizations.of(context)!.menuTitle('')} ${widget.petName}',
              buildPdf: (format) async {
                final pdf = await ExportService().generateWeeklyMenuReport(
                  petName: widget.petName,
                  raceName: widget.raceName,
                  strings: AppLocalizations.of(context)!,
                  dietType: _dietType ?? AppLocalizations.of(context)!.petNotOffice,
                  plan: normalizedPlan,
                  guidelines: _guidelines,
                  dailyKcal: _kcalTarget,
                  period: periodDesc,
                );
                return pdf.save();
              },
            ),
          ),
        );
    } catch (e) {
      debugPrint('Erro ao gerar PDF: $e');
    }
  }
}

