# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2025-12-22
### 🐾 Parceiros & Agenda Global
- **Integração WhatsApp**: Botão direto nos cards de parceiros para comunicação instantânea via `wa.me`.
- **Relatórios PDF Premium (Padrão FinAgeVoz)**: 
  - Cabeçalho azul com linha preta e logo.
  - Indicadores coloridos de status (Total, Concluído, Pendente).
  - Tabela detalhada azul com grade completa.
  - Uso nativo da `PdfPreviewScreen` com opções de Impressão e Compartilhamento.
- **Agenda Digital Aprimorada**:
  - Nova visualização detalhada de eventos com labels descritivas.
  - Layout anti-overflow com scroll garantido e margem de segurança.
  - Edição completa de títulos, categorias, atendentes e observações.
- **Sincronização de Dados**: Melhoria na persistência de eventos vinculados entre agenda e perfil do pet.

## [1.1.0] - 2025-12-19
### ✨ Nova Interface (Premium UX)
- **Design Apple-Style**: Implementada `SliverAppBar` com imagem Hero expansível e parallax.
- **Glassmorphism**: Novos componentes translúcidos com blur para badges e cards.
- **Navegação Inteligente**: TabBar persistente (Resumo, Detalhes, Receitas) que fixa no topo ao rolar.
- **Animações**: Transições de tela fluidas e feedback tátil em todos os elementos.

### 🍳 Receitas Inteligentes
- **IA Chef**: O Gemini agora sugere 2-3 receitas baseadas no ingrediente identificado.
- **Modo Cozinha**: Nova aba dedicada para visualização de receitas.
- **Cards Expansíveis**: Detalhes de tempo de preparo, dificuldade, ingredientes extras e passo a passo.

### 🛠️ Melhorias Técnicas
- **Refatoração**: Criação da `FoodResultScreen` separada com `NestedScrollView`.
- **Performance**: Otimização do carregamento de imagens e renderização de listas.
- **Prompt Engineering**: Ajuste no prompt do Gemini para retornar JSON estruturado de receitas.

## [1.0.0] - 2025-12-19

### ✨ Features
- **Smart Analysis**: Integrated Google Gemini 2.5 Flash for advanced image analysis of food, plants, and pets.
- **Interactive Dashboard**: New dashboard with "Visão Geral", "Detalhes", and "Dicas" tabs.
- **Vitality Score**: Implemented a 1-10 vitality score algorithm with benefits and risks calculation.
- **Navigation Drawer**: Added a premium sidebar menu with Settings, Help, About, and Exit options.
- **Settings System**:
  - Customizable daily calorie goal.
  - User name personalization.
  - Toggle for tips visibility.
- **Macro Tracking**: Visual breakdown of Protein, Carbs, and Fats with detailed explanation dialogs.
- **Educational Popups**: Tap-to-learn interactions for Vitality Score, Benefits, Alerts, and Macronutrients.

### 🎨 UI/UX
- **Glassmorphism Design**: Modern, translucent UI elements.
- **Responsive Layout**: Fixed all overflow issues in result cards.
- **Haptic Feedback**: Added tactile response to interactions.
- **Dynamic Icons**: Context-aware icons for different analysis modes.
- **Animations**: Smooth transitions between tabs and dialogs.

### 🔧 Improvements
- **Error Handling**: Comprehensive error management for Network, Timeout, and API issues.
- **Formatting**: Replaced "aproximadamente" with "±" symbol for cleaner data presentation.
- **Performance**: Optimized image comparison and prompt generation.
- **Privacy**: Secured API keys and user data.

### 🐛 Fixes
- Fixed text overflow in macronutrient cards.
- Resolved "Null" display issues in approximate values.
- Corrected API key validation flow.
