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
- **Análise de Feridas com IA**: Sistema completo de diagnóstico visual de lesões cutâneas com armazenamento permanente de fotos, histórico temporal e classificação de severidade (Alta/Média/Baixa).
- **Inteligência Diagnóstica**: Explicação automática de exames de sangue item por item para fácil compreensão.
- **Plano Alimentar Inteligente**: Sugestões semanais personalizadas (Natural, Ração ou Híbrida) com foco em preferências e alergias alimentares.
- **Controle Biológico e Bioestatística**: Perfil biológico, análise da raça, controle de peso inteligente e galeria de fotos integrada.
- **Hub de Parceiros**: Encontre veterinários, pet shops e adestradores próximos com geolocalização e adicione-os ao prontuário do seu pet.
- **Organização Total**: Diário por voz, agenda global, histórico de higiene, anexos de receitas e carteira de vacinação digital.
- **PDF Médico Profissional**: Gere relatórios completos (histórico, saúde, parceiros, galeria) totalmente localizados em PT/EN/ES para compartilhar com seu veterinário.
- **Histórico de Pets**: Acesse dossiês completos e exames de todos os seus pets em um só lugar.

### 4. ScanNut Pro: Potencialize Sua Experiência
Desbloqueie o máximo potencial da IA com a assinatura Pro.
- **Análises de Saúde Pet Ilimitadas**: Diagnósticos de pele e interpretação de exames sem limites.
- **Sinergia Nutricional**: Entenda como vitaminas e minerais interagem no seu prato.
- **Acesso Antecipado**: Seja o primeiro a usar novos recursos de IA.
- **Sem Anúncios**: Experiência fluida e focada.

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
- `box_partners` - Parceiros e profissionais vinculados

---

## ✨ Destaques do ScanNut
- **Multilíngue**: Suporte total em Inglês, Português (BR/PT) e Espanhol.
- **Segurança de Dados**: Criptografia de ponta para suas fotos e prontuários médicos.
- **Exportação Inteligente**: Transforme meses de registros em um documento PDF organizado com um clique.
- **Monetização Híbrida**: Modelo Freemium com RevenueCat para gestão de assinaturas.

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

*   **Análise de Comida (Human/Pet):** Toda a lógica de análise de imagem em `lib/features/food/`. Inclui cálculos de macronutrientes, semáforo de saúde e biohacking.
*   **Análise de Plantas (Botânica):** Sistema completo em `lib/features/plant/`. Inclui diagnóstico, guia de sobrevivência, segurança (BIOS) e lifestyle.
*   **Gestão de Pets (Completo):** Módulo finalizado com Prontuário, PDF Generator, Galeria, Agenda Global e Hub de Parceiros.
*   **Gestão de Nutrição:** Gerador de planos semanais e logs em `lib/nutrition/`.
*   **Infraestrutura:** RevenueCat (Assinaturas), Hive (Banco de Dados) e Serviços de Exportação PDF.

---

