import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'weekly_plan_screen.dart';

/// Tela principal do módulo de Gestão de Nutrição
/// MVP - Offline-First com Hive
class NutritionHomeScreen extends StatefulWidget {
  const NutritionHomeScreen({Key? key}) : super(key: key);

  @override
  State<NutritionHomeScreen> createState() => _NutritionHomeScreenState();
}

class _NutritionHomeScreenState extends State<NutritionHomeScreen> {
  int _selectedIndex = 0;

  final List<_NavigationItem> _navItems = [
    _NavigationItem(
      icon: Icons.restaurant_menu,
      label: 'Vou comer',
      color: const Color(0xFF00E676),
    ),
    _NavigationItem(
      icon: Icons.check_circle_outline,
      label: 'Comi',
      color: const Color(0xFF2196F3),
    ),
    _NavigationItem(
      icon: Icons.shopping_cart_outlined,
      label: 'Compras',
      color: const Color(0xFFFF6B35),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        title: Text(
          'Gestão de Nutrição',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () {
              // TODO: Navegar para ajustes do módulo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ajustes em desenvolvimento')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    try {
      switch (_selectedIndex) {
        case 0:
          return const WeeklyPlanScreen();
        case 1:
          return _buildPlaceholder(
            'Comi',
            Icons.check_circle_outline,
            'O que você já comeu hoje',
            _navItems[1].color,
          );
        case 2:
          return _buildPlaceholder(
            'Lista de Compras',
            Icons.shopping_cart_outlined,
            'Ingredientes para o que você vai comer',
            _navItems[2].color,
          );
        default:
          return const Center(child: Text('Erro'));
      }
    } catch (e) {
      debugPrint('Erro ao construir body: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar conteúdo',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPlaceholder(String title, IconData icon, String subtitle, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
              ),
              child: Icon(icon, size: 80, color: color),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Funcionalidade em desenvolvimento\nDados salvos localmente (Hive)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _selectedIndex == index;
              
              return InkWell(
                onTap: () => setState(() => _selectedIndex = index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? item.color.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? item.color : Colors.white54,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isSelected ? item.color : Colors.white54,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;
  final Color color;

  _NavigationItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
