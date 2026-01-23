import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/models/plan_day.dart';
import '../../data/models/meal.dart';
import '../controllers/nutrition_providers.dart';
import '../../data/datasources/weekly_plan_service.dart';
import '../widgets/create_menu_dialog.dart';
import '../../data/models/menu_creation_params.dart';
import '../../data/models/menu_creation_result.dart';
import '../../data/models/user_nutrition_profile.dart';
import '../../data/datasources/menu_filter_service.dart';
import '../widgets/edit_meal_dialog.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/pdf_preview_screen.dart';
import '../../../core/widgets/pdf_action_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/translation_mapper.dart';
import '../../../core/widgets/pro_access_wrapper.dart';
import '../../../core/theme/app_design.dart';

/// Tela do Plano Semanal - MVP Completo
class WeeklyPlanScreen extends ConsumerStatefulWidget {
  const WeeklyPlanScreen({super.key});

  @override
  ConsumerState<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends ConsumerState<WeeklyPlanScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Carregar dados offline
      final dataService = ref.read(nutritionDataProvider);
      if (!dataService.isLoaded) {
        await dataService.loadData();
      }

      // Verificar se existe plano para esta semana
      final currentPlan = ref.read(currentWeekPlanProvider);
      
      if (currentPlan == null) {
        // Gerar novo plano
        final profile = ref.read(nutritionProfileProvider);
        if (profile != null) {
          await ref.read(currentWeekPlanProvider.notifier).generateNewPlan(profile);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error loading plan: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showRedoOptions() async {
    final l10n = AppLocalizations.of(context)!;
    final plan = ref.read(currentWeekPlanProvider);
    if (plan == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDesign.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: AppDesign.accent),
              title: Text(l10n.redoPlanAction, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
              onTap: () {
                Navigator.pop(context);
                _showCreateMenuDialog(preferredPeriodId: 'this_week'); // Always show filter
              },
            ),
            ListTile(
              leading: const Icon(Icons.skip_next, color: AppDesign.primary),
              title: Text(l10n.generateNextWeekAction, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
              onTap: () {
                Navigator.pop(context);
                _showCreateMenuDialog(preferredPeriodId: 'next_week'); // Always show filter
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: AppDesign.warning),
              title: Text(l10n.generate28DaysAction, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
              onTap: () {
                Navigator.pop(context);
                _showCreateMenuDialog(preferredPeriodId: 'month'); // Always show filter
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }





  Future<void> _generatePDF(WeeklyPlan plan) async {
    final l10n = AppLocalizations.of(context)!;
    final String goal = plan.objective == 'emagrecimento' ? l10n.objWeightLoss : l10n.objMaintenance;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          title: l10n.pdfMenuPlanTitle,
          buildPdf: (format) async {
            final pdf = await ExportService().generateHumanNutritionPlanReport(
              goal: goal,
              days: plan.days,
              strings: l10n,
              batchCookingTips: _getLocalizedTips(plan.dicasPreparo, l10n),
              shoppingListJson: plan.shoppingListJson,
            );
            return pdf.save();
          },
        ),
      ),
    );
  }

  Future<void> _showCreateMenuDialog({String? preferredPeriodId}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      debugPrint('[CriarCardapio] Botão tocado');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.openingConfig),
            duration: const Duration(seconds: 1),
            backgroundColor: AppDesign.accent,
          ),
        );
      }

      final profile = ref.read(nutritionProfileProvider);
      
      // Load last configuration
      MenuCreationParams? lastParams;
      String? lastPeriodId;
      try {
        final lastConfig = MenuFilterService().getLastConfig();
        if (lastConfig != null) {
          lastParams = MenuCreationParams.fromMap(lastConfig);
          lastPeriodId = lastConfig['selectedPeriodId'];
        }
      } catch (e) {
        debugPrint('⚠️ Error loading last menu config: $e');
      }

      debugPrint('[CriarCardapio] Perfil lido');
      
      debugPrint('[CriarCardapio] Abrindo showDialog...');
      final result = await showDialog<MenuCreationResult>(
        context: context,
        builder: (context) => CreateMenuDialog(
          userRestrictions: profile?.restricoes ?? [],
          initialParams: lastParams,
          initialSelectedPeriodId: preferredPeriodId ?? lastPeriodId,
        ),
      );
      debugPrint('[CriarCardapio] showDialog retornou');

      if (result != null && mounted) {
        final params = result.params;
        
        // Persist last config
        await MenuFilterService().saveLastConfig(params, selectedPeriodId: result.selectedPeriodId);

        setState(() => _isLoading = true);
        
        try {
          // 1. Check for conflicts (if a plan exists on startDate)
          bool replace = false;
          final existingPlans = WeeklyPlanService().getAllActivePlans().where((p) => 
            WeeklyPlanService().isSameDay(p.weekStartDate, params.startDate!)
          ).toList();

          if (existingPlans.isNotEmpty) {
            setState(() => _isLoading = false); // Stop loading to show dialog
            final choice = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppDesign.surfaceDark,
                title: Text(l10n.redoPlanAction, style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark)),
                content: Text(l10n.redoPlanPrompt, style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'archive'),
                    child: Text(l10n.createNewVersion, style: GoogleFonts.poppins(color: AppDesign.accent)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'replace'),
                    child: Text(l10n.replaceExisting, style: GoogleFonts.poppins(color: AppDesign.error)),
                  ),
                ],
              ),
            );
            if (choice == null) return;
            replace = choice == 'replace';
            setState(() => _isLoading = true);
          }

          final dataService = ref.read(nutritionDataProvider);
          if (!dataService.isLoaded) {
            await dataService.loadData();
          }

          var activeProfile = ref.read(nutritionProfileProvider);
          if (activeProfile == null) {
              activeProfile = UserNutritionProfile.padrao();
              await ref.read(nutritionProfileProvider.notifier).updateProfile(activeProfile);
              
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text(l10n.creatingProfile),
                     backgroundColor: AppDesign.warning,
                     duration: const Duration(seconds: 2),
                   ),
                 );
              }
          }

          // Gerar plano para a semana usando o perfil garantido
          final localeCode = Localizations.localeOf(context).languageCode;
          await ref.read(currentWeekPlanProvider.notifier).generateNewPlan(
            activeProfile, 
            params: params, 
            languageCode: localeCode,
            replace: replace,
          );
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${l10n.planCreatedSuccess}'),
                  backgroundColor: AppDesign.success,
                ),
              );
            }
        } catch (e) {
          debugPrint('[CriarCardapio] Erro: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.errorGeneric} $e'),
                backgroundColor: AppDesign.error,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('[CriarCardapio] Erro crítico: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHistory() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppDesign.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.historyTitle,
                style: GoogleFonts.poppins(
                  color: AppDesign.textPrimaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ValueListenableBuilder<Box<WeeklyPlan>>(
                  valueListenable: WeeklyPlanService().listenable!,
                  builder: (context, box, _) {
                    final plans = WeeklyPlanService().getAllPlans();
                    plans.sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));

                    if (plans.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.noHistory,
                          style: const TextStyle(color: AppDesign.textPrimaryDark),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: plans.length,
                      separatorBuilder: (_, __) => Divider(
                        color: AppDesign.textPrimaryDark.withValues(alpha: 0.12),
                      ),
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        // if (!mounted) return const SizedBox.shrink(); // This is inside a builder, causing the return type mismatch void vs Widget
                        final locale = Localizations.localeOf(context).toString();
                        final isCurrent = ref.read(currentWeekPlanProvider)?.id == plan.id;
                        final statusColor = plan.status == 'active'
                            ? AppDesign.success
                            : AppDesign.textSecondaryDark;
                        final statusLabel =
                            plan.status == 'active' ? l10n.statusActive : l10n.statusArchived;

                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.weeklyPlanTitle(
                                    DateFormat('dd/MM', locale).format(plan.weekStartDate),
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: isCurrent ? AppDesign.foodOrange : AppDesign.textPrimaryDark,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: GoogleFonts.poppins(color: statusColor, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${plan.periodType == '28days' ? '28 dias' : l10n.daysPlanned(plan.days.length)} | ${plan.objective ?? l10n.objMaintenance} | ${l10n.versionLabel} ${plan.version}',
                            style: GoogleFonts.poppins(
                              color: AppDesign.textSecondaryDark,
                              fontSize: 11,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppDesign.surfaceDark,
                                      title: Text(l10n.deletePlanTitle,
                                          style: const TextStyle(color: AppDesign.textPrimaryDark)),
                                      content: Text(l10n.deletePlanBody,
                                          style:
                                              const TextStyle(color: AppDesign.textSecondaryDark)),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text(l10n.cancel)),
                                        TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: Text(l10n.commonDelete,
                                                style: const TextStyle(color: AppDesign.error))),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await ref.read(currentWeekPlanProvider.notifier).deletePlan(plan);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.deletePlanSuccess ??
                                              'Plano excluído com sucesso'),
                                          backgroundColor: AppDesign.success,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              const Icon(Icons.chevron_right, color: AppDesign.textSecondaryDark),
                            ],
                          ),
                          onTap: () {
                            ref.read(currentWeekPlanProvider.notifier).setPlan(plan);
                            if (!mounted) return;
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppDesign.accent),
            const SizedBox(height: 24),
            Text(
              l10n.generatingMenu,
              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppDesign.error),
            const SizedBox(height: 16),
            Text(
              l10n.planError,
              style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPlan,
              style: ElevatedButton.styleFrom(backgroundColor: AppDesign.accent),
              child: Text(l10n.tryAgain, style: GoogleFonts.poppins(color: AppDesign.backgroundDark)),
            ),
          ],
        ),
      );
    }

    final plan = ref.watch(currentWeekPlanProvider);

    if (plan == null) {
      return ProAccessWrapper(
        featureName: l10n.featureMenuPlanTitle,
        featureDescription: l10n.featureMenuPlanDesc,
        featureIcon: Icons.calendar_today,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Icon(Icons.calendar_today, size: 64, color: AppDesign.textSecondaryDark),
              const SizedBox(height: 16),
              Text(
                l10n.noPlanTitle,
                style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _showCreateMenuDialog,
                style: ElevatedButton.styleFrom(backgroundColor: AppDesign.foodOrange), // Synced with Footer Icon
                child: Text(l10n.createPlanButton, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return ProAccessWrapper(
      featureName: l10n.featureMenuPlanTitle,
      featureDescription: l10n.featureMenuPlanDesc,
      featureIcon: Icons.calendar_month,
      child: Column(
        children: [
          // Header com acoes
          Container(
            padding: const EdgeInsets.all(16),
            color: AppDesign.surfaceDark,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.weeklyPlanTitle(DateFormat('dd/MM', Localizations.localeOf(context).toString()).format(plan.weekStartDate)),
                        style: GoogleFonts.poppins(
                          color: AppDesign.textPrimaryDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.weeklyPlanSubtitle(plan.days.length),
                        style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.history, color: AppDesign.foodOrange),
                  tooltip: l10n.historyTitle,
                  onPressed: _showHistory,
                ),
                PdfActionButton(onPressed: () => _generatePDF(plan)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppDesign.foodOrange),
                  tooltip: l10n.redoPlanAction,
                  onPressed: _showRedoOptions,
                ),
              ],
            ),
          ),
          // Seção de Dicas (Batch Cooking)
          _buildTipsSection(plan),
          
          // Lista de dias
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plan.days.length,
              itemBuilder: (context, index) {
                final day = plan.days[index];
                return _buildDayCard(day);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(WeeklyPlan plan) {
    if (plan.dicasPreparo == null || plan.dicasPreparo!.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final localizedTips = _getLocalizedTips(plan.dicasPreparo, l10n);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppDesign.foodOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppDesign.foodOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.tipsTitle,
                style: GoogleFonts.poppins(
                  color: AppDesign.foodOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localizedTips,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedTips(String? rawTips, AppLocalizations l10n) {
    if (rawTips == null || rawTips.isEmpty) return '';
    
    // Check if it's a pipe-separated list of keys
    if (rawTips.contains('|')) {
       return rawTips.split('|').map((k) {
          final t = _translateTipKey(k, l10n);
          return t.isNotEmpty ? t : k; 
       }).join('\n\n');
    } 
    
    // Check if it's a single key
    final t = _translateTipKey(rawTips, l10n);
    return t.isNotEmpty ? t : rawTips;
  }

  String _translateTipKey(String key, AppLocalizations l10n) {
    switch (key.trim()) {
      case 'tipBeans': return l10n.tipBeans;
      case 'tipRice': return l10n.tipRice;
      case 'tipChicken': return l10n.tipChicken;
      case 'tipEggs': return l10n.tipEggs;
      case 'tipVeggies': return l10n.tipVeggies;
      case 'tipRoots': return l10n.tipRoots;
      case 'tipGroundMeat': return l10n.tipGroundMeat;
      case 'tipFruits': return l10n.tipFruits;
      case 'tipDefault': return l10n.tipDefault;
      default: return ''; 
    }
  }

  Widget _buildCaloriesSummary(PlanDay day) {
    final cals = _calculateDayCalories(day);
    if (cals == 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Icon(Icons.local_fire_department, size: 14, color: AppDesign.warning.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          '$cals ${l10n.caloriesEstimated}',
          style: GoogleFonts.poppins(
            color: AppDesign.textPrimaryDark.withValues(alpha: 0.38),
            fontSize: 11,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: (cals / 2000).clamp(0.0, 1.0),
            backgroundColor: AppDesign.textPrimaryDark.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppDesign.warning.withValues(alpha: 0.5)),
            minHeight: 2,
          ),
        ),
      ],
    );
  }

  int _calculateDayCalories(PlanDay day) {
    int total = 0;
    for (var meal in day.meals) {
      final mealMatch = RegExp(r'(\d+)\s*kcal').firstMatch(meal.observacoes);
      if (mealMatch != null) {
        total += int.tryParse(mealMatch.group(1) ?? '0') ?? 0;
      } else {
        for (var item in meal.itens) {
          final itemMatch = RegExp(r'(\d+)\s*kcal').firstMatch(item.observacoes ?? '');
          if (itemMatch != null) {
            total += int.tryParse(itemMatch.group(1) ?? '0') ?? 0;
          }
        }
      }
    }
    return total;
  }

  Widget _buildDayCard(PlanDay day) {
    final isToday = _isToday(day.date);
    final locale = Localizations.localeOf(context).toString();
    final dayName = DateFormat('EEEE', locale).format(day.date);
    final dayNumber = DateFormat('dd/MM', locale).format(day.date);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isToday ? AppDesign.accent.withValues(alpha: 0.1) : AppDesign.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isToday ? AppDesign.foodOrange : AppDesign.foodOrange.withValues(alpha: 0.3), // Food Domain Border
          width: isToday ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _openDayDetails(day),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppDesign.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.todayLabel,
                        style: GoogleFonts.poppins(
                          color: AppDesign.backgroundDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isToday) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dayName.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: AppDesign.textPrimaryDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    dayNumber,
                    style: GoogleFonts.poppins(color: AppDesign.textSecondaryDark, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildCaloriesSummary(day),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: day.meals.map((meal) => _buildMealChip(meal)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealChip(Meal meal) {
    final l10n = AppLocalizations.of(context)!;
    final icon = _getMealIcon(meal.tipo);
    final color = _getMealColor(meal.tipo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            _getMealLabel(meal.tipo, l10n),
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _openDayDetails(PlanDay day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayPlanDetailsScreen(day: day),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  IconData _getMealIcon(String tipo) {
    switch (tipo) {
      case 'cafe':
        return Icons.free_breakfast;
      case 'almoco':
        return Icons.lunch_dining;
      case 'lanche':
        return Icons.cookie;
      case 'jantar':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealColor(String tipo) {
    switch (tipo) {
      case 'cafe':
        return AppDesign.warning;
      case 'almoco':
        return AppDesign.success;
      case 'lanche':
        return AppDesign.accent;
      case 'jantar':
        return AppDesign.primary;
      default:
        return AppDesign.textSecondaryDark;
    }
  }

  String _getMealLabel(String tipo, AppLocalizations l10n) {
    switch (tipo) {
      case 'cafe':
        return l10n.mealBreakfast;
      case 'almoco':
        return l10n.mealLunch;
      case 'lanche':
        return l10n.mealSnack;
      case 'jantar':
        return l10n.mealDinner;
      default:
        return tipo;
    }
  }
}

/// Tela de detalhes do dia
class DayPlanDetailsScreen extends ConsumerWidget {
  final PlanDay day;

  const DayPlanDetailsScreen({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toString();
    // Watch for changes to the plan to ensure we have the latest version of the day
    final plan = ref.watch(currentWeekPlanProvider);
    
    // Find the current version of this day in the plan
    final currentDay = plan?.days.firstWhere(
      (d) => 
        d.date.year == day.date.year && 
        d.date.month == day.date.month && 
        d.date.day == day.date.day,
      orElse: () => day,
    ) ?? day;

    final dayName = DateFormat('EEEE, dd/MM/yyyy', locale).format(currentDay.date);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppDesign.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppDesign.surfaceDark,
        title: Text(
          dayName,
          style: GoogleFonts.poppins(color: AppDesign.textPrimaryDark),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: currentDay.meals.length,
        itemBuilder: (context, index) {
          final meal = currentDay.meals[index];
          return _buildMealCard(context, ref, meal, l10n, currentDay);
        },
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, WidgetRef ref, Meal meal, AppLocalizations l10n, PlanDay currentDay) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppDesign.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getMealIcon(meal.tipo),
                  color: _getMealColor(meal.tipo),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMealLabel(meal.tipo, l10n),
                        style: GoogleFonts.poppins(
                          color: AppDesign.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        TranslationMapper.localizeFoodName(meal.nomePrato ?? (meal.itens.isNotEmpty ? meal.itens.first.nome : l10n.mealDefault), l10n),
                        style: GoogleFonts.poppins(
                          color: AppDesign.textPrimaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppDesign.textSecondaryDark, size: 20),
                  onPressed: () => _showEditDialog(context, ref, meal, currentDay),
                ),
              ],
            ),
            if (meal.observacoes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                meal.observacoes,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Text(
              l10n.ingredientsTitle,
              style: GoogleFonts.poppins(
                color: Colors.white30,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ...meal.itens.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: _getMealColor(meal.tipo).withValues(alpha: 0.5)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      TranslationMapper.localizeFoodName(item.nome, l10n),
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Text(
                    item.quantidadeTexto,
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Meal meal, PlanDay currentDay) {
    showDialog(
      context: context,
      builder: (context) => EditMealDialog(
        meal: meal,
        onSave: (updatedMeal) async {
          debugPrint('📝 [EditMeal] Saving started...');
          debugPrint('   Old: ${meal.nomePrato} (${meal.itens.length} items)');
          debugPrint('   New: ${updatedMeal.nomePrato} (${updatedMeal.itens.length} items)');
          try {
            await ref.read(currentWeekPlanProvider.notifier).updateMeal(currentDay, meal, updatedMeal);
            debugPrint('✅ [EditMeal] Save completed successfully');
            
            // Force refresh if needed, but watch() in build should handle it
            // ref.read(currentWeekPlanProvider.notifier).refresh(); 
          } catch (e) {
             debugPrint('❌ [EditMeal] Error saving: $e');
          }
        },
      ),
    );
  }

  IconData _getMealIcon(String tipo) {
    switch (tipo) {
      case 'cafe':
        return Icons.free_breakfast;
      case 'almoco':
        return Icons.lunch_dining;
      case 'lanche':
        return Icons.cookie;
      case 'jantar':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealColor(String tipo) {
    switch (tipo) {
      case 'cafe':
        return AppDesign.warning;
      case 'almoco':
        return AppDesign.success;
      case 'lanche':
        return AppDesign.accent;
      case 'jantar':
        return AppDesign.primary;
      default:
        return AppDesign.textSecondaryDark;
    }
  }

  String _getMealLabel(String tipo, AppLocalizations l10n) {
    switch (tipo) {
      case 'cafe':
        return l10n.mealBreakfast;
      case 'almoco':
        return l10n.mealLunch;
      case 'lanche':
        return l10n.mealSnack;
      case 'jantar':
        return l10n.mealDinner;
      default:
        return tipo;
    }
  }
}

