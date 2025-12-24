import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/weekly_plan.dart';
import '../../data/models/plan_day.dart';
import '../../data/models/meal.dart';
import '../controllers/nutrition_providers.dart';
import '../widgets/create_menu_dialog.dart';
import '../widgets/hive_debug_panel.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text('Refazer a semana?', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          'Isso vai criar um novo cardápio para a semana. O atual será substituído.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
            child: Text('Refazer', style: GoogleFonts.poppins(color: Colors.black)),
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
              const SnackBar(
                content: Text('✅ Cardápio da semana refeito!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao regerar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCreateMenuDialog() async {
    try {
      debugPrint('[CriarCardapio] Botão tocado');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abrindo configuração...'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF00E676),
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

          if (profile != null) {
            await ref.read(currentWeekPlanProvider.notifier).generateNewPlan(profile);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Cardápio criado!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
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

  @override
  Widget build(BuildContext context) {
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
              'Erro ao carregar o cardápio',
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
              child: Text('Tentar Novamente', style: GoogleFonts.poppins(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    final plan = ref.watch(currentWeekPlanProvider);

    if (plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'Você ainda não tem um cardápio',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showCreateMenuDialog,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
              child: Text('Criar Cardápio', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header com ações
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
                      'Semana de ${DateFormat('dd/MM').format(plan.weekStartDate)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'O que você vai comer nos próximos ${plan.days.length} dias',
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Botão Debug (apenas em DEBUG mode)
              if (kDebugMode)
                IconButton(
                  icon: const Icon(Icons.bug_report, color: Colors.red),
                  tooltip: 'Debug Hive',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HiveDebugPanel(),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF00E676)),
                tooltip: 'Refazer cardápio da semana',
                onPressed: _regeneratePlan,
              ),
            ],
          ),
        ),
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
    );
  }

  Widget _buildDayCard(PlanDay day) {
    final isToday = _isToday(day.date);
    final dayName = DateFormat('EEEE', 'pt_BR').format(day.date);
    final dayNumber = DateFormat('dd/MM').format(day.date);

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
                        'HOJE',
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
            _getMealLabel(meal.tipo),
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

  String _getMealLabel(String tipo) {
    switch (tipo) {
      case 'cafe':
        return 'Café';
      case 'almoco':
        return 'Almoço';
      case 'lanche':
        return 'Lanche';
      case 'jantar':
        return 'Jantar';
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
    final dayName = DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(day.date);

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
          return _buildMealCard(context, ref, meal);
        },
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, WidgetRef ref, Meal meal) {
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
                        _getMealLabel(meal.tipo),
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        meal.itens.isNotEmpty ? meal.itens.first.nome : 'Refeição',
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
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _consumeMeal(context, ref, meal),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text('Consumir', style: GoogleFonts.poppins(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00E676),
                      side: const BorderSide(color: Color(0xFF00E676)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _swapMeal(context, ref, meal),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: Text('Trocar', style: GoogleFonts.poppins(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _consumeMeal(BuildContext context, WidgetRef ref, Meal meal) {
    // TODO: Implementar consumo (criar MealLog)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${_getMealLabel(meal.tipo)} registrado no diário!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _swapMeal(BuildContext context, WidgetRef ref, Meal meal) {
    // TODO: Implementar troca de refeição
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Troca de refeição em desenvolvimento'),
        backgroundColor: Colors.orange,
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

  String _getMealLabel(String tipo) {
    switch (tipo) {
      case 'cafe':
        return 'Café da Manhã';
      case 'almoco':
        return 'Almoço';
      case 'lanche':
        return 'Lanche';
      case 'jantar':
        return 'Jantar';
      default:
        return tipo;
    }
  }
}
