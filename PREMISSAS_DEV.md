# Premissas para o Desenvolvimento do App

Estas são as diretrizes fundamentais para o desenvolvimento e manutenção do projeto ScanNut, visando qualidade, estabilidade e conformidade, conforme definido pelo time de produto.

1. **Estrutura de Menu Padrão**:
   Todas as versões devem conter acessibilidade fácil e consistente a:
   - **Configurações**:
     - Suporte mandatório a múltiplos idiomas:
       - Inglês (Padrão)
       - Português-BR
       - Português-PT
       - Espanhol
   - **Ajuda**: Documentação clara e suporte.
   - **Sobre**:
     - Desenvolvedor: Multiverso Digital
     - Contato: contato@multiversodigital.com.br
     - Informações de Controle de Versão (Build/Version)
   - **Sair**: Logout seguro.

2. **Robustez e Estabilidade (Crash-Free)**:
   - Rotinas críticas devem ser blindadas contra erros (`try/catch`).
   - Prevenção ativa de crashes em runtime.
   - Aplicação deve ser resiliente a falhas de rede ou dados corrompidos.

3. **Internacionalização (i18n)**:
   - Proibido uso de strings "hardcoded" no código.
   - Todas as strings devem usar chaves (`keys`) de localização gerenciáveis.

4. **Usabilidade e Responsividade (UI/UX)**:
   - **Telas com Rolagem**: Todas as telas devem suportar rolagem (`SingleChildScrollView`, `ListView`) para evitar erros de "overflow" (tela amarela/preta) em dispositivos menores.

5. **Padrão de Relatórios (PDF)**:
   - Geração de PDFs padronizados.
   - Modo **Eco-Friendly** (Economia de Tinta - sem fundos coloridos) deve ser o padrão.
   - Mapeamento completo dos dados (Identidade, Saúde, Feridas, Nutrição, Galeria, Rede de Apoio).

6. **Conformidade (Compliance)**:
   - Adesão estrita às políticas da **Google Play Store**.
   - Transparência no uso de dados e permissões sensíveis.
