import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:scannut/core/theme/app_design.dart';
import 'package:scannut/l10n/app_localizations.dart';

import '../../models/weekly_meal_plan.dart';
import '../../services/meal_plan_service.dart';
import '../../services/pet_shopping_list_service.dart';
import '../../services/pet_menu_generator_service.dart';
import '../../../../core/services/export_service.dart';
import 'pet_menu_filter_dialog.dart';
import '../../models/meal_plan_request.dart';

class WeeklyMenuScreen extends ConsumerStatefulWidget {
  final String petName;
  final String raceName;
  
  // Legacy params kept for compatibility
  final List<Map<String, dynamic>> currentWeekPlan;
  final String generalGuidelines;

  const WeeklyMenuScreen({
    Key? key,
    required this.petName,
    required this.raceName,
    this.currentWeekPlan = const [],
    this.generalGuidelines = '',
  }) : super(key: key);

  @override
  ConsumerState<WeeklyMenuScreen> createState() => _WeeklyMenuScreenState();
}

class _WeeklyMenuScreenState extends ConsumerState<WeeklyMenuScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<WeeklyMealPlan> _history = [];
  final Set<String> _selectedPlanIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
       // Fetch strict history from Hive
       final plans = await MealPlanService().getPlansForPet(widget.petName.trim());
       if (mounted) {
         setState(() {
           _history = plans;
           _isLoading = false;
         });
         
         // Auto-switch to History if available and not explicitly set
         if (_history.isNotEmpty && _tabController.index == 0) {
            _tabController.animateTo(1);
         }
       }
    } catch (e) {
       debugPrint('Error loading history: $e');
       if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePlan(String planId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.petTabHistory, style: const TextStyle(color: Colors.white)),
        content: Text(l10n.petMenuDeleteWeekConfirm, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(l10n.commonDelete, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await MealPlanService().deletePlan(planId);
      await PetShoppingListService().deleteList(planId);
      
      if (mounted) {
        _selectedPlanIds.remove(planId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.petMenuDeletedSuccess), backgroundColor: AppDesign.success));
        await _loadHistory();
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppDesign.error));
         setState(() => _isLoading = false);
       }
    }
  }

  Future<void> _generatePdfMulti() async {
    if (_selectedPlanIds.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppDesign.petPink)),
    );

    try {
      // 1. Gather Data
      final selectedPlans = _history.where((p) => _selectedPlanIds.contains(p.id)).toList();
      selectedPlans.sort((a, b) => a.startDate.compareTo(b.startDate)); // Chronological order

      // 2. Normalize for ExportService (needs List<Map<String, dynamic>>)
      // ExportService expects 'plan' as List of Daily Items, grouped by 'planId'.
      final List<Map<String, dynamic>> consolidatedPlan = [];
      final Map<String, List<Map<String, dynamic>>> shoppingLists = {};

      for (var plan in selectedPlans) {
         // Load shopping list
         final sl = await PetShoppingListService().getList(plan.id);
         if (sl != null) shoppingLists[plan.id] = sl;

         // Convert daily meals
         for (var day in plan.meals) {
            consolidatedPlan.add({
               'dia': _formatDateForPdf(plan.startDate, day.dayOfWeek),
               'hora': day.time,
               'titulo': day.title,
               'descricao': day.description,
               'benefit': day.benefit ?? '',
               'refeicoes': [ // Format expected by ExportService
                   {
                     'hora': day.time,
                     'titulo': day.title,
                     'descricao': day.description,
                     'quantity': day.quantity
                   }
               ],
               'planId': plan.id // Critical for grouping
            });
         }
      }

      // 3. Generate
      final pdf = await ExportService().generateWeeklyMenuReport(
         petName: widget.petName,
         raceName: widget.raceName,
         dietType: selectedPlans.first.dietType, // Use first as representative
         plan: consolidatedPlan,
         strings: l10n,
         shoppingLists: shoppingLists,
         period: _selectedPlanIds.length > 1 ? l10n.petMenuGeneratePdfMulti(selectedPlans.length) : null
      );

      if (mounted) {
         Navigator.pop(context); // Close loading
         await ExportService().saveAndShow(pdf: pdf, fileName: "Menu_${widget.petName}_Consolidated.pdf");
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.petMenuPdfGenerated), backgroundColor: AppDesign.success));
         setState(() => _selectedPlanIds.clear());
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pdf Error: $e'), backgroundColor: AppDesign.error));
      }
    }
  }

  String _formatDateForPdf(DateTime start, int dayOfWeekIso) {
     final d = start.add(Duration(days: dayOfWeekIso - 1));
     return DateFormat('EEEE dd/MM', Localizations.localeOf(context).toString()).format(d);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(widget.petName.isEmpty ? 'Cardápio' : '${widget.petName}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
           controller: _tabController,
           indicatorColor: AppDesign.petPink,
           labelColor: AppDesign.petPink,
           unselectedLabelColor: Colors.white60,
           indicatorSize: TabBarIndicatorSize.label,
           tabs: [
              Tab(text: l10n.petTabGenerate),
              Tab(text: l10n.petTabHistory),
           ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
           _buildGenerateTab(l10n),
           _buildHistoryTab(l10n),
        ],
      ),
    );
  }

  Widget _buildGenerateTab(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Container(
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(
                  color: AppDesign.petPink.withOpacity(0.1),
                  shape: BoxShape.circle,
               ),
               child: const Icon(Icons.auto_awesome, size: 60, color: AppDesign.petPink),
             ),
             const SizedBox(height: 32),
             Text(
               l10n.petTabGenerate,
               style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
             ),
             const SizedBox(height: 12),
             Text(
               'Crie cardápios personalizados, listas de compras e acompanhe a nutrição do seu pet em segundos.',
               textAlign: TextAlign.center,
               style: GoogleFonts.poppins(fontSize: 14, color: Colors.white60),
             ),
             const SizedBox(height: 48),
             SizedBox(
               width: double.infinity,
               height: 56,
               child: ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppDesign.petPink,
                   foregroundColor: Colors.black,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   elevation: 4,
                 ),
                 onPressed: () async {
                    // Trigger Filter
                    final config = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => const PetMenuFilterDialog(),
                    );
                    
                    if (config != null && mounted) {
                       _runGeneration(config);
                    }
                 },
                 child: Text(
                   l10n.petTabGenerate.toUpperCase(),
                   style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                 ),
               ),
             )
          ],
        ),
      ),
    );
  }

  Future<void> _runGeneration(Map<String, dynamic> config) async {
     final l10n = AppLocalizations.of(context)!;
     
     showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppDesign.petPink)),
     );
     
     try {
        Map<String, dynamic> profileData = {
           'name': widget.petName,
           'breed': widget.raceName
        };

         final request = MealPlanRequest(
            petId: widget.petName.trim(), 
            profileData: profileData,
            mode: config['mode'],
            startDate: config['startDate'],
            endDate: config['endDate'],
            locale: Localizations.localeOf(context).toString(),
            dietType: config['dietType'] as PetDietType,
            otherNote: config['otherNote'] as String?,
            source: 'PetProfile', // Authorized Source (WeeklyMenuScreen is reached via PetProfile)
         );

         await ref.read(petMenuGeneratorProvider).generateAndSave(request);


        if (mounted) {
           Navigator.pop(context); // Stop Loading
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.petMenuSuccess), backgroundColor: AppDesign.success));
           await _loadHistory(); // Refresh history
           _tabController.animateTo(1); // Switch to History
        }
     } catch (e) {
        if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generation Error: $e'), backgroundColor: AppDesign.error));
        }
     }
  }

  Widget _buildHistoryTab(AppLocalizations l10n) {
    if (_isLoading) {
       return const Center(child: CircularProgressIndicator(color: AppDesign.petPink));
    }
    
    if (_history.isEmpty) {
       return Center(
         child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Icon(Icons.history_toggle_off, size: 48, color: Colors.white24),
               const SizedBox(height: 16),
               Text(l10n.petMenuEmptyHistory, style: GoogleFonts.poppins(color: Colors.white54)),
            ],
         ),
       );
    }

    return Column(
      children: [
        if (_selectedPlanIds.isNotEmpty)
           Container(
             color: AppDesign.petPink,
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  Text(
                    l10n.petMenuGeneratePdfMulti(_selectedPlanIds.length), 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
                  ),
                  Row(
                    children: [
                       TextButton.icon(
                         onPressed: () => setState(() => _selectedPlanIds.clear()),
                         icon: const Icon(Icons.close, size: 16, color: Colors.black87),
                         label: Text(l10n.petMenuSelectionClear, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                       ),
                       const SizedBox(width: 8),
                       IconButton(
                         icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
                         onPressed: _generatePdfMulti,
                       )
                    ],
                  )
               ],
             ),
           ),
        
        Expanded(
          child: ListView.builder(
            itemCount: _history.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
               final plan = _history[index];
               return _buildWeekCard(plan, l10n);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCard(WeeklyMealPlan plan, AppLocalizations l10n) {
     final startStr = DateFormat.Md(l10n.localeName).format(plan.startDate);
     final endStr = DateFormat.Md(l10n.localeName).format(plan.endDate);
     final dateRange = "$startStr - $endStr";
     final isSelected = _selectedPlanIds.contains(plan.id);

     return Card(
       color: Colors.white.withOpacity(0.05),
       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppDesign.petPink : Colors.transparent)),
       child: Theme(
         data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
         child: ExpansionTile(
            leading: Checkbox(
               value: isSelected,
               activeColor: AppDesign.petPink,
               checkColor: Colors.black,
               side: const BorderSide(color: Colors.white54),
               onChanged: (val) {
                  setState(() {
                     if (val == true) _selectedPlanIds.add(plan.id);
                     else _selectedPlanIds.remove(plan.id);
                  });
               },
            ),
            title: Text(dateRange, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('${plan.meals.length} days • Dieta: ${_getDietLabel(plan.dietType, l10n)}', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
            trailing: PopupMenuButton<String>(
               icon: const Icon(Icons.more_vert, color: Colors.white54),
               color: const Color(0xFF2C2C2C),
               onSelected: (val) {
                  if (val == 'delete') _deletePlan(plan.id);
               },
               itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                       children: [
                          const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.commonDelete, style: const TextStyle(color: Colors.white)),
                       ],
                    ),
                  )
               ],
            ),
            children: plan.meals.map((day) => _buildDayItem(plan, day, l10n)).toList(),
         ),
       ),
     );
  }

  Widget _buildDayItem(WeeklyMealPlan plan, DailyMealItem day, AppLocalizations l10n) {
     final dayDate = plan.startDate.add(Duration(days: day.dayOfWeek - 1));
     final weekDayName = DateFormat('EEEE', l10n.localeName).format(dayDate); 
     final dateStr = DateFormat('dd/MM', l10n.localeName).format(dayDate);

     return Container(
        decoration: BoxDecoration(
           border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Text(
                      "${weekDayName.toUpperCase()} $dateStr",
                      style: GoogleFonts.poppins(color: AppDesign.petPink, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    Row(
                       children: [
                          IconButton(
                             icon: const Icon(Icons.edit, size: 16, color: Colors.white54),
                             onPressed: () => _editDayDialog(plan, day),
                             tooltip: l10n.commonSave, 
                          ),
                          IconButton(
                             icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                             onPressed: () => _deleteDay(plan, day),
                             tooltip: l10n.commonDelete,
                          )
                       ],
                    )
                 ],
              ),
              const SizedBox(height: 4),
              // Content
              Text(
                "${day.time} - ${day.title}",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              if (day.quantity.isNotEmpty)
                 Text("Qty: ${day.quantity}", style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13)),
              
              const SizedBox(height: 4),
              Text(
                 day.description,
                 style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
           ],
        ),
     );
  }

  Future<void> _deleteDay(WeeklyMealPlan plan, DailyMealItem day) async {
     final l10n = AppLocalizations.of(context)!;
     final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
           backgroundColor: const Color(0xFF1E1E1E),
           content: Text(l10n.petMenuDeleteDayConfirm, style: const TextStyle(color: Colors.white)),
           actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54))),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete, style: const TextStyle(color: Colors.redAccent))),
           ],
        )
     );
     
     if (confirm != true) return;
     
     // Remove from list (Create new list)
     final newMeals = List<DailyMealItem>.from(plan.meals)..remove(day);
     
     // Check validity? Should I delete the week if empty?
     if (newMeals.isEmpty) {
        // Option to delete plan?
        await _deletePlan(plan.id);
        return;
     }

     final updatedPlan = WeeklyMealPlan(
        id: plan.id,
        petId: plan.petId,
        startDate: plan.startDate,
        endDate: plan.endDate,
        dietType: plan.dietType,
        nutritionalGoal: plan.nutritionalGoal,
        meals: newMeals,
        metadata: plan.metadata,
        templateName: plan.templateName,
        createdAt: plan.createdAt
     );
     
     await MealPlanService().savePlan(updatedPlan);
     
     if (mounted) {
        setState(() {
           final index = _history.indexWhere((p) => p.id == plan.id);
           if (index != -1) {
              _history[index] = updatedPlan;
           }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.petMenuDeletedSuccess), backgroundColor: AppDesign.success));
     }
  }

  Future<void> _editDayDialog(WeeklyMealPlan plan, DailyMealItem day) async {
     final l10n = AppLocalizations.of(context)!;
     
     final descCtrl = TextEditingController(text: day.description);
     final qtyCtrl = TextEditingController(text: day.quantity);
     
     final changed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
           backgroundColor: const Color(0xFF1E1E1E),
           title: Text(l10n.petMenuEditDayTitle, style: const TextStyle(color: Colors.white)),
           content: SingleChildScrollView(
              child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    TextField(
                       controller: qtyCtrl,
                       style: const TextStyle(color: Colors.white),
                       decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          labelStyle: TextStyle(color: Colors.white54),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                       ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                       controller: descCtrl,
                       style: const TextStyle(color: Colors.white),
                       maxLines: 5,
                       decoration: InputDecoration(
                          labelText: 'Ingredientes / Descrição',
                          labelStyle: const TextStyle(color: Colors.white54),
                          hintText: l10n.petMenuEditIngredientsHint,
                          hintStyle: const TextStyle(color: Colors.white24),
                          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                       ),
                    )
                 ],
              ),
           ),
           actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54))),
              ElevatedButton(
                 onPressed: () => Navigator.pop(ctx, true),
                 style: ElevatedButton.styleFrom(backgroundColor: AppDesign.petPink),
                 child: Text(l10n.commonSave, style: const TextStyle(color: Colors.black)),
              )
           ],
        )
     );
     
     if (changed != true) return;
     
     // Update
     final newDay = DailyMealItem(
        dayOfWeek: day.dayOfWeek,
        time: day.time,
        title: day.title,
        description: descCtrl.text,
        quantity: qtyCtrl.text,
        benefit: day.benefit
     );
     
     final newMeals = List<DailyMealItem>.from(plan.meals);
     final index = newMeals.indexOf(day);
     if (index != -1) newMeals[index] = newDay;
     
     final updatedPlan = WeeklyMealPlan(
        id: plan.id,
        petId: plan.petId,
        startDate: plan.startDate,
        endDate: plan.endDate,
        dietType: plan.dietType,
        nutritionalGoal: plan.nutritionalGoal,
        meals: newMeals,
        metadata: plan.metadata,
        templateName: plan.templateName,
        createdAt: plan.createdAt
     );
     
     await MealPlanService().savePlan(updatedPlan);
     
     if (mounted) {
        setState(() {
           final hIndex = _history.indexWhere((p) => p.id == plan.id);
           if (hIndex != -1) _history[hIndex] = updatedPlan;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.petMenuSaveSuccess), backgroundColor: AppDesign.success));
     }
  }


  String _getDietLabel(String code, AppLocalizations l10n) {
     if (code.toLowerCase().startsWith("outra") || code.toLowerCase().startsWith("other")) return code;
     switch (code) {
       case 'renal': return l10n.dietRenal ?? 'Renal';
       case 'hepatic': return l10n.dietHepatic ?? 'Hepatic';
       case 'gastrointestinal': return l10n.dietGastrointestinal ?? 'Gastrointestinal';
       case 'hypoallergenic': return l10n.dietHypoallergenic ?? 'Hypoallergenic';
       case 'obesity': return l10n.dietObesity ?? 'Obesity';
       case 'diabetes': return l10n.dietDiabetes ?? 'Diabetes';
       case 'cardiac': return l10n.dietCardiac ?? 'Cardiac';
       case 'urinary': return l10n.dietUrinary ?? 'Urinary';
       case 'muscle_gain': return l10n.dietMuscleGain ?? 'Muscle Gain';
       case 'pediatric': return l10n.dietPediatric ?? 'Pediatric';
       case 'growth': return l10n.dietGrowth ?? 'Growth';
       default: return code; 
     }
  }
}
