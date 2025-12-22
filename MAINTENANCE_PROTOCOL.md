# Protocolo de Manutenção ScanNut

## 1. Princípio da Não-Regressão
**Regra Absoluta:** Nunca alterar uma funcionalidade, ícone ou fluxo de navegação que já foi confirmado como funcional.
*   **Áreas Críticas:** Radar Geo, GPS, Scans de Saúde, PetCard, Home Screen.
*   **Ação:** Se uma alteração tocar nestas áreas, deve ser feita com extremo cuidado e validação prévia.

## 2. Modificações Incrementais
**Regra:** Ao adicionar novas funcionalidades (abas, campos), **NÃO** reescrever o arquivo inteiro.
*   **Técnica:** Adicionar apenas o novo código (funções, widgets).
*   **Extensibilidade:** Utilizar `extensions` do Dart para adicionar métodos a classes existentes sem modificar o arquivo original sempre que possível.

## 3. Preservação de Widget Tree
**Regra:** Não alterar a estrutura de widgets já definidos visualmente.
*   **Ação:** Para adicionar ícones ou botões (ex: em `PetCard` ou `Home`), usar `list.add()` ou `append`, nunca substituir a lista inteira ou reorganizar a árvore sem permissão explícita.

## 4. Imutabilidade de Modelos
**Regra:** Alterações em `PetModel`, `PartnerModel`, etc., devem ser **retro-compatíveis**.
*   **Técnica:** Novos campos devem ser sempre `nullable` (opcionais) ou ter valores padrão (`default values`) para que telas antigas (`Resultado de Scan`, `Edição`) continuem compilando e funcionando sem refatoração massiva.

## 5. Confirmação de Escopo
**Regra:** Alterações que afetem múltiplos arquivos exigem confirmação prévia.
*   **Processo:** 
    1. Descrever o plano (quais arquivos, porquê).
    2. Aguardar "De acordo" ou "Pode seguir" do usuário.
