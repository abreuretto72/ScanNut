import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RaceNutritionTables extends StatefulWidget {
  final List<Map<String, String>> benigna;
  final List<Map<String, String>> maligna;
  final String raceName;

    const RaceNutritionTables({super.key, required this.benigna, required this.maligna, required this.raceName});

  @override
  State<RaceNutritionTables> createState() => _RaceNutritionTablesState();
}

class _RaceNutritionTablesState extends State<RaceNutritionTables> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.poppins(),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Aliados',
                            style: GoogleFonts.poppins(color: Colors.greenAccent),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cancel, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Inimigos',
                            style: GoogleFonts.poppins(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 400, // Fixed height for the list/table area
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTableList(widget.benigna, true),
                    _buildTableList(widget.maligna, false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableList(List<Map<String, String>> items, bool isBenign) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma informação disponível.',
          style: GoogleFonts.poppins(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item['alimento'] ?? 'Alimento';
        final detail = isBenign 
            ? item['beneficio_especifico_raca'] 
            : item['risco_especifico_raca'];
        final extra = isBenign 
            ? "Preparo: ${item['modo_preparo']}" 
            : "Efeito: ${item['efeito_fisiologico']}";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isBenign 
                ? Colors.green.withOpacity(0.05) 
                : Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBenign 
                  ? Colors.green.withOpacity(0.2) 
                  : Colors.red.withOpacity(0.2),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isBenign 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBenign ? Icons.thumb_up : Icons.warning_amber,
                  color: isBenign ? Colors.greenAccent : Colors.redAccent,
                  size: 20,
                ),
              ),
              title: Text(
                name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                detail ?? '',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Icon(
                        isBenign ? Icons.restaurant_menu : Icons.medical_services,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          extra,
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
