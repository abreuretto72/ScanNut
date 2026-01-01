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
import '../../data/models/user_nutrition_profile.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/pdf_preview_screen.dart';
import '../../../core/widgets/pdf_action_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/translation_mapper.dart';
import '../../../core/widgets/pro_access_wrapper.dart';

/// Tela do Plano Semanal - MVP Completo
class WeeklyPlanScreen extends ConsumerStatefulWidget {
  const WeeklyPlanScreen({Key? key}) : super(key: key);

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

  Future<void> _regeneratePlan() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(l10n.regeneratePlanTitle, style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          l10n.regeneratePlanBody,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel, style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            child: Text(l10n.regenerateAction, style: GoogleFonts.poppins(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final profile = ref.read(nutritionProfileProvider);
        if (profile != null) {
          await ref.read(currentWeekPlanProvider.notifier).regeneratePlan(profile);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${l10n.regenerateSuccess}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.planError}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _generatePDF(WeeklyPlan plan) async {
    final profile = ref.read(nutritionProfileProvider);
    final goal = profile?.objetivo ?? 'Saúde e Bem-estar'; // Localization here would require more refactoring of user profile or dynamic keys
    final l10n = AppLocalizations.of(context)!;

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
            );
            return pdf.save();
          },
        ),
      ),
    );
  }

  Future<void> _showCreateMenuDialog() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      debugPrint('[CriarCardapio] Botão tocado');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.openingConfig),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF00E676),
          ),
        );
      }

      final profile = ref.read(nutritionProfileProvider);
      debugPrint('[CriarCardapio] Perfil lido');
      
      debugPrint('[CriarCardapio] Abrindo showDialog...');
      final params = await showDialog<MenuCreationParams>(
        context: context,
        builder: (context) => CreateMenuDialog(
          userRestrictions: profile?.restricoes ?? [],
        ),
      );
      debugPrint('[CriarCardapio] showDialog retornou');

      if (params != null && mounted) {
        setState(() => _isLoading = true);
        
        try {
          final dataService = ref.read(nutritionDataProvider);
          if (!dataService.isLoaded) {
            await dataService.loadData();
          }

          var profile = ref.read(nutritionProfileProvider);
          
          // FALLBACK: Create default profile if missing
          if (profile == null) {
              debugPrint('⚠️ [WeeklyPlan] Profile is null. Creating default profile for generation...');
              profile = UserNutritionProfile.padrao();
              await ref.read(nutritionProfileProvider.notifier).updateProfile(profile);
              
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text(l10n.creatingProfile),
                     backgroundColor: Colors.amber,
                     duration: const Duration(seconds: 2),
                   ),
                 );
              }
          }

          // Gerar plano para a semana usando o perfil garantido
          final localeCode = Localizations.localeOf(context).languageCode;
          await ref.read(currentWeekPlanProvider.notifier).generateNewPlan(profile, params: params, languageCode: localeCode);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${l10n.planCreatedSuccess}'),
                  backgroundColor: Colors.green,
                ),
              );
            }
        } catch (e) {
          debugPrint('[CriarCardapio] Erro: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro: $e'),
                backgroundColor: Colors.red,
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
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(l10n.historyTitle, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<Box<WeeklyPlan>>(
                valueListenable: WeeklyPlanService().listenable!,
                builder: (context, box, _) {
                  final List<WeeklyPlan> plans = box.values.whereType<WeeklyPlan>().toList();
                  plans.sort((WeeklyPlan a, WeeklyPlan b) => b.weekStartDate.compareTo(a.weekStartDate));
                  
                  if (plans.isEmpty) return Center(child: Text(l10n.noHistory, style: const TextStyle(color: Colors.white)));
                  
                  return ListView.separated(
                    itemCount: plans.length,
                    separatorBuilder: (_,__) => const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      final locale = Localizations.localeOf(context).toString();
                      return ListTile(
                          title: Text(l10n.weeklyPlanTitle(DateFormat('dd/MM/yyyy', locale).format(plan.weekStartDate)), style: GoogleFonts.poppins(color: Colors.white)),
                          subtitle: Text(l10n.daysPlanned(plan.days.length), style: GoogleFonts.poppins(color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.grey.shade900,
                                      title: Text(l10n.deletePlanTitle, style: const TextStyle(color: Colors.white)),
                                      content: Text(l10n.deletePlanBody, style: const TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonDelete, style: const TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  
                                  if (confirm == true) {
                                    await ref.read(currentWeekPlanProvider.notifier).deletePlan(plan);
                                  }
                                },
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white54),
                            ],
                          ),
                          onTap: () {
                              ref.read(currentWeekPlanProvider.notifier).setPlan(plan);
                              Navigator.pop(context);
                          },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E676)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n.planError,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPlan,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
              child: Text(l10n.tryAgain, style: GoogleFonts.poppins(color: Colors.black)),
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
              const Icon(Icons.calendar_today, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                l10n.noPlanTitle,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _showCreateMenuDialog,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
                child: Text(l10n.createPlanButton, style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
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
            color: Colors.grey.shade900,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.weeklyPlanTitle(DateFormat('dd/MM', Localizations.localeOf(context).toString()).format(plan.weekStartDate)),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.weeklyPlanSubtitle(plan.days.length),
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  tooltip: l10n.historyTitle,
                  onPressed: _showHistory,
                ),
                PdfActionButton(onPressed: () => _generatePDF(plan)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF00E676)),
                  tooltip: l10n.regeneratePlanTitle,
                  onPressed: _regeneratePlan,
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
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.tipsTitle,
                style: GoogleFonts.poppins(
                  color: Colors.orange,
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
        Icon(Icons.local_fire_department, size: 14, color: Colors.orange.shade300),
        const SizedBox(width: 4),
        Text(
          '$cals ${l10n.caloriesEstimated}',
          style: GoogleFonts.poppins(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: (cals / 2000).clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.withValues(alpha: 0.5)),
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
      color: isToday ? const Color(0xFF00E676).withValues(alpha: 0.1) : Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isToday ? const Color(0xFF00E676) : Colors.white12,
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
                        color: const Color(0xFF00E676),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.todayLabel,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
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
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    dayNumber,
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
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
        return const Color(0xFFFFB74D);
      case 'almoco':
        return const Color(0xFF4CAF50);
      case 'lanche':
        return const Color(0xFFFF6B35);
      case 'jantar':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
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

  const DayPlanDetailsScreen({Key? key, required this.day}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toString();
    final dayName = DateFormat('EEEE, dd/MM/yyyy', locale).format(day.date);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          dayName,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: day.meals.length,
        itemBuilder: (context, index) {
          final meal = day.meals[index];
          return _buildMealCard(context, ref, meal, l10n);
        },
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, WidgetRef ref, Meal meal, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey.shade900,
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
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        TranslationMapper.localizeFoodName(meal.nomePrato ?? (meal.itens.isNotEmpty ? meal.itens.first.nome : l10n.mealDefault), l10n),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
        return const Color(0xFFFFB74D);
      case 'almoco':
        return const Color(0xFF4CAF50);
      case 'lanche':
        return const Color(0xFFFF6B35);
      case 'jantar':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
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
