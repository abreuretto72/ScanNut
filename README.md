# 🍎 Scannut - AI Visual Assistant

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Gemini](https://img.shields.io/badge/Gemini-2.5%20Flash-4285F4?logo=google)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Assistente Visual com IA para Análise Nutricional, Diagnóstico de Plantas e Triagem Veterinária**

Scannut é um aplicativo Flutter que utiliza o Google Gemini 2.5 Flash para análise inteligente de imagens em três categorias: alimentos, plantas e pets.

---

## ✨ Features

- **🧠 IA Avançada (Gemini 2.5 Flash)**:
  - 🍎 **Nutri Vision**: Identifica alimentos, calcula calorias com precisão e analisa macros.
  - 🍳 **Co-Piloto de Cozinha**: Sugere receitas completas (ingredientes + modo de preparo) baseadas no que você escaneou.
  - 🌿 **Botany AI**: Diagnostica saúde de plantas e sugere tratamentos orgânicos.
  - 🐾 **Vet Lens**: Triagem visual de condições dermatológicas em pets com níveis de urgência.

- **💎 Interface Premium (Design System)**:
  - **Experiência Imersiva**: Hero animations, Slivers e efeitos Glassmorphism.
  - **Dashboard Fluido**: Navegação por abas persistentes e gráficos interativos.
  - **Feedback Rico**: Micro-interações e transições suaves.

- **📊 Dashboard Interativo**:
  - Score de Vitalidade (1-10).
  - Gráficos de macros e metas diárias.
  - Alertas de riscos e benefícios.
  - 💡 Dicas - Benefícios e pontos de atenção

### 🌿 Diagnóstico de Plantas
- **Identificação de espécies**
- **Detecção de doenças** e pragas
- **Tratamentos orgânicos** recomendados
- **Nível de urgência** (baixo, médio, alto)

### 🐾 Triagem Veterinária + Gestão Completa
- **Análise visual** de feridas e condições de pele
- **Possíveis causas** identificadas
- **Nível de urgência** (Verde, Amarelo, Vermelho)
- **Cuidados imediatos** sugeridos
- **Botão de emergência** para acesso rápido a veterinários

#### 🆕 Identificação de Raça e Perfil Completo
- **Identificação de raça** com linhagem provável
- **Perfil comportamental** (energia, inteligência, sociabilidade)
- **Plano nutricional semanal** com Alimentação Natural (AN)
- **Tabelas de alimentos** benignos e malignos para a raça
- **Grooming personalizado** (pelagem, banho, tosa)
- **Saúde preventiva** (predisposições, checkups)

#### 💉 Protocolo de Imunização (NOVO!)
- **Vacinas essenciais** (V10/V8, Antirrábica, Gripe, Giárdia)
- **Calendário preventivo** (filhotes e adultos)
- **Prevenção parasitária** (vermífugos, pulgas/carrapatos)
- **Saúde bucal** (ossos naturais permitidos)
- **Alertas regionais** (Leishmaniose, Dirofilariose)
- **Checklist interativo** para marcar vacinas aplicadas

#### 📅 Agenda do Pet (NOVO!)
- **Gerenciamento de eventos** (vacinas, banho, tosa, veterinário, medicamentos)
- **Recorrência configurável** (única, diária, semanal, mensal, anual)
- **Notificações** antes dos eventos
- **3 visualizações** (Próximos, Passados, Todos)
- **Filtros por tipo** de evento
- **Badges visuais** (HOJE, ATRASADO)
- **Marcar como concluído**

#### 🍽️ Cardápio Semanal Inteligente
- **Rotação nutricional** automática
- **Exclusão de ingredientes** já utilizados
- **Gerar novo cardápio** para próxima semana
- **Histórico completo** de cardápios (em desenvolvimento)
- **PDF personalizado** com nome do pet

---

## 🎨 UI/UX Premium

### Design Moderno
- ✅ **Glassmorphism** e gradientes suaves
- ✅ **Dark mode** nativo
- ✅ **Haptic feedback** em interações
- ✅ **Animações fluidas** e micro-interações
- ✅ **Zero overflow** - Layout 100% responsivo

### Navegação Intuitiva
- 📱 **Menu Drawer** com 4 opções:
  - ⚙️ Configuração
  - ❓ Ajuda
  - ℹ️ Sobre
  - 🚪 Sair
- 🔄 **TabBar** para organização de informações
- 👆 **Cards clicáveis** com explicações detalhadas

### Interatividade
- 💡 **Score de Vitalidade** - Toque para ver explicação
- 🟢 **Benefícios** - Toque para lista completa
- 🟠 **Alertas** - Toque para pontos de atenção
- 📊 **Gráficos circulares** para visualização de dados

---

## 🛡️ Error Handling Robusto

### 11 Tipos de Erro Específicos
- ⏱️ **Timeout** - "A conexão demorou muito. Verifique seu Wi-Fi/4G."
- 🌐 **Network** - "Sem conexão com a internet."
- 📄 **Parse Error** - "Erro ao processar dados. Tente tirar a foto novamente."
- 🔴 **Server Error** - "Serviço temporariamente indisponível."
- 🖼️ **Invalid Image** - Validação de tamanho e integridade
- 🚫 **Rate Limit** - Controle de requisições
- ⚙️ **Configuration** - Validação de API key

### Validação de Imagem
- ✅ Verifica existência do arquivo
- ✅ Valida se não está vazio
- ✅ Limita tamanho máximo (4MB)
- ✅ Mensagens amigáveis ao usuário

### SnackBar Helper
- 🔴 **Erro** - Vermelho com ícone de alerta
- 🟢 **Sucesso** - Verde com ícone de check
- 🔵 **Info** - Azul com ícone de informação
- 🟠 **Aviso** - Laranja com ícone de atenção

---

## ⚙️ Configurações

### Personalizáveis
- 🎯 **Meta Diária de Calorias** (1500-3000 kcal)
- 👤 **Nome do Usuário**
- 💡 **Exibir/Ocultar Dicas**

### Presets Rápidos
- 1500 kcal
- 1800 kcal
- 2000 kcal (padrão)
- 2200 kcal
- 2500 kcal
- 3000 kcal

### Persistência
- 💾 **SharedPreferences** - Salvamento automático
- 🔄 **Restaurar Padrões** - Reset com um toque

---

## 🚀 Tecnologias

### Core
- **Flutter** 3.0+
- **Dart** 3.0+
- **Riverpod** 2.6+ - State management

### IA & API
- **Google Gemini 2.5 Flash** - Análise de imagens
- **Dio** 5.4+ - HTTP client
- **flutter_dotenv** - Gerenciamento de variáveis de ambiente

### UI/UX
- **google_fonts** - Tipografia (Poppins)
- **percent_indicator** - Gráficos circulares
- **camera** - Captura de imagens

### Armazenamento
- **shared_preferences** - Configurações do usuário
- **path_provider** - Gerenciamento de arquivos
- **hive_flutter** - Banco de dados local (histórico, agenda)

### Utilitários
- **uuid** - Geração de IDs únicos
- **intl** - Formatação de datas
- **pdf** + **printing** - Geração e compartilhamento de PDFs
- **share_plus** - Compartilhamento de arquivos

---

## 📦 Instalação

### Pré-requisitos
- Flutter SDK 3.0+
- Android Studio / VS Code
- Dispositivo Android ou iOS

### Passos

1. **Clone o repositório**
```bash
git clone https://github.com/seu-usuario/scannut.git
cd scannut
```

2. **Instale as dependências**
```bash
flutter pub get
```

3. **Configure a API Key**

Crie um arquivo `.env` na raiz do projeto:
```env
GOOGLE_API_KEY=sua_chave_aqui
```

> 📝 Obtenha sua chave em: https://makersuite.google.com/app/apikey

4. **Execute o app**
```bash
flutter run
```

---

## 🎯 Como Usar

### 1️⃣ Escolha o Modo
Selecione na barra inferior:
- 🍎 **Alimentos**
- 🌿 **Plantas**
- 🐾 **Pets**

### 2️⃣ Capture a Imagem
- Aponte a câmera para o objeto
- Toque no botão central para capturar

### 3️⃣ Aguarde a Análise
- A IA processará a imagem (5-10 segundos)
- Indicador de progresso será exibido

### 4️⃣ Explore os Resultados
- **Navegue pelas abas** (Visão Geral, Detalhes, Dicas)
- **Toque nos cards** para ver explicações
- **Salve no diário** para histórico

### 5️⃣ Configure sua Meta
- Abra o **menu** (☰)
- Vá em **Configuração**
- Defina sua **meta diária**

---

## 📊 Arquitetura

### Estrutura de Pastas
```
lib/
├── core/
│   ├── enums/           # ScannutMode
│   ├── models/          # AnalysisState
│   ├── providers/       # Riverpod providers
│   ├── services/        # GeminiService
│   └── utils/           # Helpers e factories
├── features/
│   ├── food/            # Análise de alimentos
│   ├── plant/           # Diagnóstico de plantas
│   ├── pet/             # Triagem veterinária
│   ├── home/            # Tela principal
│   ├── settings/        # Configurações
│   └── splash/          # Splash screen
└── main.dart
```

### Padrões Utilizados
- **Provider Pattern** - State management
- **Repository Pattern** - Acesso a dados
- **Factory Pattern** - Criação de prompts
- **Singleton Pattern** - Serviços

---

## 🔒 Segurança

### API Key
- ✅ Armazenada em `.env` (não versionado)
- ✅ Nunca exposta no código
- ✅ Validação na inicialização

### Dados do Usuário
- ✅ Armazenamento local (SharedPreferences)
- ✅ Sem envio de dados pessoais
- ✅ Imagens não são armazenadas

---

## 🐛 Troubleshooting

### Erro: "API Key não configurada"
**Solução:** Crie o arquivo `.env` com sua chave do Gemini

### Erro: "Modelo não encontrado"
**Solução:** O serviço tenta automaticamente outros modelos disponíveis

### Erro: "Sem conexão"
**Solução:** Verifique sua conexão Wi-Fi/4G

### Overflow na UI
**Solução:** Já corrigido! Layout 100% responsivo

---

## 🎨 Screenshots

### Tela Principal
- Camera preview com frame de scan
- Botão de menu (☰)
- Seletor de modo (Food/Plant/Pet)

### Análise de Alimentos
- Dashboard com gráficos
- Score de Vitalidade
- Macronutrientes
- Benefícios e Alertas

### Configurações
- Meta diária personalizável
- Presets rápidos
- Nome do usuário

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

---

## 📝 Changelog

### v2.0.0 (2025-12-20) - 🐾 Pet Management Update
#### Novas Funcionalidades
- ✅ **Agenda do Pet** - Sistema completo de gerenciamento de eventos
  - 6 tipos de eventos (vacina, banho, tosa, veterinário, medicamento, outro)
  - Recorrência configurável
  - Notificações antes dos eventos
  - Filtros e visualizações múltiplas
- ✅ **Protocolo de Imunização** - Caderneta de vacinação digital
  - Vacinas essenciais com calendário
  - Prevenção parasitária
  - Saúde bucal e óssea
  - Checklist interativo
- ✅ **Identificação de Raça** - Análise completa do pet
  - Perfil comportamental
  - Plano nutricional semanal (AN)
  - Tabelas de alimentos benignos/malignos
  - Grooming personalizado
- ✅ **Cardápio Semanal Inteligente**
  - Rotação nutricional automática
  - Geração de novos cardápios
  - PDF personalizado com nome do pet
- ✅ **Histórico de Pets** - Salvamento e recuperação de análises
  - Ícones de ação (agenda, cardápio, editar)
  - Visualização completa de dados salvos

#### Melhorias Técnicas
- ✅ Hive database para persistência local
- ✅ Deep conversion de Maps para compatibilidade
- ✅ Provider async para serviços
- ✅ Layout responsivo sem overflow
- ✅ Error handling aprimorado

### v1.0.0 (2025-01-19)
- ✅ Integração com Gemini 2.5 Flash
- ✅ Dashboard com TabBar
- ✅ Menu Drawer
- ✅ Configurações personalizáveis
- ✅ Error handling robusto
- ✅ Cards clicáveis com explicações
- ✅ Score de Vitalidade
- ✅ Layout sem overflow
- ✅ Símbolo ± para aproximações

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👨‍💻 Autor

**Seu Nome**
- GitHub: [@seu-usuario](https://github.com/seu-usuario)
- Email: seu-email@example.com

---

## 🙏 Agradecimentos

- **Google Gemini** - Por fornecer a API de IA
- **Flutter Team** - Pelo framework incrível
- **Comunidade Open Source** - Pelas bibliotecas utilizadas

---

## 🔮 Roadmap

### Próximas Features
- [ ] Histórico de análises
- [ ] Exportar relatórios em PDF
- [ ] Compartilhamento de resultados
- [ ] Modo offline com cache
- [ ] Suporte a múltiplos idiomas
- [ ] Integração com wearables
- [ ] Reconhecimento de voz

---

**Feito com ❤️ usando Flutter e Gemini AI**
