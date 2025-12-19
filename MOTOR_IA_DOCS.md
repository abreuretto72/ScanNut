# Motor de Inteligência Scannut - Documentação Técnica

## Arquitetura Implementada

### 1. **Camada de Serviço - GroqService**
📁 `lib/core/services/groq_service.dart`

**Responsabilidades:**
- Comunicação com a API da Groq
- Conversão de imagens para Base64
- Tratamento robusto de erros
- Logging para debugging

**Modelo Utilizado:** `llava-v1.5-7b-4096-preview` (Vision Model)

**Características:**
- ✅ Timeout configurável (30s conexão, 60s resposta)
- ✅ Interceptor de logging em modo debug
- ✅ Tratamento específico de erros (401, 429, timeout, etc.)
- ✅ Forçar resposta em JSON (`response_format: json_object`)
- ✅ Temperatura baixa (0.3) para respostas consistentes

### 2. **Gerenciamento de Estado - Riverpod**
📁 `lib/core/providers/analysis_provider.dart`
📁 `lib/core/models/analysis_state.dart`

**Estados Implementados:**
```dart
- AnalysisIdle: Estado inicial
- AnalysisLoading: Durante análise (com mensagem customizada)
- AnalysisSuccess<T>: Sucesso com dados tipados
- AnalysisError: Erro com mensagem amigável
```

**StateNotifier:**
- `AnalysisNotifier`: Gerencia o ciclo de vida completo da análise
- Método principal: `analyzeImage(File, ScannutMode)`
- Parsing automático baseado no modo selecionado

### 3. **Modelos de Dados Tipados**

**FoodAnalysisModel:**
```dart
- itemName: String
- estimatedCalories: int
- macronutrients: Macronutrients
- benefits: List<String>
- risks: List<String>
- advice: String
```

**PlantAnalysisModel:**
```dart
- plantName: String
- condition: String
- diagnosis: String
- organicTreatment: String
- urgency: String (low/medium/high)
```

**PetAnalysisResult:**
```dart
- especie: String
- descricaoVisual: String
- possiveisCausas: List<String>
- urgenciaNivel: String (Verde/Amarelo/Vermelho)
- orientacaoImediata: String
```

### 4. **Integração na UI - HomeView**

**Fluxo de Captura:**
1. Usuário clica no botão de captura
2. Foto é tirada e salva temporariamente
3. `AnalysisNotifier` é acionado
4. Estado muda para `AnalysisLoading` (overlay aparece)
5. Groq API processa a imagem
6. Estado muda para `AnalysisSuccess` ou `AnalysisError`
7. Modal Bottom Sheet é exibido com resultado

**Recursos Implementados:**
- ✅ Consumer widget para reatividade
- ✅ Mensagens de loading específicas por modo
- ✅ Prevenção de múltiplos cliques durante análise
- ✅ Reset de estado após salvar
- ✅ Tratamento de erros com SnackBar

### 5. **Prompts Mestres (PromptFactory)**
📁 `lib/core/utils/prompt_factory.dart`

**Estratégia:**
- Prompts em **inglês** para máxima precisão do modelo
- Instrução explícita: "Answer all string values in Portuguese (pt-BR)"
- Formato JSON estrito sem markdown
- Campos de erro para validação (`error: "not_food"`)

**Exemplo de Prompt (Food):**
```
Act as a professional nutritionist. Analyze the provided image...
Return a STRICT JSON object (no markdown) with:
{
  "item_name": "string",
  "estimated_calories": integer,
  ...
}
IMPORTANT: Answer all string values in the JSON in Portuguese (pt-BR).
```

## Configuração de Variáveis de Ambiente

📁 `.env` (raiz do projeto)
```env
GROQ_API_KEY=your_groq_api_key_here
BASE_URL=https://api.groq.com/openai/v1
```

**Carregamento:**
```dart
await dotenv.load(fileName: ".env");
```

## Benefícios da Arquitetura

### ✅ Tipagem Forte
- Objetos Dart reais, não strings
- Autocomplete e type-safety
- Fácil integração com widgets

### ✅ Velocidade
- Groq LLaVA: respostas em < 2 segundos
- Modelo otimizado para visão computacional

### ✅ Robustez
- StateNotifier previne race conditions
- Tratamento granular de erros
- Logging completo para debugging

### ✅ Escalabilidade
- Fácil adicionar novos modos
- Provider pattern facilita testes
- Separação clara de responsabilidades

## Como Usar

```dart
// 1. Capturar imagem
final image = await _controller!.takePicture();
final File imageFile = File(image.path);

// 2. Determinar modo
final mode = ScannutMode.food; // ou plant, pet

// 3. Acionar análise
await ref.read(analysisNotifierProvider.notifier).analyzeImage(
  imageFile: imageFile,
  mode: mode,
);

// 4. Observar estado
ref.listen(analysisNotifierProvider, (previous, next) {
  if (next is AnalysisSuccess) {
    // Exibir resultado
  } else if (next is AnalysisError) {
    // Exibir erro
  }
});
```

## Próximos Passos Sugeridos

1. **Persistência:** Implementar Hive/SQLite para salvar histórico
2. **Cache:** Armazenar resultados para evitar re-análises
3. **Offline:** Fallback quando sem internet
4. **Analytics:** Tracking de uso e performance
5. **Testes:** Unit tests para GroqService e Notifiers

---

**Desenvolvido com Clean Architecture + Riverpod + Groq AI**
