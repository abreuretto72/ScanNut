# 🧪 GUIA DE TESTE - Eventos de Alimentação e Saúde

## ✅ **APP RODANDO NO DISPOSITIVO**

---

## 📋 **O QUE TESTAR**

### **1. Evento de Alimentação (CORRIGIDO)**
### **2. Evento de Saúde (NOVO)**

---

## 🍽️ **TESTE 1: EVENTO DE ALIMENTAÇÃO**

### **Objetivo:** Verificar que IDs técnicos NÃO aparecem mais na UI

### **Passo a Passo:**

#### **1.1 Abrir Evento de Alimentação**
```
1. Abrir o app
2. Navegar para perfil de um pet
3. Tocar no card "Alimentação" 🍽
4. BottomSheet abre
```

#### **1.2 Verificar Dropdown Categorizado**
```
✅ VERIFICAR:
- Há um dropdown (não chips)
- Dropdown tem placeholder "Tipo de Ocorrência"
- Tocar no dropdown abre lista organizada
```

#### **1.3 Verificar Grupos e Tradução**
```
Tocar no dropdown e verificar:

✅ GRUPO 1: "Alimentação Normal"
   - Refeição realizada
   - Refeição atrasada
   - Refeição pulada
   - Troca de alimento
   - Redução da ingestão
   - Aumento do apetite

✅ GRUPO 2: "Ocorrências Comportamentais"
   - Relutância em comer
   - Come devagar
   - Come muito rápido
   - Seleciona alimento
   - Esconde comida
   - Agressividade ao comer
   - Ansiedade ao se alimentar

✅ GRUPO 3: "Intercorrências Digestivas"
   - Vômito imediato
   - Vômito tardio
   - Náusea
   - Engasgo
   - Regurgitação
   - Flatulência excessiva
   - Dor abdominal aparente

✅ GRUPO 4: "Intercorrências Intestinais"
   - Diarreia
   - Fezes amolecidas
   - Constipação
   - Fezes com muco
   - Fezes com sangue
   - Alteração de cor das fezes
   - Odor fecal anormal

✅ GRUPO 5: "Nutricional/Metabólico"
   - Ganho de peso
   - Perda de peso
   - Sede excessiva
   - Baixa ingestão de água
   - Suspeita de intolerância alimentar
   - Suspeita de alergia alimentar
   - Reação adversa ao alimento

✅ GRUPO 6: "Dieta Terapêutica"
   - Dieta não tolerada
   - Recusa de dieta terapêutica
   - Melhora clínica com dieta
   - Piora clínica após refeição
   - Necessidade de ajuste de dieta
   - Alimentação associada a medicamento
   - Alimentação assistida (seringa/sonda)

❌ VERIFICAR QUE NÃO APARECE:
   - mealSkipped
   - vomitingImmediate
   - diarrhea
   - Nenhum ID técnico!
```

#### **1.4 Testar Evento Normal**
```
1. Selecionar "Refeição realizada"
2. Verificar que campos aparecem:
   - Quantidade Ingerida
   - Aceitação (Boa/Parcial/Recusou)
3. Preencher:
   - Quantidade: "200g"
   - Aceitação: "Boa"
4. Adicionar nota: "Comeu tudo rapidamente"
5. Salvar
6. ✅ Evento salvo com sucesso
```

#### **1.5 Testar Evento Clínico**
```
1. Tocar em "Alimentação" novamente
2. Selecionar "Vômito imediato"
3. Verificar que:
   - ✅ Campo "Gravidade" aparece
   - ✅ Toggle "Intercorrência clínica" AUTO-ATIVADO
   - ✅ Alerta laranja aparece
4. Selecionar gravidade: "Moderada"
5. Adicionar nota: "Vômito 30min após refeição"
6. Salvar
7. ✅ Evento salvo como intercorrência
```

#### **1.6 Verificar Histórico**
```
1. Ir para histórico de eventos
2. Verificar que aparecem:
   - ✅ "Refeição realizada" (não "mealCompleted")
   - ✅ "Vômito imediato" (não "vomitingImmediate")
3. ✅ ZERO IDs técnicos visíveis
```

---

## 🏥 **TESTE 2: EVENTO DE SAÚDE**

### **Objetivo:** Verificar novo sistema de saúde com 52 eventos

### **Passo a Passo:**

#### **2.1 Abrir Evento de Saúde**
```
1. Navegar para perfil do pet
2. Tocar no card "Saúde" 🏥
3. BottomSheet abre
```

#### **2.2 Verificar Dropdown Categorizado**
```
✅ VERIFICAR:
- Há um dropdown
- Placeholder: "Selecione o tipo de ocorrência"
- Tocar no dropdown abre lista organizada
```

#### **2.3 Verificar Grupos e Tradução**
```
Tocar no dropdown e verificar:

✅ GRUPO A: "Monitoramento Diário"
   - Verificação de Temperatura
   - Verificação de Peso
   - Monitoramento de Apetite
   - Verificação de Hidratação
   - Nível de Energia
   - Observação de Comportamento

✅ GRUPO B: "Sintomas Agudos"
   - Febre
   - Vômito
   - Diarreia
   - Letargia
   - Perda de Apetite
   - Sede Excessiva
   - Dificuldade Respiratória
   - Tosse
   - Espirros
   - Secreção Nasal

✅ GRUPO C: "Infeccioso/Parasitário"
   - Suspeita de Infecção
   - Infecção em Ferida
   - Infecção de Ouvido
   - Infecção Ocular
   - Infecção Urinária
   - Parasita Detectado
   - Carrapato Encontrado
   - Infestação de Pulgas

✅ GRUPO D: "Dermatológico"
   - Erupção Cutânea
   - Coceira
   - Queda de Pelo
   - Hot Spot
   - Ferida
   - Abscesso
   - Reação Alérgica
   - Inchaço

✅ GRUPO E: "Mobilidade/Ortopédico"
   - Manqueira
   - Dor Articular
   - Dificuldade para Andar
   - Rigidez
   - Fraqueza Muscular
   - Queda
   - Suspeita de Fratura

✅ GRUPO F: "Neurológico/Sensorial"
   - Convulsão
   - Tremores
   - Desorientação
   - Perda de Equilíbrio
   - Problemas de Visão
   - Problemas de Audição
   - Inclinação da Cabeça

✅ GRUPO G: "Tratamento/Procedimento"
   - Medicamento Administrado
   - Vacina Aplicada
   - Limpeza de Ferida
   - Troca de Curativo
   - Consulta Veterinária
   - Cirurgia
   - Atendimento de Emergência
   - Internação

❌ VERIFICAR QUE NÃO APARECE:
   - seizure
   - vomiting
   - wound_infection
   - Nenhum ID técnico!
```

#### **2.4 Testar Evento Normal**
```
1. Selecionar "Verificação de Temperatura"
2. Verificar que campos aparecem:
   - Gravidade (Leve/Moderado/Grave)
   - Toggle "Marcar como emergência" (DESLIGADO)
3. Selecionar gravidade: "Leve"
4. Adicionar nota: "Temperatura normal: 38.5°C"
5. Salvar
6. ✅ Evento salvo com sucesso
```

#### **2.5 Testar Evento de Emergência**
```
1. Tocar em "Saúde" novamente
2. Selecionar "Convulsão"
3. Verificar que:
   - ✅ Toggle "Emergência" AUTO-ATIVADO
   - ✅ Gravidade forçada para "Grave"
   - ✅ Alerta VERMELHO aparece:
        "🚨 Se o pet estiver em risco, procure
        atendimento veterinário imediatamente."
   - ✅ Toggle DESABILITADO (não pode desmarcar)
4. Adicionar nota: "Convulsão durou 2 minutos"
5. Salvar
6. ✅ Evento salvo como emergência
```

#### **2.6 Verificar Histórico**
```
1. Ir para histórico de eventos
2. Verificar que aparecem:
   - ✅ "Verificação de Temperatura" (não "temperature_check")
   - ✅ "Convulsão" (não "seizure")
3. ✅ ZERO IDs técnicos visíveis
```

---

## 🎯 **CHECKLIST DE VALIDAÇÃO**

### **Alimentação:**
- [ ] Dropdown categorizado funciona
- [ ] 6 grupos organizados
- [ ] 44 eventos traduzidos
- [ ] ZERO IDs técnicos na UI
- [ ] Eventos clínicos auto-detectados
- [ ] Histórico exibe nomes traduzidos

### **Saúde:**
- [ ] Dropdown categorizado funciona
- [ ] 7 grupos organizados
- [ ] 52 eventos traduzidos
- [ ] ZERO IDs técnicos na UI
- [ ] 21 emergências auto-detectadas
- [ ] Alerta vermelho para emergências
- [ ] Toggle desabilitado para emergências
- [ ] Histórico exibe nomes traduzidos

---

## ⚠️ **PROBLEMAS CONHECIDOS**

### **Se aparecer ID técnico:**
```
❌ PROBLEMA: Vê "mealSkipped" em vez de "Refeição pulada"
✅ CAUSA: Erro na função getEventTypeLabel()
✅ SOLUÇÃO: Reportar imediatamente
```

### **Se dropdown não abrir:**
```
❌ PROBLEMA: Dropdown não responde ao toque
✅ CAUSA: Possível erro de compilação
✅ SOLUÇÃO: Verificar console para erros
```

### **Se alerta não aparecer:**
```
❌ PROBLEMA: Alerta de emergência não aparece
✅ CAUSA: Evento não está na lista de emergências
✅ SOLUÇÃO: Verificar lista emergencyEvents
```

---

## 📊 **RESULTADOS ESPERADOS**

### **✅ SUCESSO:**
- Todos os eventos exibem nomes traduzidos
- Dropdowns organizados por categoria
- Headers de categoria em rosa
- Itens indentados
- Emergências auto-detectadas
- Alertas visuais funcionando
- Histórico traduzido

### **❌ FALHA:**
- Qualquer ID técnico visível na UI
- Dropdown não organizado
- Headers não aparecem
- Emergências não detectadas
- Alertas não aparecem
- Histórico com IDs técnicos

---

## 🎓 **NOTAS IMPORTANTES**

### **Alimentação:**
- Total: 44 eventos
- Grupos: 6
- Clínicos: 22 eventos
- UI: Dropdown categorizado

### **Saúde:**
- Total: 52 eventos
- Grupos: 7
- Emergências: 21 eventos
- UI: Dropdown categorizado

### **Padrão Comum:**
- ✅ Dropdown em vez de chips
- ✅ Switch/case para tradução
- ✅ Type-safe
- ✅ Headers de categoria
- ✅ Indentação visual
- ✅ ZERO IDs técnicos

---

## 🚀 **APÓS OS TESTES**

### **Se tudo funcionar:**
✅ Marcar como aprovado  
✅ Documentar resultados  
✅ Aplicar padrão em outros eventos  

### **Se houver problemas:**
❌ Documentar erros encontrados  
❌ Capturar screenshots  
❌ Reportar para correção  

---

**Data:** 2026-01-07  
**Versão:** 1.0.0  
**Status:** Pronto para Teste  
**Dispositivo:** SM A256E  

---

**BOA SORTE NOS TESTES!** 🎯
