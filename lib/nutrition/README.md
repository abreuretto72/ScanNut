# 🍽️ Módulo de Gestão de Nutrição

## Visão Geral

Módulo MVP (Minimum Viable Product) de gestão nutricional integrado ao ScanNut, com arquitetura **offline-first** usando Hive para persistência local.

## 📁 Estrutura

```
lib/nutrition/
├── data/
│   ├── models/              # Modelos Hive (TypeIds 24-30)
│   │   ├── user_nutrition_profile.dart
│   │   ├── meal.dart
│   │   ├── meal_log.dart
│   │   ├── plan_day.dart
│   │   ├── weekly_plan.dart
│   │   └── shopping_list_item.dart
│   ├── datasources/         # Serviços Hive
│   │   ├── nutrition_profile_service.dart
│   │   ├── weekly_plan_service.dart
│   │   ├── meal_log_service.dart
│   │   ├── shopping_list_service.dart
│   │   └── nutrition_data_service.dart
│   └── repositories/        # (Futuro)
├── domain/
│   ├── entities/            # (Futuro)
│   └── usecases/            # Lógica de negócio
│       ├── weekly_plan_generator.dart
│       ├── shopping_list_generator.dart
│       └── scan_to_nutrition_mapper.dart
├── presentation/
│   ├── screens/
│   │   └── nutrition_home_screen.dart
│   ├── widgets/             # (Futuro)
│   └── controllers/
│       └── nutrition_providers.dart
└── nutrition_hive_adapters.dart
```

## 🗄️ Boxes Hive

| Box Name | TypeId | Modelo | Descrição |
|----------|--------|--------|-----------|
| `nutrition_user_profile` | 24 | UserNutritionProfile | Perfil nutricional do usuário |
| `nutrition_weekly_plans` | 25-28 | WeeklyPlan | Planos semanais de refeições |
| `nutrition_meal_logs` | 29 | MealLog | Logs de refeições consumidas |
| `nutrition_shopping_list` | 30 | ShoppingListItem | Lista de compras |

## 🎯 Funcionalidades

### A) Perfil Nutricional
- Objetivo: emagrecer, manter, saúde, ganhar massa
- Restrições: sem lactose, sem glúten, diabetes, hipertensão, vegetariano, vegano
- Metas: refeições semanais e água diária
- Horários padrão: café, almoço, lanche, jantar

### B) Plano Semanal Automático
- Geração de 7 dias com 4 refeições/dia
- Respeita restrições alimentares
- Troca individual de refeições
- Regeneração completa do plano
- Seed para reproduzibilidade

### C) Diário Alimentar
- Registro manual de refeições
- Consumo direto do plano (1 toque)
- Integração com scan de alimentos
- Edição e remoção de logs
- Cálculo de aderência ao plano

### D) Lista de Compras
- Geração automática do plano semanal
- Agregação de itens duplicados
- Marcar itens comprados
- Limpar itens completos

### E) Progresso
- Aderência semanal (%)
- Histórico de logs
- Filtros por período

### F) Integração com Scan
- Botão "Adicionar ao Diário"
- Botão "Adicionar ao Plano"
- Modal de seleção de tipo de refeição
- Preservação de macros

## 📊 Base de Dados Offline

### Alimentos (`assets/data/foods_ptbr.json`)
- 30 alimentos brasileiros comuns
- Informações: calorias, proteínas, carboidratos, gorduras, fibras
- Categorias: cereais, leguminosas, proteínas, tubérculos, frutas, vegetais, laticínios, pães, oleaginosas, bebidas

### Receitas (`assets/data/recipes_ptbr.json`)
- 10 receitas simples de 5-15 minutos
- Informações: ingredientes, modo de preparo, macros, restrições
- Dificuldade: muito fácil, fácil, média

## 🔧 Como Usar

### 1. Inicialização (já feito no main.dart)

```dart
// Registrar adapters
NutritionHiveAdapters.registerAdapters();

// Inicializar serviços
await NutritionProfileService().init();
await WeeklyPlanService().init();
await MealLogService().init();
await ShoppingListService().init();
```

### 2. Carregar Dados Offline

```dart
final dataService = NutritionDataService();
await dataService.loadData();
```

### 3. Usar Providers

```dart
// Perfil
final profile = ref.watch(nutritionProfileProvider);

// Plano semanal
final plan = ref.watch(currentWeekPlanProvider);
await ref.read(currentWeekPlanProvider.notifier).generateNewPlan(profile!);

// Logs
final logs = ref.watch(mealLogsProvider);
await ref.read(mealLogsProvider.notifier).addLog(mealLog);

// Lista de compras
final items = ref.watch(shoppingListProvider);
await ref.read(shoppingListProvider.notifier).generateFromPlan(plan!);
```

### 4. Integração com Scan

```dart
// Mapper
final mealLog = ScanToNutritionMapper.createMealLogFromScan(
  analysis: foodAnalysis,
  tipo: 'almoco',
);

// Adicionar ao diário
await ref.read(mealLogsProvider.notifier).addLog(mealLog);
```

## 📝 Como Adicionar Alimentos/Receitas

### Adicionar Alimento

Edite `assets/data/foods_ptbr.json`:

```json
{
  "id": "novo_alimento",
  "nome": "Nome do Alimento",
  "categoria": "categoria",
  "porcao": "1 unidade (100g)",
  "calorias": 100,
  "proteinas": 5.0,
  "carboidratos": 20.0,
  "gorduras": 2.0,
  "fibras": 3.0
}
```

### Adicionar Receita

Edite `assets/data/recipes_ptbr.json`:

```json
{
  "id": "nova_receita",
  "nome": "Nome da Receita",
  "tempoPreparo": "15 minutos",
  "dificuldade": "fácil",
  "porcoes": 1,
  "ingredientes": ["ingrediente 1", "ingrediente 2"],
  "modoPreparo": "Modo de preparo detalhado",
  "calorias": 300,
  "proteinas": 15.0,
  "carboidratos": 40.0,
  "gorduras": 10.0,
  "restricoes": ["vegetariano", "sem_lactose"]
}
```

**Restrições disponíveis**: `sem_lactose`, `sem_gluten`, `vegetariano`, `vegano`, `diabetes`, `hipertensao`

## 🧪 Como Testar

### 1. Compilar o App

```bash
flutter pub get
flutter run
```

### 2. Testar Fluxo Completo

1. Abrir o app
2. Ir no Drawer → "Gestão de Nutrição"
3. Navegar pelas 4 seções (Plano, Diário, Compras, Progresso)
4. Fazer scan de um alimento
5. Clicar em "Adicionar ao Diário" ou "Adicionar ao Plano"
6. Verificar que foi salvo

### 3. Verificar Persistência

1. Fechar o app
2. Reabrir
3. Verificar que os dados continuam salvos

## 🛡️ Tratamento de Erros

Todos os métodos críticos possuem try/catch:

```dart
try {
  // Operação
} catch (e) {
  debugPrint('❌ Error: $e');
  // Fallback ou UI amigável
}
```

## 📈 Próximas Melhorias (Opcional)

- [ ] Telas detalhadas para cada seção
- [ ] Gráficos de progresso (fl_chart)
- [ ] Tela de setup do perfil
- [ ] Sincronização com nuvem (opcional)
- [ ] Mais alimentos e receitas
- [ ] Suporte a mais idiomas

## 🔗 Integração

O módulo está totalmente integrado com:
- ✅ Hive (persistência)
- ✅ Riverpod (state management)
- ✅ Material 3 (design)
- ✅ Scan de alimentos (FoodResultScreen)
- ✅ Drawer (navegação)

## 📄 Licença

Parte do projeto ScanNut - Multiverso Digital © 2025

---

**Desenvolvido com ❤️ usando Flutter & Hive**
