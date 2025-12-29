# ScanNut: IA para Alimentos, Biohacking e Gestão Pet

**Sua IA para Performance Humana, Botânica Avançada e Saúde Pet: analise alimentos e biohacking, diagnóstico de plantas e gestão clínica completa de pets.**

ScanNut: Otimize sua vida, seu ambiente e a saúde do seu pet com o poder da Inteligência Artificial.

O ScanNut é a ferramenta definitiva para quem busca alta performance, segurança ambiental e organização clínica de nível profissional. Com tecnologia de ponta, entregamos diagnósticos visuais profundos para humanos, inteligência botânica avançada e a mais completa gestão de saúde para animais de estimação.

---

## 🚀 Principais Pilares

### 1. Biohacking & Nutrição: Análise Inteligente de Alimentos
Transforme sua câmera em um consultor nutricional de elite.
- **Avaliação de Performance**: Analise alimentos sob a ótica do Biohacking. Saiba como cada item impacta sua energia e desempenho.
- **Raio-X Nutricional**: Scanner de ultraprocessados com identificação de macros, vitaminas, minerais, calorias e pontos de atenção.
- **Inteligência Culinária**: Dicas de especialistas, segurança alimentar e receitas exclusivas para uma dieta otimizada.
- **Dashboard Fitness**: Acompanhe seu balanço calórico diário com visualização em tempo real de calorias consumidas vs. queimadas.
- **Histórico Nutricional**: Acesse todo seu histórico de análises de alimentos com busca e filtros avançados.

### 2. Engenharia Botânica: Inteligência de Ecossistemas
Domine o reino vegetal ao seu redor com ciência e estética.
- **Diagnóstico Clínico & Recuperação**: Identifique doenças em plantas e receba planos de tratamento.
- **Semáforo de Sobrevivência**: Alertas de toxicidade, segurança doméstica e ajustes de estação (luz, água e solo).
- **Biofilia e Bem-estar**: Feng Shui botânico, estética viva e engenharia de propagação para multiplicar seu ecossistema.
- **Histórico Botânico**: Mantenha um jardim digital com todas as suas análises de plantas e diagnósticos.

### 3. Gestão Digital de Pets: O Prontuário Clínico Definitivo
O cuidado que seu melhor amigo merece, organizado de forma profissional e inteligente.
- **Análise de Pele com IA**: Monitore lesões e feridas cutâneas com histórico visual e evolução temporal.
- **Inteligência Diagnóstica**: Explicação automática de exames de sangue item por item para fácil compreensão.
- **Plano Alimentar Inteligente**: Sugestões semanais personalizadas (Natural, Ração ou Híbrida) com foco em preferências e alergias alimentares.
- **Controle Biológico e Bioestatística**: Perfil biológico, análise da raça, controle de peso inteligente e galeria de fotos integrada.
- **Organização Total**: Diário por voz para vacinas e sintomas, agenda do pet, histórico de higiene, anexos de receitas e carteira de vacinação digital.
- **Ecossistema de Parceiros**: Conecte-se a serviços vinculados e profissionais de confiança diretamente pelo app.
- **PDF Médico Profissional**: Gere relatórios completos com todas as informações, fotos de feridas e histórico clínico para compartilhar com seu veterinário.
- **Histórico de Pets**: Acesse dossiês completos e exames de todos os seus pets em um só lugar.

---

## 🏗️ Arquitetura de Dados Local-First

O ScanNut utiliza uma arquitetura **local-first** robusta com **Hive** para garantir:
- ✅ **100% Offline**: Todos os dados funcionam sem internet
- ✅ **Alta Performance**: Acesso instantâneo aos dados
- ✅ **Privacidade Total**: Seus dados permanecem no seu dispositivo
- ✅ **Sincronização Inteligente**: Limpeza automática de cache temporário

### Boxes Hive Implementados:
- `box_nutrition_human` - Histórico de análises nutricionais
- `box_botany_intel` - Histórico de análises botânicas
- `box_workouts` - Registro de treinos e calorias queimadas
- `box_user_profile` - Perfil do usuário (peso, altura, metas)
- `box_pets_master` - Perfis completos dos pets
- `box_pet_events` - Eventos e histórico dos pets
- `box_pet_health` - Dados de saúde e exames
- `box_weekly_meal_plans` - Planos alimentares semanais

---

## ✨ Destaques do ScanNut
- **Multilíngue**: Suporte total em Inglês, Português (BR/PT) e Espanhol.
- **Segurança de Dados**: Criptografia de ponta para suas fotos e prontuários médicos.
- **Exportação Inteligente**: Transforme meses de registros em um documento organizado com um clique.

---

## ⚠️ Aviso Legal
As análises de alimentos, plantas e pele de pets são geradas por Inteligência Artificial para fins informativos. O ScanNut não substitui o diagnóstico de médicos ou veterinários profissionais.

---

## 🛠️ Tecnologias e Primeiros Passos

### Pré-requisitos
- Flutter SDK **≥ 3.19**
- Android SDK (API 33 recomendado)
- Google Play Services (para Mapas/Localização)

### Instalação
```bash
git clone https://github.com/abreuretto72/ScanNut.git
cd ScanNut
flutter pub get
flutter run
```

---
**Multiverso Digital** | contato@multiversodigital.com.br

---

## 🚫 Módulos Blindados e Congelados (Stable)

Os seguintes módulos foram marcados como **estáveis e blindados** (Data: 29/12/2025). Nenhuma alteração em suas rotinas internas, lógicas de cálculo ou geração de dados deve ser realizada sem autorização explícita. Estes módulos estão protegidos por banners de "NÃO ALTERAR" em seus respectivos serviços:

*   **Análise de Comida (Human/Pet):** Toda a lógica de análise de imagem e extração nutricional em `lib/features/food/`. Inclui cálculos de macronutrientes, semáforo de saúde e biohacking.
*   **Análise de Plantas (Botânica):** Sistema completo de análise botânica com 7 camadas de inteligência em `lib/features/plant/`. Inclui diagnóstico de saúde, guia de sobrevivência (hardware), segurança doméstica (BIOS), propagação, ecossistema e lifestyle (Feng Shui). Geração de Dossiê Botânico Premium em PDF.
*   **Gestão de Nutrição:** O gerador de planos semanais (`WeeklyPlanGenerator`), lógica de substituição de refeições e interface de gestão em `lib/nutrition/`.
*   **Bases de Dados Estáticas:** Arquivos JSON de referência `assets/data/foods_ptbr.json` e `assets/data/recipes_ptbr.json`.
*   **Visualização de PDF:** Componente `PdfPreviewScreen` com padrão visual Black Side e ações padronizadas (Imprimir, Abrir, Compartilhar) em `lib/core/widgets/`.

---

## 🐾 Módulo em Refinamento Ativo: Gestão de Pets

**Status:** Desbloqueado para melhorias e refinamentos (29/12/2025)

O módulo de **Pets** está passando por um processo de refinamento para alcançar o mesmo nível de excelência dos módulos de Comida e Plantas. Funcionalidades atuais:

*   **Prontuário Clínico Completo:** Gestão de dados vitais, raça, idade e análise comportamental
*   **Histórico de Saúde:** Controle de vacinas, vermífugos, exames laboratoriais
*   **Dermatologia:** Histórico de feridas com análise por IA
*   **Biometria:** Acompanhamento de peso e evolução
*   **Agenda:** Lembretes de consultas e procedimentos
*   **Nutrição Pet:** Planejamento alimentar semanal
*   **PRAC:** Prontuário de Acompanhamento Comportamental

**Foco do Refinamento:**
- Padronização visual com os módulos de Comida e Plantas
- Melhorias na UX e fluxos de navegação
- Otimização de exportação de dados
- Aprimoramento de funcionalidades existentes

