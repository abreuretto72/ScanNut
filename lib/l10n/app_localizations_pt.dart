// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'ScanNut';

  @override
  String get splashPoweredBy => 'Tecnologia AI Vision';

  @override
  String get tabFood => 'Comida';

  @override
  String get tabPlants => 'Plantas';

  @override
  String get tabPets => 'Pets';

  @override
  String get disclaimerTitle => 'Aviso Importante';

  @override
  String get disclaimerBody =>
      'Este aplicativo realiza apenas triagem informativa e NÃO substitui o conselho profissional de Nutricionistas, Agronômos ou Veterinários.';

  @override
  String get disclaimerButton => 'Entendi';

  @override
  String get emergencyCall => 'Ligar para Veterinário Próximo';

  @override
  String get cameraPermission =>
      'Precisamos da câmera para analisar. Você pode ativar nas configurações.';

  @override
  String get petNamePromptTitle => 'Nome do Pet';

  @override
  String get petNamePromptHint => 'Digite o nome do seu pet';

  @override
  String get petNamePromptCancel => 'Cancelar';

  @override
  String get petNameEmptyError =>
      'Nome do pet não fornecido. Pet mode cancelado.';

  @override
  String get petUnknown => 'Pet Desconhecido';

  @override
  String get homeHintFood => 'Aponte a câmera para a comida/refeição';

  @override
  String get homeHintPlant => 'Aponte a câmera para a planta ou doença';

  @override
  String get homeHintPetBreed => 'Aponte a câmera para o pet';

  @override
  String get homeHintPetHealth => 'Aponte a câmera para a ferida do pet';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsLanguage => 'Idioma / Language';

  @override
  String get settingsProfile => 'Perfil';

  @override
  String get settingsNutrition => 'Metas Nutricionais Humanas';

  @override
  String get settingsDangerZone => 'Zona de Perigo';

  @override
  String get pdfReportTitle => 'Prontuário';

  @override
  String get pdfAnaliseFezes => 'Análise Coprológica (Fezes)';

  @override
  String get pdfGeneratedOn => 'Gerado em';

  @override
  String get pdfIdentitySection => 'Identidade e Perfil Biológico';

  @override
  String get pdfHealthSection => 'Saúde e Histórico Médico';

  @override
  String get pdfClinicalSigns => 'Avaliação de Sinais Clínicos e Triagem';

  @override
  String get pdfEyes => 'Olhos';

  @override
  String get pdfTeeth => 'Dentes';

  @override
  String get pdfSkin => 'Pele/Pelagem';

  @override
  String get pdfNutritionSection => 'Nutrição e Plano Alimentar';

  @override
  String get pdfGallerySection => 'Galeria e Documentos';

  @override
  String get pdfParcSection => 'Hub de Apoio';

  @override
  String get pdfDisclaimerTitle => 'AVISO LEGAL IMPORTANTE';

  @override
  String get pdfDisclaimerBody =>
      'Este relatório é uma ferramenta de apoio. NÃO substitui consultas veterinárias.';

  @override
  String get termScreen => 'Tela';

  @override
  String get termMobile => 'Celular';

  @override
  String get termFood => 'Ração';

  @override
  String get breedMixed => 'Sem Raça Definida (Vira-lata)';

  @override
  String get porteSmall => 'Pequeno';

  @override
  String get porteMedium => 'Médio';

  @override
  String get porteLarge => 'Grande';

  @override
  String get porteGiant => 'Gigante';

  @override
  String get weightStatusUnderweight => 'Abaixo do ideal';

  @override
  String get weightStatusOverweight => 'Acima do ideal';

  @override
  String get weightStatusNormal => 'Peso Normal';

  @override
  String get weightRecUnderweight =>
      'Considere consultar o veterinário para avaliar a nutrição e saúde geral do pet.';

  @override
  String get weightRecOverweight =>
      'Agende uma consulta com o veterinário na aba \'Parc.\' para ajustar a dieta e exercícios.';

  @override
  String get weightRecNormal =>
      'Continue com os cuidados atuais! Mantenha a rotina de alimentação e exercícios.';

  @override
  String get termSeverity => 'Gravidade';

  @override
  String get termDiagnosis => 'Diagnóstico';

  @override
  String get termRecommendations => 'Recomendações';

  @override
  String get tabIdentity => 'IDENTIDADE';

  @override
  String get tabNutrition => 'NUTRIÇÃO';

  @override
  String get tabGrooming => 'GROOMING';

  @override
  String get tabHealth => 'SAÚDE';

  @override
  String get tabLifestyle => 'LIFESTYLE';

  @override
  String get emptyPastWeek => 'Nenhum histórico recente.';

  @override
  String get emptyCurrentWeek => 'Nenhum cardápio para esta semana.';

  @override
  String get emptyNextWeek => 'Nenhum planejamento futuro.';

  @override
  String get tabPastWeek => 'Semana Passada';

  @override
  String get tabCurrentWeek => 'Semana Atual';

  @override
  String get tabNextWeek => 'Próxima Semana';

  @override
  String get menuPlanTitle => 'Planejar Cardápio Inteligente';

  @override
  String get menuPeriod => 'Período do Cardápio';

  @override
  String get dietType => 'Regime Alimentar';

  @override
  String get dietNatural => 'Alimentação Natural';

  @override
  String get dietKibble => 'Ração Comercial';

  @override
  String get dietHybrid => 'Modo Híbrido Ativado';

  @override
  String get nutritionalGoal => 'Meta Nutricional';

  @override
  String get generateMenu => 'Gerar Cardápio';

  @override
  String get selectDates => 'Selecionar Datas';

  @override
  String get cancel => 'Cancelar';

  @override
  String get commonBack => 'Voltar';

  @override
  String get permissionCameraDisclosureTitle => 'Uso da Câmera';

  @override
  String get permissionCameraDisclosureBody =>
      'O ScanNut precisa acessar sua câmera para analisar a saúde da pele, pelo e olhos do seu pet, além de permitir o registro de documentos veterinários.';

  @override
  String get permissionMicrophoneDisclosureTitle => 'Uso do Microfone';

  @override
  String get permissionMicrophoneDisclosureBody =>
      'O ScanNut solicita acesso ao microfone para permitir que você faça anotações por voz sobre as observações do seu pet.';

  @override
  String get continueButton => 'Continuar';

  @override
  String get deleteAccount => 'Excluir Conta e Dados';

  @override
  String get deleteAccountConfirmTitle => 'Excluir tudo?';

  @override
  String get deleteAccountConfirmBody =>
      'Isso apagará permanentemente todos os seus cardápios e históricos.';

  @override
  String get deleteAccountButton => 'Excluir Tudo';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get aiDisclaimer =>
      'Esta análise é informativa e baseada em processamento automático. Consulte sempre o veterinário vinculado na aba Parc. para um diagnóstico preciso.';

  @override
  String get onboardingTitle1 => 'Transforme a sua Nutrição';

  @override
  String get onboardingBody1 =>
      'Utilize a nossa IA para analisar alimentos em segundos. Descubra calorias, macronutrientes e receba dicas de biohacking e receitas rápidas de 15 minutos para a sua alta performance.';

  @override
  String get onboardingTitle2 => 'Domine o seu Ecossistema';

  @override
  String get onboardingBody2 =>
      'Identifique plantas, diagnostique doenças e aprenda sobre propagação. Saiba instantaneamente se uma planta é segura para humanos através do nosso Semáforo de Sobrevivência.';

  @override
  String get onboardingTitle3 => 'O Prontuário Clínico Definitivo';

  @override
  String get onboardingBody3 =>
      'Acompanhe a saúde do seu pet com análise de pele por IA, histórico de vacinas e exames laboratoriais explicados. Tudo organizado e pronto para exportar em PDF para o seu veterinário.';

  @override
  String get onboardingTitle4 => 'Os seus dados são seus';

  @override
  String get onboardingBody4 =>
      'No ScanNut, a sua privacidade é prioridade. Todos os seus registos são guardados localmente no seu telemóvel (Hive) e não em nuvens externas.';

  @override
  String get onboardingAcceptTerms =>
      'Li e aceito os Termos de Uso e Política de Privacidade da Multiverso Digital';

  @override
  String get onboardingGetStarted => 'Começar';

  @override
  String get analysisErrorAiFailure =>
      'Todas as IAs falharam em analisar a imagem.';

  @override
  String get analysisErrorJsonFormat => 'Erro ao processar dados da IA.';

  @override
  String get analysisErrorUnexpected => 'Erro inesperado. Tente novamente.';

  @override
  String get analysisErrorInvalidCategory =>
      'A foto difere da categoria. A IA pode errar!';

  @override
  String get analysisErrorNotDetected =>
      'Nenhuma alteração ou problema detectado na imagem.';

  @override
  String get errorNoInternet =>
      'Sem conexão com a internet. Verifique sua rede.';

  @override
  String get errorTimeout => 'A operação demorou muito. Tente novamente.';

  @override
  String get errorAuthentication =>
      'Erro de autenticação. Verifique suas credenciais.';

  @override
  String get errorNotFound => 'Recurso não encontrado. Tente novamente.';

  @override
  String get errorServer =>
      'Erro no servidor. Tente novamente em alguns instantes.';

  @override
  String get errorImageTooLarge =>
      'Imagem muito grande. Tente com uma foto menor.';

  @override
  String get errorInvalidImage => 'Imagem inválida. Tire uma nova foto.';

  @override
  String get errorConfiguration =>
      'Erro de configuração. Entre em contato com o suporte.';

  @override
  String get errorPermissionDenied =>
      'Permissão negada. Verifique as configurações.';

  @override
  String get errorNoStorage => 'Espaço insuficiente no dispositivo.';

  @override
  String get errorCamera => 'Erro ao acessar a câmera.';

  @override
  String get errorLocation => 'Erro ao acessar localização.';

  @override
  String get errorDatabase => 'Erro ao salvar dados localmente.';

  @override
  String get errorJsonParse => 'Erro ao processar resposta da IA.';

  @override
  String get errorIncompleteData => 'Dados incompletos recebidos.';

  @override
  String get errorGeneric =>
      'Ops! Algo deu errado. Seus dados estão seguros. Tente novamente.';

  @override
  String get loadingFood => 'Analisando alimento...';

  @override
  String get loadingPlant => 'Analisando a planta...';

  @override
  String get loadingPetBreed => 'Analisando imagem do PET...';

  @override
  String get loadingPetHealth => 'Analisando saúde do PET...';

  @override
  String get nutrientsAdvancedMacros => 'Macronutrientes Avançados';

  @override
  String get nutrientsProteins => 'Proteínas';

  @override
  String get nutrientsCarbs => 'Carboidratos';

  @override
  String get nutrientsFats => 'Gorduras';

  @override
  String get nutrientsMinerals => 'Minerais e Vitaminas';

  @override
  String get nutrientsSynergy => 'Sinergia';

  @override
  String get recipesQuick => 'Receitas Rápidas (até 15 min)';

  @override
  String get recipesCulinaryIntel => 'Inteligência Culinária';

  @override
  String get recipesExpertTip => 'Dica do Especialista';

  @override
  String get labelGlycemicImpact => 'Impacto Glicêmico';

  @override
  String get labelFattyAcids => 'Ácidos Graxos';

  @override
  String get labelAminoProfile => 'Perfil de Aminoácidos';

  @override
  String get foodSafetyBio => 'Segurança & Bioquímica';

  @override
  String get foodIdealMoment => 'Momento Ideal';

  @override
  String get foodCriticalAlerts => 'Alertas Críticos';

  @override
  String get foodBioChem => 'Bioquímica e Neutralização';

  @override
  String get foodPreservation => 'Preservação';

  @override
  String get foodSmartSwap => 'Smart Swap (Troca)';

  @override
  String get foodDisclaimer =>
      'Nota: As informações nutricionais são estimadas. Consulte sempre um profissional de saúde.';

  @override
  String get foodVerdict => 'Veredito da IA';

  @override
  String get foodPros => 'Pontos Positivos';

  @override
  String get foodCons => 'Pontos de Atenção';

  @override
  String get foodBiohacking => 'Performance Biohacking';

  @override
  String get foodSatietyIndex => 'Índice de Saciedade';

  @override
  String get foodBodyBenefits => 'Benefícios para o Corpo';

  @override
  String get foodAttention => 'Atenção';

  @override
  String get foodFocusEnergy => 'Foco e Energia';

  @override
  String get paywallTitle => 'Desbloqueie o Poder Total';

  @override
  String get paywallSubtitle =>
      'Obtenha acesso ilimitado a todas as ferramentas de IA e análises detalhadas.';

  @override
  String get paywallSubscribeButton => 'Assinar Agora';

  @override
  String get paywallSelectPlan => 'Selecione um plano';

  @override
  String get paywallRestore => 'Restaurar Compras';

  @override
  String get paywallTerms => 'Termos';

  @override
  String get paywallMonthly => 'Mensal';

  @override
  String get paywallYearly => 'Anual';

  @override
  String get paywallBestValue => 'MELHOR VALOR';

  @override
  String get paywallSuccess =>
      'Assinatura ativada com sucesso! Bem-vindo ao Pro! 🚀';

  @override
  String get paywallError => 'A compra não foi concluída. Tente novamente.';

  @override
  String get paywallRestoreSuccess => 'Compras restauradas com sucesso!';

  @override
  String get paywallRestoreFail =>
      'Nenhuma assinatura ativa encontrada para restaurar.';

  @override
  String get paywallLoadingOfferings =>
      'Não foi possível carregar as ofertas no momento.';

  @override
  String get drawerProTitle => 'ScanNut Pro';

  @override
  String get drawerProSubtitle => 'Desbloqueie tudo';

  @override
  String get settingsNameLabel => 'Nome';

  @override
  String get settingsNameHint => 'Como você gostaria de ser chamado?';

  @override
  String get settingsWeightUnit => 'Unidade de Peso';

  @override
  String get settingsKg => 'Kilogramas (kg)';

  @override
  String get settingsLbs => 'Libras (lbs)';

  @override
  String get settingsPreferences => 'Preferências';

  @override
  String get settingsShowTips => 'Mostrar Dicas';

  @override
  String get settingsShowTipsSubtitle =>
      'Exibir dicas nutricionais nas análises';

  @override
  String get settingsPartnerManagement => 'Gestão de Parceiros';

  @override
  String get settingsSearchRadius => 'Raio de Busca Padrão';

  @override
  String get settingsSearchRadiusSubtitle =>
      'Sugere parceiros próximos ao seu pet baseando-se neste limite.';

  @override
  String get settingsSystemMaintenance => 'Manutenção do Sistema';

  @override
  String get settingsBackupOptimize => 'Gerar Backup e Otimizar';

  @override
  String get settingsBackupOptimizeSubtitle =>
      'Gera PDF completo e libera espaço antigo.';

  @override
  String get settingsDeletePets => 'Excluir Histórico de Pets';

  @override
  String get settingsDeletePetsSubtitle =>
      'Apagar todos os pets salvos permanentemente.';

  @override
  String get settingsDeletePlants => 'Excluir Histórico de Plantas';

  @override
  String get settingsDeletePlantsSubtitle =>
      'Apagar todas as plantas salvas permanentemente.';

  @override
  String get settingsDeleteFood => 'Excluir Histórico de Alimentos';

  @override
  String get settingsDeleteFoodSubtitle =>
      'Apagar todos os alimentos salvos permanentemente.';

  @override
  String get settingsClearPartners => 'Limpar Rede de Apoio';

  @override
  String get settingsClearPartnersSubtitle =>
      'Remover todos os parceiros cadastrados permanentemente.';

  @override
  String get partnersTitle => 'Futuros Parceiros';

  @override
  String get partnersSubtitle => 'Parceiros cadastrados no ecossistema';

  @override
  String get partnersFilterAll => 'Todos';

  @override
  String get partnersFilterVet => 'Veterinário';

  @override
  String get partnersFilterPetShop => 'Pet Shop';

  @override
  String get partnersFilterPharmacy => 'Farmácia';

  @override
  String get partnersFilterHotel => 'Hotel';

  @override
  String get partnersFilterGrooming => 'Banho e Tosa';

  @override
  String get partnersFilterLab => 'Laboratório';

  @override
  String get partnersFilterDogWalker => 'Dog Walker';

  @override
  String get catHeaderHealth => '🏥 SAÚDE & BEM-ESTAR';

  @override
  String get catVet => 'Veterinário Geral';

  @override
  String get catVetEmergency => 'Veterinário de Emergência (24h)';

  @override
  String get catVetSpecialist => 'Especialista (Cardio/Dermato/Orto)';

  @override
  String get catPhysio => 'Fisioterapia/Reabilitação';

  @override
  String get catHomeo => 'Homeopatia/Acupuntura';

  @override
  String get catNutri => 'Nutricionista Veterinário';

  @override
  String get catAnest => 'Anestesista';

  @override
  String get catOnco => 'Oncologista';

  @override
  String get catDentist => 'Dentista Veterinário';

  @override
  String get catHeaderDaily => '🛏️ CUIDADOS DIÁRIOS & HOTEL';

  @override
  String get catSitter => 'Pet Sitter (Em domicílio)';

  @override
  String get catWalker => 'Dog Walker (Passeador)';

  @override
  String get catNanny => 'Babá de Pets';

  @override
  String get catHotel => 'Hotel/Hospedagem';

  @override
  String get catDaycare => 'Creche (Day Care)';

  @override
  String get catHeaderGrooming => '🧼 ESTÉTICA & HIGIENE';

  @override
  String get catBath => 'Banho e Tosa';

  @override
  String get catStylist => 'Pet Stylist';

  @override
  String get catGroomerBreed => 'Groomer Especialista';

  @override
  String get catHeaderTraining => '🦮 COMPORTAMENTO & TREINO';

  @override
  String get catTrainer => 'Adestrador';

  @override
  String get catBehaviorist => 'Comportamentalista';

  @override
  String get catCatSultant => 'Consultor Felino';

  @override
  String get catHeaderRetail => '🛒 LOJAS & SERVIÇOS';

  @override
  String get catPetShop => 'Pet Shop';

  @override
  String get catSupplies => 'Ração e Acessórios';

  @override
  String get catTransport => 'Táxi Pet / Transporte';

  @override
  String get catPharm => 'Farmácia Veterinária';

  @override
  String get catHeaderOther => '🧬 OUTROS';

  @override
  String get catNgo => 'ONG / Abrigo';

  @override
  String get catBreeder => 'Criador / Canil';

  @override
  String get catLab => 'Laboratório de Análises';

  @override
  String get catInsurance => 'Plano de Saúde Pet';

  @override
  String get catFuneralPlan => 'Plano de Assist. Funeral';

  @override
  String get catCemeterie => 'Cemitério Pet';

  @override
  String get catCremation => 'Crematório';

  @override
  String get catFuneral => 'Serviços Funerários & Velório';

  @override
  String get deletePetTitle => 'Excluir Pet';

  @override
  String get deletePetConfirmation =>
      'Tem certeza que deseja excluir este pet permanentemente? Esta ação não pode ser desfeita.';

  @override
  String get deletePlantTitle => 'Excluir Planta';

  @override
  String get deletePlantConfirm =>
      'Tem certeza que deseja excluir esta planta? Esta ação não pode ser desfeita.';

  @override
  String get delete => 'Excluir';

  @override
  String get petActivityLow => 'Baixo';

  @override
  String get petActivityHigh => 'Alto';

  @override
  String get petActivityAthlete => 'Atleta';

  @override
  String get petBathWeekly => 'Semanal';

  @override
  String get petBathMonthly => 'Mensal';

  @override
  String get petNotOffice => 'Não informado';

  @override
  String get whatsappInitialMessage =>
      'Olá! Vi seu perfil no ScanNut e gostaria de mais informações.';

  @override
  String get settingsResetDefaults => 'Restaurar Padrões';

  @override
  String get settingsResetDialogTitle => 'Restaurar Padrões';

  @override
  String get settingsResetDialogContent =>
      'Tem certeza que deseja restaurar todas as configurações para os valores padrão?';

  @override
  String get settingsResetSuccess => 'Configurações restauradas';

  @override
  String get settingsAutoSaveInfo =>
      'Suas configurações são salvas automaticamente';

  @override
  String get settingsConfirmDeleteTitle => 'Confirmar Exclusão';

  @override
  String settingsConfirmDeleteContent(Object itemType) {
    return 'Tem certeza que deseja apagar permanentemente todo o histórico de $itemType? Essa ação não pode ser desfeita.';
  }

  @override
  String settingsDeleteSuccess(Object itemType) {
    return 'Histórico de $itemType apagado com sucesso.';
  }

  @override
  String get modePetIdentification => 'Raça & ID';

  @override
  String get modePetHealth => 'Saúde';

  @override
  String get instructionPetBody =>
      'Aponte a câmera para o corpo inteiro do seu pet';

  @override
  String get instructionPetWound => 'Aponte a câmera para a ferida do seu pet';

  @override
  String get tooltipNutritionHistory => 'Histórico Alimentar';

  @override
  String get tooltipNutritionManagement => 'Gestão da Nutrição';

  @override
  String get tooltipBotanyHistory => 'Histórico Botânico';

  @override
  String get exitDialogTitle => 'Sair do App';

  @override
  String get exitDialogContent => 'Deseja realmente sair do ScanNut?';

  @override
  String get exit => 'Sair';

  @override
  String get redirectShop => 'Redirecionando para loja parceira...';

  @override
  String get cameraError => 'Erro ao iniciar câmera: ';

  @override
  String petSavedSuccess(Object petName) {
    return 'Dossiê do $petName salvo/atualizado com sucesso!';
  }

  @override
  String savedSuccess(Object type) {
    return '$type salvo nas boxes especializadas!';
  }

  @override
  String get errorPetNameNotFound => 'Erro: Nome do pet não encontrado.';

  @override
  String healthAnalysisSaved(String petName) {
    return 'Análise de saúde de $petName salva com sucesso!';
  }

  @override
  String errorSavingAnalysis(String error) {
    return 'Erro ao salvar análise: $error';
  }

  @override
  String get menuHello => 'Olá!';

  @override
  String menuHelloUser(Object userName) {
    return 'Olá, $userName!';
  }

  @override
  String get menuAiAssistant => 'Assistente IA ScanNut';

  @override
  String get menuSettings => 'Configuração';

  @override
  String menuSettingsSubtitle(Object calories) {
    return 'Meta diária: $calories kcal';
  }

  @override
  String get menuNutritionalPillars => 'Pilares da Nutrição';

  @override
  String get menuNutritionalPillarsSubtitle => 'Conceitos do ScanNut';

  @override
  String get menuEnergyBalance => 'Balanço Energético';

  @override
  String get menuEnergyBalanceSubtitle => 'Dashboard Fitness & Biohacking';

  @override
  String get menuNutritionHistory => 'Histórico de Nutrição';

  @override
  String get menuNutritionHistorySubtitle => 'Análises de Alimentos';

  @override
  String get menuBotanyHistory => 'Histórico Botânico';

  @override
  String get menuBotanyHistorySubtitle => 'Saúde e Guia de Cultivo';

  @override
  String get menuPetHistory => 'Histórico de Pets';

  @override
  String get menuPetHistorySubtitle => 'Dossiês e Exames';

  @override
  String get menuHelp => 'Ajuda';

  @override
  String get menuHelpSubtitle => 'Como usar o app';

  @override
  String get menuAbout => 'Sobre';

  @override
  String get menuPrivacySubtitle => 'Consultar termos e dados';

  @override
  String get menuDeleteAccountSubtitle => 'Remover todos os registros';

  @override
  String get menuExit => 'Sair';

  @override
  String get menuExitSubtitle => 'Fechar o aplicativo';

  @override
  String get logoutTitle => 'Sair e Desconectar';

  @override
  String get logoutSubtitle => 'Encerrar sessão no ScanNut';

  @override
  String get contactSubject => 'Contato ScanNut';

  @override
  String get helpWelcomeTitle => 'Bem-vindo ao ScanNut!';

  @override
  String get helpWelcomeSubtitle =>
      'Seu assistente visual de IA para alimentos, plantas e pets';

  @override
  String get helpDisclaimerTitle => '⚠️ AVISO IMPORTANTE';

  @override
  String get helpDisclaimerBody =>
      'A Inteligência Artificial pode cometer erros na análise de imagens. O ScanNut NÃO se responsabiliza pelas informações geradas pela IA.\n\n• Análises são apenas ORIENTATIVAS\n• NÃO substituem profissionais qualificados\n• Sempre consulte veterinários, nutricionistas ou botânicos\n• Use o app como ferramenta de apoio, não como diagnóstico final';

  @override
  String get helpFooter =>
      'Desenvolvido com ❤️ por Abreu Retto\n© 2026 ScanNut';

  @override
  String get footerDevelopedBy => 'Desenvolvido por Abreu Retto';

  @override
  String get footerMadeWith => 'Feito com ❤️ usando Gemini AI';

  @override
  String get aboutTitle => 'Sobre o ScanNut';

  @override
  String get aboutSubtitle => 'ScanNut IA Visual Assistant';

  @override
  String get aboutPoweredBy => 'Powered by Google Gemini 2.5 Flash';

  @override
  String get aboutDescription =>
      'Análise inteligente de:\n• Alimentos 🍎\n• Plantas 🌿\n• Pets 🐾';

  @override
  String get nutritionGuideTitle => 'Guia de Nutrição Animal ScanNut';

  @override
  String get nutritionIntro =>
      'Diferente dos humanos, os cães e gatos possuem um metabolismo acelerado e exigências nutricionais únicas. O ScanNut utiliza IA para equilibrar estes 5 pilares vitais para a longevidade do seu pet.';

  @override
  String get ngProteinTitle => 'Proteína Animal';

  @override
  String get ngProteinSubtitle => 'A Força do Pet';

  @override
  String get ngProteinWhatIs =>
      'Pets são carnívoros (estritos como gatos ou facultativos como cães). Eles precisam de aminoácidos específicos encontrados na carne que o corpo deles não produz.';

  @override
  String get ngProteinAction =>
      'Priorizamos fontes como frango, carne bovina, peixes, ovos ou proteínas selecionadas em rações premium.';

  @override
  String get ngFatsTitle => 'Gorduras Específicas';

  @override
  String get ngFatsSubtitle => 'A Proteção';

  @override
  String get ngFatsWhatIs =>
      'Além da energia, a gordura correta previne dermatites e garante que o pet absorva as vitaminas A, D, E e K. O Ômega 3 é o maior aliado contra inflamações.';

  @override
  String get ngFatsAction =>
      'Sugerimos o equilíbrio de Ômegas 3 e 6, provenientes de óleos de peixe ou gorduras boas.';

  @override
  String get ngCarbsTitle => 'Fibras e Carboidratos Selecionados';

  @override
  String get ngCarbsSubtitle => 'O Intestino';

  @override
  String get ngCarbsWhatIs =>
      'O sistema digestivo do pet é mais curto. Usamos carboidratos de fácil digestão (como batata-doce ou arroz) e fibras que auxiliam na formação correta das fezes.';

  @override
  String get ngCarbsAction =>
      'Sugerimos vegetais como abóbora e cenoura, e grãos como arroz integral ou aveia.';

  @override
  String get ngVitaminsTitle => 'Minerais e Vitaminas';

  @override
  String get ngVitaminsSubtitle => 'Cuidado com a Dose';

  @override
  String get ngVitaminsWhatIs =>
      'Crucial: O excesso de cálcio pode prejudicar filhotes e a falta pode fragilizar idosos. O ScanNut foca no equilíbrio mineral exato para a estrutura óssea canina e felina.';

  @override
  String get ngVitaminsAction =>
      'O app sinaliza a necessidade de suplementação, especialmente em dietas Naturais, para evitar carências.';

  @override
  String get ngHydrationTitle => 'Hidratação Biológica';

  @override
  String get ngHydrationSubtitle => 'O Ponto Fraco';

  @override
  String get ngHydrationWhatIs =>
      'Muitos pets não sentem sede proporcional à necessidade. O app incentiva alimentos úmidos para evitar cálculos renais, uma das maiores causas de óbito em gatos e cães idosos.';

  @override
  String get ngHydrationAction =>
      'Sugerimos a inclusão de alimentos úmidos, caldos ou adição de água na ração para proteger os rins.';

  @override
  String get ngWarningTitle => 'ATENÇÃO:';

  @override
  String get ngWarningText =>
      'Nunca ofereça alimentos proibidos para pets (como chocolate, uvas, cebola e xilitol). As sugestões do ScanNut respeitam estas restrições de segurança.';

  @override
  String get ngSectionWhatIs => 'O que é:';

  @override
  String get ngSectionScanNut => 'No ScanNut:';

  @override
  String get fitnessDashboardTitle => 'Dashboard Fitness';

  @override
  String get fitnessBalanceKcal => 'Saldo kcal';

  @override
  String fitnessMetaDaily(Object goal) {
    return 'Meta diária: $goal kcal';
  }

  @override
  String get fitnessConsumed => 'Consumido';

  @override
  String get fitnessBurned => 'Queimado';

  @override
  String get fitnessPerformance => 'Performance Biohacking';

  @override
  String get fitnessTip =>
      'Dica do Dia: Treine em jejum hoje para otimizar a queima de gordura de acordo com o seu último consumo de carboidratos.';

  @override
  String get fitnessAddWorkout => 'Add Treino';

  @override
  String get fitnessRegWorkout => 'Registrar Treino';

  @override
  String get fitnessExerciseHint => 'Exercício (ex: Corrida)';

  @override
  String get fitnessCaloriesHint => 'Calorias Queimadas';

  @override
  String get fitnessDurationHint => 'Duração (min)';

  @override
  String get botanyTitle => 'Inteligência Botânica';

  @override
  String get botanyEmpty => 'Nenhuma planta analisada ainda.';

  @override
  String get botanyStatus => 'STATUS';

  @override
  String get botanyToxicHuman => 'Tóxico para Humanos';

  @override
  String get botanyDangerousPet => 'Perigoso para Pets';

  @override
  String get botanyRecovery => 'Recuperação';

  @override
  String get botanyRecoveryPlan => 'Plano de Recuperação';

  @override
  String get botanyFengShui => 'Feng Shui & Simbolismo';

  @override
  String botanyDossierTitle(String plantName) {
    return 'Dossiê Botânico: $plantName';
  }

  @override
  String get petHistoryTitle => 'Meus Pets Salvos';

  @override
  String get petHistoryEmpty => 'Nenhum pet salvo ainda.';

  @override
  String get petBreed => 'N/A';

  @override
  String get petLinkPartnerError =>
      'Vincule o pet a um Veterinário ou Pet Shop na aba \'Parceiros\' para usar a agenda.';

  @override
  String get petNoRecentMenu => 'O pet ainda não tem cardápio gerado';

  @override
  String get petEditSaved => 'Alterações salvas.';

  @override
  String get petVisualDescription => 'Descrição Visual';

  @override
  String get petPossibleCauses => 'Causas Prováveis';

  @override
  String get petSpecialistOrientation => 'Orientação do Especialista';

  @override
  String get foodHistoryTitle => 'Histórico de Alimentos';

  @override
  String get foodHistoryEmpty => 'Nenhuma análise salva ainda.';

  @override
  String get foodReload => 'Recarregar';

  @override
  String get foodKcalPer100g => 'kcal / 100g';

  @override
  String get foodProt => 'Prot.';

  @override
  String get foodCarb => 'Carb.';

  @override
  String get foodFat => 'Gord.';

  @override
  String get foodDeleteConfirmTitle => 'Excluir Análise?';

  @override
  String get foodDeleteConfirmContent => 'Esta ação não pode ser desfeita.';

  @override
  String get commonUnderstand => 'Entendi';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonYes => 'Sim';

  @override
  String get commonNo => 'Não';

  @override
  String get linkError => 'Não foi possível abrir o link.';

  @override
  String get helpTitle => 'Ajuda e Suporte';

  @override
  String get helpCommonQuestions => 'Perguntas Frequentes';

  @override
  String get helpContactUs => 'Entre em Contato';

  @override
  String get helpTutorials => 'Tutoriais em Vídeo';

  @override
  String get helpAppVersion => 'Versão do Aplicativo';

  @override
  String get helpUserGuide => 'Guia do Usuário';

  @override
  String get helpTermsPrivacy => 'Termos e Privacidade';

  @override
  String get guideVitalsTitle => 'SEÇÕES DO PERFIL DO PET';

  @override
  String get guideIdentity => 'Identidade';

  @override
  String get guideIdentityDesc =>
      'Gerencie os dados vitais do pet: peso, raça, idade e análise comportamental genética completa.';

  @override
  String get guideHealth => 'Saúde';

  @override
  String get guideHealthDesc =>
      'Histórico médico completo com controle de vacinas, vermífugos, exames laboratoriais e lembretes de consultas.';

  @override
  String get guideNutrition => 'Nutrição';

  @override
  String get guideNutritionDesc =>
      'Planejamento alimentar semanal detalhado com cálculos de Kcal, datas (DD/MM) e os 5 pilares nutricionais.';

  @override
  String get guideGallery => 'Galeria';

  @override
  String get guideGalleryDesc =>
      'Documente visualmente a evolução e momentos especiais do seu pet com fotos e vídeos.';

  @override
  String get guidePrac => 'Prac';

  @override
  String get guidePracDesc =>
      'Prontuário de Acompanhamento Comportamental para registrar rotinas, mudanças de hábito e rede de apoio.';

  @override
  String get guideObservationsTitle => 'OBSERVAÇÕES E HISTÓRICO';

  @override
  String get guideHistory => 'Histórico Cumulativo';

  @override
  String get guideHistoryDesc =>
      'Cada seção possui um campo de observações. Novas anotações NÃO apagam as antigas - tudo fica registrado!';

  @override
  String get guideTimestamps => 'Timestamps Automáticos';

  @override
  String get guideTimestampsDesc =>
      'O sistema insere automaticamente Data e Hora em cada entrada, criando um histórico cronológico completo.';

  @override
  String get guideOrder => 'Ordem Inteligente';

  @override
  String get guideOrderDesc =>
      'A entrada mais recente sempre aparece no topo, facilitando a leitura e acompanhamento.';

  @override
  String get guideVoice => 'Ditado por Voz';

  @override
  String get guideVoiceDesc =>
      'Use o ícone de microfone para ditar observações em vez de digitar. Mais rápido e prático!';

  @override
  String get guideExportTitle => 'EXPORTAÇÃO EM PDF';

  @override
  String get guidePdfTitle => 'Prontuário Veterinário Completo';

  @override
  String get guidePdfDesc =>
      'É gerado automaticamente com TODAS as informações (Perfil + Saúde + Nutrição + Observações). Ideal para levar ao veterinário!';

  @override
  String get guideBotanyTitle => 'ANÁLISE DE PLANTAS';

  @override
  String get guideBotanyLeaf => 'Ícone de Folha (Verde)';

  @override
  String get guideBotanyLeafDesc =>
      'Indica que a planta está SAUDÁVEL. Nenhuma intervenção urgente necessária.';

  @override
  String get guideBotanyAlert => 'Ícone de Alerta (Amarelo/Laranja)';

  @override
  String get guideBotanyAlertDesc =>
      'Planta requer ATENÇÃO. Pode estar com deficiências nutricionais ou estresse hídrico.';

  @override
  String get guideBotanyCritical => 'Ícone de Emergência (Vermelho)';

  @override
  String get guideBotanyCriticalDesc =>
      'Estado CRÍTICO. A planta necessita de tratamento imediato para sobreviver.';

  @override
  String get guideBotanyTraffic => 'Semáforo de Sobrevivência';

  @override
  String get guideBotanyTrafficDesc =>
      'Verde = Ideal | Amarelo = Atenção | Vermelho = Urgente. Aparece nos cards de histórico.';

  @override
  String get guideFinalTip =>
      'O ScanNut é uma ferramenta de longo prazo para acompanhar toda a vida do seu pet!';

  @override
  String get tabSummary => 'RESUMO';

  @override
  String get tabNutrients => 'NUTRIENTES';

  @override
  String get tabGastronomy => 'GASTRONOMIA';

  @override
  String get labelTrafficLight => 'Semáforo (Luz, Água, Solo)';

  @override
  String get tabHardware => 'Hardware';

  @override
  String get tabBios => 'Bios';

  @override
  String get tabPropagation => 'Propagação';

  @override
  String get cardTapForRecipes => 'Toque para ver receitas ✨';

  @override
  String get cardScore => 'Score';

  @override
  String get cardTabOverview => 'Visão Geral';

  @override
  String get cardTabDetails => 'Detalhes';

  @override
  String get cardTabTips => 'Dicas';

  @override
  String get cardTotalCalories => 'Calorias Totais';

  @override
  String get cardDailyGoal => 'da meta diária';

  @override
  String get cardMacroDist => 'Distribuição de Macronutrientes';

  @override
  String get cardQuickSummary => 'Resumo Rápido';

  @override
  String get cardBenefits => 'Benefícios';

  @override
  String get cardAlerts => 'Alertas';

  @override
  String get cardVitalityScore => 'Score de Vitalidade';

  @override
  String get cardDetailedInfo => 'Informações Detalhadas';

  @override
  String get cardDisclaimer =>
      'Nota: Esta é uma análise feita por IA e não substitui um diagnóstico de nutricionista.';

  @override
  String get pdfFoodTitle => 'Análise Nutricional & Biohacking';

  @override
  String get pdfDate => 'Data';

  @override
  String get pdfCalories => 'Calorias';

  @override
  String get pdfTrafficLight => 'Semáforo';

  @override
  String get pdfProcessing => 'Processamento';

  @override
  String get pdfExSummary => 'Resumo Executivo';

  @override
  String get pdfAiVerdict => 'Veredito da IA';

  @override
  String get pdfPros => 'Pontos Positivos';

  @override
  String get pdfCons => 'Pontos de Atenção';

  @override
  String get pdfDetailedNutrition => 'Nutrição Detalhada';

  @override
  String get pdfMacros => 'Macronutrientes';

  @override
  String get pdfNutrient => 'Nutriente';

  @override
  String get pdfQuantity => 'Quantidade';

  @override
  String get pdfDetails => 'Detalhes';

  @override
  String get pdfMicros => 'Micronutrientes e Vitaminas';

  @override
  String get pdfSynergy => 'Sinergia Nutricional';

  @override
  String get pdfBiohacking => 'Biohacking e Saúde';

  @override
  String get pdfPerformance => 'Performance';

  @override
  String get pdfSatiety => 'Índice de Saciedade';

  @override
  String get pdfFocus => 'Foco e Energia';

  @override
  String get pdfIdealMoment => 'Momento Ideal';

  @override
  String get pdfSecurity => 'Segurança';

  @override
  String get pdfAlerts => 'Alertas';

  @override
  String get pdfBiochem => 'Bioquímica';

  @override
  String get pdfGastronomy => 'Gastronomia e Dicas';

  @override
  String get pdfQuickRecipes => 'Receitas Rápidas';

  @override
  String pdfGeneratedBy(Object date, Object owner) {
    return 'Gerado em $date por $owner';
  }

  @override
  String pdfPage(Object current, Object total) {
    return 'Página $current de $total';
  }

  @override
  String get pdfEstablishment => 'Estabelecimento';

  @override
  String get pdfFieldCategory => 'Categoria';

  @override
  String get pdfPhone => 'Telefone';

  @override
  String get pdfRating => 'Avaliação';

  @override
  String get pdfStars => 'Estrelas';

  @override
  String get pdfStatus => 'Status';

  @override
  String get pdfTotalFound => 'Total Encontrado';

  @override
  String get pdfRegion => 'Região';

  @override
  String get pdfPartnersGuide => 'Guia de Parceiros';

  @override
  String get distanceLabel => 'Distância';

  @override
  String get ratingLabel => 'Avaliação';

  @override
  String get nutritionMgmtTitle => 'Gestão de Nutrição';

  @override
  String get dailyMealPlan => 'Plano Alimentar Diário';

  @override
  String get recommendedIntake => 'Ingestão Recomendada';

  @override
  String get weightMonitoring => 'Monitoramento de Peso';

  @override
  String get labelProteins => 'Proteínas';

  @override
  String get labelCarbs => 'Carboidratos';

  @override
  String weeklyPlanTitle(Object date) {
    return 'Semana de $date';
  }

  @override
  String weeklyPlanSubtitle(Object count) {
    return 'O que você vai comer nos próximos $count dias';
  }

  @override
  String get tipsTitle => 'Dicas de Preparo (Batch Cooking)';

  @override
  String get caloriesEstimated => 'kcal estimados para o dia';

  @override
  String get todayLabel => 'HOJE';

  @override
  String get mealBreakfast => 'Café';

  @override
  String get mealLunch => 'Almoço';

  @override
  String get mealSnack => 'Lanche';

  @override
  String get mealDinner => 'Jantar';

  @override
  String get regeneratePlanTitle => 'Refazer a semana?';

  @override
  String get regeneratePlanBody =>
      'Isso vai criar um novo cardápio para a semana. O atual será substituído.';

  @override
  String get regenerateAction => 'Refazer';

  @override
  String get regenerateSuccess => 'Cardápio da semana refeito!';

  @override
  String get planError => 'Erro ao carregar o cardápio';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get noPlanTitle => 'Você ainda não tem um cardápio';

  @override
  String get createPlanButton => 'Criar Cardápio';

  @override
  String get historyTitle => 'Histórico de Cardápios';

  @override
  String get noHistory => 'Nenhum histórico';

  @override
  String daysPlanned(Object count) {
    return '$count dias planejados';
  }

  @override
  String get deletePlanTitle => 'Excluir cardápio?';

  @override
  String get deletePlanBody => 'Esta ação não pode ser desfeita.';

  @override
  String get ingredientsTitle => 'INGREDIENTES';

  @override
  String get mealDefault => 'Refeição';

  @override
  String get creatingProfile => 'Perfil básico criado automaticamente.';

  @override
  String get planCreatedSuccess => 'Cardápio criado com sucesso!';

  @override
  String get openingConfig => 'Abrindo configuração...';

  @override
  String get pdfMenuPlanTitle => 'Plano Alimentar Semanal';

  @override
  String get menuCreationTitle => 'Criar Cardápio da Semana';

  @override
  String get menuCreationSubtitle => 'Configure como você quer seu cardápio';

  @override
  String get mealsPerDay => 'Refeições por dia';

  @override
  String get mealsUnit => 'refeições';

  @override
  String get menuStyleTitle => 'Estilo do cardápio';

  @override
  String get styleSimple => 'Simples';

  @override
  String get styleBudget => 'Econômico';

  @override
  String get styleQuick => 'Rápido';

  @override
  String get styleHealthy => 'Saudável';

  @override
  String get dietaryRestrictions => 'Restrições alimentares';

  @override
  String get allowRepetition => 'Pode repetir receitas na semana';

  @override
  String get allowRepetitionSubtitle =>
      'Se desligado, cada receita aparece apenas 1 vez';

  @override
  String get restVegetarian => 'Vegetariano';

  @override
  String get restVegan => 'Vegano';

  @override
  String get restLactoseFree => 'Sem Lactose';

  @override
  String get restGlutenFree => 'Sem Glúten';

  @override
  String get restDiabetes => 'Diabetes';

  @override
  String get restHypertension => 'Hipertensão';

  @override
  String get periodTypeTitle => 'Período do Cardápio';

  @override
  String get periodWeekly => 'Semanal (7 dias)';

  @override
  String get periodMonthly => 'Mensal (28 dias)';

  @override
  String get objectiveTitle => 'Objetivo';

  @override
  String get objMaintenance => 'Manter peso';

  @override
  String get objWeightLoss => 'Emagrecimento';

  @override
  String get objBalanced => 'Alimentação equilibrada';

  @override
  String get periodSectionTitle => 'Para quando?';

  @override
  String get periodSectionDesc =>
      'Escolha o período do cardápio que será gerado.';

  @override
  String get periodThisWeek => 'Esta semana';

  @override
  String get periodNextWeek => 'Próxima semana';

  @override
  String get period28Days => 'Próximos 28 dias';

  @override
  String get objectiveSectionTitle => 'Objetivo do cardápio';

  @override
  String get objectiveSectionDesc =>
      'O objetivo influencia a escolha dos alimentos e calorias.';

  @override
  String get preferencesSectionTitle => 'Preferências alimentares';

  @override
  String get preferencesSectionDesc =>
      'Opcional. Se não marcar nada, o cardápio será padrão.';

  @override
  String get confirmationSectionTitle => 'Resumo da escolha';

  @override
  String get confirmationSummaryLead => 'Você vai gerar:';

  @override
  String get confirmationPeriodPrefix => '• Cardápio: ';

  @override
  String get confirmationObjectivePrefix => '• Objetivo: ';

  @override
  String get generateMenuAction => 'GERAR CARDÁPIO';

  @override
  String get selectPeriodError => 'Escolha o período do cardápio.';

  @override
  String get generatingMenu => 'Gerando seu cardápio...';

  @override
  String get redoPlanAction => 'Refazer esta semana';

  @override
  String get generateNextWeekAction => 'Gerar próxima semana';

  @override
  String get generate28DaysAction => 'Gerar próximos 28 dias';

  @override
  String get createNewVersion => 'Criar nova versão';

  @override
  String get replaceExisting => 'Substituir atual';

  @override
  String get redoPlanPrompt => 'Como você deseja refazer este cardápio?';

  @override
  String get historyFilter => 'Filtrar Histórico';

  @override
  String get allPeriods => 'Todos os Períodos';

  @override
  String get activeStatus => 'Ativo';

  @override
  String get archivedStatus => 'Arquivado';

  @override
  String get editMeal => 'Editar Refeição';

  @override
  String get saveChanges => 'Salvar Alterações';

  @override
  String get deletePlanSuccess => 'Cardápio excluído com sucesso.';

  @override
  String get mealRemoved => 'Cardápio removido.';

  @override
  String get statusActive => 'Ativo';

  @override
  String get statusArchived => 'Arquivado';

  @override
  String get versionLabel => 'Versão';

  @override
  String get pdfPersonalizedPlanTitle => 'PLANO ALIMENTAR PERSONALIZADO';

  @override
  String get pdfGoalLabel => 'OBJETIVO';

  @override
  String get pdfGeneratedByLine =>
      'RELATÓRIO DE NUTRIÇÃO SEMANAL GERADO POR ScanNut AI';

  @override
  String get pdfBatchCookingTips => '💡 DICAS DE BATCH COOKING & PREPARO';

  @override
  String get tipBeans =>
      '💡 Cozinhe uma panela grande de feijão logo no início da semana e congele porções para economizar gás e tempo.';

  @override
  String get tipRice =>
      '💡 Mantenha uma base de arroz branco pronta na geladeira; ele é o acompanhamento coringa para quase todos os seus PFs.';

  @override
  String get tipChicken =>
      '💡 Cozinhe e desfie o frango de uma única vez. Use-o no sanduíche natural, no wrap e no mexidão de sexta.';

  @override
  String get tipEggs =>
      '💡 Ovos são sua proteína econômica e rápida. Mantenha-os sempre à mão para substituir carnes em dias corridos.';

  @override
  String get tipVeggies =>
      '💡 Lave e pique todos os vegetais da estação assim que chegar do mercado. Guarde-os em potes herméticos para durarem mais.';

  @override
  String get tipRoots =>
      '💡 Raízes como mandioca e batata doce podem ser cozidas em grande quantidade e guardadas na água na geladeira por 3 dias.';

  @override
  String get tipGroundMeat =>
      '💡 A carne moída é a base perfeita: use-a pura no almoço e no recheio da panqueca ou sanduíche no dia seguinte.';

  @override
  String get tipFruits =>
      '💡 Frutas muito maduras? Congele-as em pedaços para turbinar suas vitaminas e smoothies matinais.';

  @override
  String get tipDefault =>
      'Planeje suas compras com foco em itens da estação para economizar e ganhar saúde.';

  @override
  String get foodRice => 'Arroz';

  @override
  String get foodBeans => 'Feijão';

  @override
  String get foodChicken => 'Frango';

  @override
  String get foodMeat => 'Carne';

  @override
  String get foodFish => 'Peixe';

  @override
  String get foodEgg => 'Ovo';

  @override
  String get foodBread => 'Pão';

  @override
  String get foodMilk => 'Leite';

  @override
  String get foodCoffee => 'Café';

  @override
  String get foodYogurt => 'Iogurte';

  @override
  String get foodFruit => 'Fruta';

  @override
  String get foodSalad => 'Salada';

  @override
  String get foodVegetables => 'Legumes';

  @override
  String get foodPasta => 'Macarrão';

  @override
  String get foodPotato => 'Batata';

  @override
  String get foodCassava => 'Mandioca';

  @override
  String get foodCheese => 'Queijo';

  @override
  String get foodJuice => 'Suco';

  @override
  String get foodWater => 'Água';

  @override
  String get defaultWoundAnalysis =>
      'Análise visual de ferida ou lesão detectada';

  @override
  String get petSelectionTitle => 'De qual pet é esta análise?';

  @override
  String get petNew => 'Novo Pet';

  @override
  String get petQuickAnalysis => 'Análise rápida sem salvar';

  @override
  String get paywallBenefit1 => 'Acesso ilimitado a todos os recursos';

  @override
  String get paywallBenefit2 => 'Análises detalhadas e avançadas';

  @override
  String get paywallBenefit3 => 'PDFs completos sem restrições';

  @override
  String get paywallBenefit4 => 'Suporte prioritário';

  @override
  String get featureMicrosTitle => 'Micronutrientes e Sinergia';

  @override
  String get featureMicrosDesc =>
      'Obtenha análise completa de vitaminas, minerais e como eles interagem.';

  @override
  String get foodApple => 'Maçã';

  @override
  String get foodBanana => 'Banana';

  @override
  String get foodCorn => 'Milho';

  @override
  String get foodPeas => 'Ervilha';

  @override
  String get foodCarrot => 'Cenoura';

  @override
  String get foodTomato => 'Tomate';

  @override
  String get foodOnion => 'Cebola';

  @override
  String get foodGarlic => 'Alho';

  @override
  String get foodOrange => 'Laranja';

  @override
  String get foodPineapple => 'Abacaxi';

  @override
  String get unknownFood => 'Alimento Desconhecido';

  @override
  String get actionDelete => 'Apagar';

  @override
  String get plantCareGuide => 'Guia de Cuidados';

  @override
  String get toxicityWarning => 'Alerta de Toxicidade';

  @override
  String get featureMenuPlanTitle => 'Planeamento de Cardápio Inteligente';

  @override
  String get featureMenuPlanDesc =>
      'Crie cardápios semanais personalizados baseados nas suas metas e restrições alimentares.';

  @override
  String get plantHomeSafety => 'Segurança Doméstica';

  @override
  String get plantDangerPets => 'Pode ser perigoso para animais de estimação.';

  @override
  String get plantDangerKids => 'Perigoso para Crianças';

  @override
  String get plantNoAlerts => 'Sem alertas específicos.';

  @override
  String get plantBioPower => 'Poderes Biofílicos';

  @override
  String get plantAirScore => 'Pontuação de Ar';

  @override
  String get plantHumidification => 'Umidificação';

  @override
  String get plantWellness => 'Bem-estar';

  @override
  String get plantPropagationEngine => 'Engenharia de Propagação';

  @override
  String get plantMethod => 'Método';

  @override
  String get plantDifficulty => 'Dificuldade';

  @override
  String get plantStepByStep => 'Passo a Passo';

  @override
  String get plantEcoIntel => 'Inteligência de Ecossistema';

  @override
  String get plantCompanions => 'Plantas Companheiras';

  @override
  String get plantAvoid => 'Evitar';

  @override
  String get plantRepellent => 'Repelente';

  @override
  String get plantFengShui => 'Feng Shui';

  @override
  String get plantPlacement => 'Posicionamento';

  @override
  String get plantSymbolism => 'Simbolismo';

  @override
  String get plantLivingAesthetic => 'Estética Viva';

  @override
  String get plantFlowering => 'Floração';

  @override
  String get plantFlowerColor => 'Cor das Flores';

  @override
  String get plantGrowth => 'Crescimento';

  @override
  String get plantMaxSize => 'Tamanho Máximo';

  @override
  String get plantNeedSun => 'Luminosidade';

  @override
  String get plantNeedWater => 'Rega';

  @override
  String get plantNeedSoil => 'Solo';

  @override
  String get plantSeasonAdjust => 'Ajuste Sazonal';

  @override
  String get seasonWinter => 'Inverno';

  @override
  String get seasonSummer => 'Verão';

  @override
  String get plantClinicalDiagnosis => 'Diagnóstico Clínico';

  @override
  String get plantRecoveryPlan => 'Plano de Recuperação';

  @override
  String get plantUrgency => 'Urgência';

  @override
  String get plantBuyTreatment => 'Comprar Tratamento';

  @override
  String get fallbackNoInfo => 'Sem informação';

  @override
  String get fallbackDirectWatering => 'Rega direta no solo';

  @override
  String get fallbackAsNeeded => 'Conforme necessário';

  @override
  String get advancedDiagnosis => 'Diagnóstico Avançado';

  @override
  String get advancedDiagnosisDesc =>
      'Acesse diagnósticos clínicos detalhados e guias de recuperação passo a passo.';

  @override
  String get biosTitle => 'Segurança e Biofília';

  @override
  String get biosDesc =>
      'Saiba detalhes sobre toxicidade para pets/crianças e benefícios biófilicos da planta.';

  @override
  String get noInformation => 'Sem informação';

  @override
  String get directSoilWatering => 'Rega direta no solo';

  @override
  String get asNeeded => 'Conforme necessário';

  @override
  String get plantFamily => 'Família';

  @override
  String get plantIdentificationTaxonomy => 'Identificação e Taxonomia';

  @override
  String get plantPopularNames => 'Nomes Populares';

  @override
  String get plantScientificName => 'Nome Científico';

  @override
  String get plantOrigin => 'Origem';

  @override
  String get plantDetails => 'Detalhes';

  @override
  String get plantSubstrate => 'Substrato';

  @override
  String get plantFertilizer => 'Fertilizante';

  @override
  String get plantIdealPh => 'pH Ideal';

  @override
  String get plantToxicityDetails => 'Detalhes de Toxicidade';

  @override
  String get safetyAlert => 'Alerta de Segurança';

  @override
  String get close => 'Fechar';

  @override
  String get editPetTitle => 'Editar Perfil';

  @override
  String get newPetTitle => 'Novo Pet';

  @override
  String get petNameLabel => 'Nome do Pet';

  @override
  String get petNameRequired => 'Nome do pet é obrigatório.';

  @override
  String get petBreedLabel => 'Raça';

  @override
  String get petOriginRegion => 'Região de Origem';

  @override
  String get petMorphology => 'Tipo Morfológico';

  @override
  String get unknownRegion => 'Região Desconhecida';

  @override
  String get unknownMorphology => 'Morfologia N/A';

  @override
  String get petAgeLabel => 'Idade Exata (ex: 2 anos 3 meses)';

  @override
  String get petBiologicalProfile => 'Perfil Biológico';

  @override
  String get petActivityLevelLabel => 'Nível de Atividade';

  @override
  String get petReproductiveStatusLabel => 'Status Reprodutivo';

  @override
  String get petIdentity => 'Identidade';

  @override
  String get petHealth => '💉 Saúde';

  @override
  String get petNutrition => '🍖 Alimentação';

  @override
  String get petGallery => 'Galeria';

  @override
  String get petPartners => 'Parceiros';

  @override
  String get petWeightControl => 'Controle de Peso Inteligente';

  @override
  String get petWeightAutoAnalysis =>
      'Análise automática baseada na raça e porte';

  @override
  String get petCurrentWeight => 'Peso Atual (kg)';

  @override
  String get petVaccinationHistory => 'Histórico de Vacinas';

  @override
  String get petLastV10 => 'Última V10/V8';

  @override
  String get petLastRabies => 'Última Antirrábica';

  @override
  String get petHygiene => '🛁 Higiene';

  @override
  String get petBathFrequency => 'Frequência de Banho';

  @override
  String get petMedicalDocs => 'Outros Documentos Médicos';

  @override
  String get petPrescriptions => 'Receitas Veterinárias';

  @override
  String get petVaccineCard => 'Carteira de Vacinação';

  @override
  String get petWoundHistory => 'Histórico de Análises de Feridas';

  @override
  String get petDiseaseHistory => 'Histórico de Análises de Doenças';

  @override
  String get petNoWounds => 'Nenhuma análise de ferida registrada ainda.';

  @override
  String petWoundsCount(int count) {
    return '$count análise(s) registrada(s)';
  }

  @override
  String get petFoodAllergies => 'Alergias Alimentares';

  @override
  String get petFoodAllergiesDesc => 'Ingredientes que devem ser evitados';

  @override
  String get petAddAllergy => 'Adicionar Alergia';

  @override
  String get petFoodPreferences => 'Preferências Alimentares';

  @override
  String get petFoodPreferencesDesc => 'Alimentos que o pet mais gosta';

  @override
  String get petAddPreference => 'Adicionar Preferência';

  @override
  String get petDietRecipes => 'Receitas e Dietas';

  @override
  String get petDeleteTitle => 'Excluir Pet?';

  @override
  String petDeleteContent(Object name) {
    return 'Deseja remover $name e todo o seu histórico? Esta ação não pode ser desfeita.';
  }

  @override
  String get petDeleteConfirm => 'Excluir Definitivamente';

  @override
  String get petChangePhoto => 'Alterar Foto do Perfil';

  @override
  String get petTakePhoto => 'Tirar Foto';

  @override
  String get petChooseGallery => 'Escolher da Galeria';

  @override
  String get petAddMedia => 'Adicionar Mídia';

  @override
  String get petAttachDoc => 'Anexar Documento';

  @override
  String get petCameraPhoto => 'Câmera (Foto)';

  @override
  String get petGalleryPhoto => 'Galeria (Foto)';

  @override
  String get petCameraVideo => 'Câmera (Vídeo)';

  @override
  String get petGalleryVideo => 'Galeria (Vídeo)';

  @override
  String get petEmptyGallery => 'A galeria está vazia';

  @override
  String get petEmptyGalleryDesc => 'Fotos e vídeos dos melhores momentos';

  @override
  String get petAddToGallery => 'Adicionar à Galeria';

  @override
  String get petDocAttached => 'Documento anexado!';

  @override
  String get petDeleteAttachment => 'Excluir Anexo?';

  @override
  String get petDeleteAttachmentContent => 'Esta ação não pode ser desfeita.';

  @override
  String get petSaveSuccess => 'Salvo!';

  @override
  String get petUndoChanges => 'Desfazer alterações';

  @override
  String get petAllSaved => 'Tudo salvo';

  @override
  String get petBasicInfo => 'Informações Básicas';

  @override
  String get petPartnersNoPartners =>
      'Nenhum parceiro cadastrado. Adicione parceiros através do Hub de Parceiros na tela inicial.';

  @override
  String get petPartnersNotFound =>
      'Nenhum parceiro encontrado nesta categoria.';

  @override
  String get petPartnersLinked => 'Vinculado';

  @override
  String get petPartnersNoAddress => 'Endereço não informado';

  @override
  String get petPartnersPhoneHint => 'Digite o telefone';

  @override
  String get petPartnersCall => 'Ligar';

  @override
  String get petPartnersSchedule => 'Agenda';

  @override
  String get petPartnersObs => 'Prac (Rede de Apoio)';

  @override
  String get agendaToday => 'Hoje';

  @override
  String get agendaYesterday => 'Ontem';

  @override
  String get agendaNewEvent => 'Novo Evento';

  @override
  String get agendaTitle => 'Agenda';

  @override
  String get agendaDate => 'Data';

  @override
  String get agendaTime => 'Hora';

  @override
  String get agendaObservations => 'Observações';

  @override
  String get agendaAdd => 'Adicionar Evento';

  @override
  String get agendaTitleHint => 'Título (ex: Consulta, Banho)';

  @override
  String get agendaEmpty =>
      'Nenhum evento registrado.\nAdicione agendamentos, vacinas ou notas.';

  @override
  String get petDiagnosis => 'Diagnóstico';

  @override
  String get petSeverity => 'Gravidade';

  @override
  String get petRecommendations => 'Recomendações';

  @override
  String get petBiometricAnalysis => 'Análise Biométrica';

  @override
  String get petLineage => 'Linhagem';

  @override
  String get petSize => 'Porte';

  @override
  String get petLongevity => 'Longevidade';

  @override
  String get petGrowthCurve => 'Curva de Crescimento Estimada';

  @override
  String get petMonth3 => '3 Meses';

  @override
  String get petMonth6 => '6 Meses';

  @override
  String get petMonth12 => '12 Meses';

  @override
  String get petAdult => 'Adulto';

  @override
  String get petEnergy => 'Energia';

  @override
  String get petIntelligence => 'Inteligência';

  @override
  String get petSociability => 'Sociabilidade';

  @override
  String get petDrive => 'Drive Ancestral';

  @override
  String get petSuggestedPlan => 'Plano Alimentar Sugerido';

  @override
  String get petResultTitle => 'Análise Veterinária 360°';

  @override
  String get petResultViewProfile => 'VER PERFIL DO PET';

  @override
  String get petResultSave => 'Salvar apenas';

  @override
  String get petResultGeneratePDF => 'Gerar PDF';

  @override
  String get petResultDossier => 'Dossiê 360°';

  @override
  String get petSectionObservedSigns => 'Sinais Observados';

  @override
  String get petSectionNutrition => 'Nutrição & Dieta';

  @override
  String get petSectionGrooming => 'Grooming & Higiene';

  @override
  String get petSectionHealth => 'Saúde Preventiva';

  @override
  String get petSectionLifestyle => 'Lifestyle & Educação';

  @override
  String get petInsightSpecialist => 'Insight do Especialista';

  @override
  String get petDisclaimerAI =>
      'Conteúdo gerado por IA. Não substitui diagnóstico veterinário.';

  @override
  String get petMetaPuppy => 'Meta Filhote';

  @override
  String get petMetaAdult => 'Meta Adulto';

  @override
  String get petMetaSenior => 'Meta Sênior';

  @override
  String get petTargetNutrients => 'Nutrientes Alvo';

  @override
  String get petCoatType => 'Tipo de Pelagem';

  @override
  String get petBrushingFreq => 'Escovação';

  @override
  String get petBathSug => 'Banho Sugerido';

  @override
  String get petPredispositions => 'Predisposições';

  @override
  String get petCheckup => 'Checkup';

  @override
  String get petNoData => '--';

  @override
  String get petSavingProfile => 'Salvando no Histórico...';

  @override
  String get petSavedHistory => 'Salvo no Histórico!';

  @override
  String get petProfileCreated => 'Perfil criado com sucesso!';

  @override
  String get petSaveError => 'Erro ao salvar perfil. Tente novamente.';

  @override
  String get petGeneratingPDF => 'Gerando PDF... (Simulação)';

  @override
  String get petUrgencyRed => 'Urgência Veterinária';

  @override
  String get petUrgencyYellow => 'Atenção Necessária';

  @override
  String get petUrgencyGreen => 'Observação';

  @override
  String get petSignCritical => 'Sinais clínicos de risco detectados.';

  @override
  String get petImmediateOrientation => 'Orientação Imediata:';

  @override
  String get petDailyCaloricGoals => 'Metas Calóricas Diárias';

  @override
  String get petPuppy => 'Filhote';

  @override
  String get petSenior => 'Sênior';

  @override
  String get petSecuritySupplements => 'Segurança & Suplementos';

  @override
  String get petSupplementation => 'Suplementação';

  @override
  String get petObesityTendency => 'Tendência Obesidade';

  @override
  String get petCoatGrooming => 'Pelagem & Tosa';

  @override
  String get petType => 'Tipo';

  @override
  String get petFrequency => 'Frequência';

  @override
  String get petPreventiveHealth => 'Saúde Preventiva';

  @override
  String get petPredisposition => 'Predisposição';

  @override
  String get petTrainingEnvironment => 'Treino & Ambiente';

  @override
  String get petTraining => 'Treino';

  @override
  String get petApartmentRef => 'Apartamento';

  @override
  String get petExclusiveInsight => 'Insight Exclusivo';

  @override
  String get petRaceAnalysis => 'Análise da Raça';

  @override
  String get petReliability => 'Confiabilidade';

  @override
  String get petReliabilityLow => 'Baixa';

  @override
  String get petReliabilityMedium => 'Média';

  @override
  String get petReliabilityHigh => 'Alta';

  @override
  String get petNotIdentified => 'Não identificado';

  @override
  String get petNotEstimated => 'Não estimada';

  @override
  String get petVariable => 'Variável';

  @override
  String get petNeutered => 'Castrado';

  @override
  String get petIntact => 'Inteiro';

  @override
  String get petActivityModerate => 'Moderado';

  @override
  String get petBathBiweekly => 'Quinzenal';

  @override
  String get petGenerateWeeklyMenu => 'Gerar Cardápio Semanal';

  @override
  String get petNoDocumentsAttached => 'Nenhum documento anexado';

  @override
  String get petSeeFull => 'Ver Completo';

  @override
  String get petObservationsHistory => 'Observações e Histórico';

  @override
  String get petRegisterObservations =>
      'Registre observações importantes aqui...';

  @override
  String get petNoObservations => 'Nenhuma observação registrada ainda.';

  @override
  String get commonAddText => 'Adicionar Texto';

  @override
  String get commonVoice => 'Voz';

  @override
  String get commonListening => 'Ouvindo...';

  @override
  String commonLoadMore(Object count) {
    return 'Carregar antigas ($count restantes)';
  }

  @override
  String get petWeeklyPlanTitle => 'Plano Alimentar Semanal';

  @override
  String get petNutritionPillarsDesc =>
      'Cada refeição foca nos 5 Pilares (Protéina, Gordura, Fibras, Minerais e Hidratação)';

  @override
  String get backButton => 'Voltar';

  @override
  String get generateReportButton => 'Gerar Relatório';

  @override
  String get reportDetailLevelLabel => 'Nível de Detalhe';

  @override
  String get reportHubTitle => 'Relatório de Parceiros';

  @override
  String get noPartnersForFilters => 'Nenhum parceiro encontrado neste filtro';

  @override
  String get reportSummary => 'Resumo';

  @override
  String get reportDetailed => 'Detalhado';

  @override
  String get reportDescription =>
      'Relatório PDF completo da rede de parceiros.';

  @override
  String get exportPdfTitle => 'Exportar PDF';

  @override
  String get partnerTypeLabel => 'Categoria';

  @override
  String get petActivityLevel => 'Nível de Atividade';

  @override
  String get petReproductiveStatus => 'Status Reprodutivo';

  @override
  String get errorBadPhoto =>
      'Ops! A foto não ficou clara o suficiente. Tente um novo ângulo!';

  @override
  String get errorAiTimeout =>
      'Nossa IA está analisando com cuidado... só mais um momento!';

  @override
  String get aiCalculatingMetrics => 'Gerando cardápio da semana...';

  @override
  String get examBlood => 'Exame de Sangue';

  @override
  String get examUrine => 'Exame de Urina';

  @override
  String get examFeces => 'Exame de Fezes';

  @override
  String get examOther => 'Outros Exames';

  @override
  String get petSeverityLow => 'Baixa';

  @override
  String get petSeverityMedium => 'Média';

  @override
  String get petSeverityHigh => 'Alta';

  @override
  String get petDiagnosisDefault => 'Sem diagnóstico';

  @override
  String get examDeleteTitle => 'Excluir Exame';

  @override
  String get examDeleteContent =>
      'Tem certeza que deseja excluir este exame? Esta ação não pode ser desfeita.';

  @override
  String get petLifeExpectancy => 'Expectativa de Vida';

  @override
  String get petTypicalWeight => 'Peso Típico';

  @override
  String get petTemperament => 'Temperamento';

  @override
  String get petOrigin => 'Origem & História';

  @override
  String get petCuriosities => 'Curiosidades';

  @override
  String errorAddingExam(Object error) {
    return 'Erro ao adicionar exame: $error';
  }

  @override
  String get ocrSuccess =>
      'Texto extraído com sucesso! Clique em \'Explicar Exame\' para análise.';

  @override
  String errorGeneratingExplanation(Object error) {
    return 'Erro ao gerar explicação: $error';
  }

  @override
  String get petEstimatedByBreed => 'Estimado pela raça';

  @override
  String menuTitle(String petName) {
    return 'Cardápio de $petName';
  }

  @override
  String get menuLastWeek => 'Semana Passada';

  @override
  String get menuCurrentWeek => 'Semana Atual';

  @override
  String get menuNextWeek => 'Próxima Semana';

  @override
  String get menuNoHistory => 'Sem histórico disponível.';

  @override
  String get menuNoCurrent => 'Sem cardápio para esta semana.';

  @override
  String get menuNoFuture => 'Sem cardápio futuro planejado.';

  @override
  String get menuGenerateEdit => 'Gerar/Editar Cardápio';

  @override
  String get menuMainNutrients => 'Nutrientes Principais';

  @override
  String get menuNoDetails => 'Sem detalhes disponíveis.';

  @override
  String get menuExportTitle => 'Exportar Cardápio';

  @override
  String get menuExportSelectPeriod => 'Selecione os períodos';

  @override
  String get menuExportReport => 'Exportar Relatório';

  @override
  String get menuNoPeriodSelected => 'Nenhum período selecionado.';

  @override
  String get menuPeriodCustom => 'Personalizado';

  @override
  String get menuPeriodFull => 'Plano Completo';

  @override
  String get petChangesDiscarded => 'Alterações desfeitas.';

  @override
  String get agendaNoEventsTitle =>
      'Nenhum evento registrado.\nAdicione agendamentos, vacinas ou notas.';

  @override
  String get errorOpeningApp => 'Não foi possível abrir o aplicativo';

  @override
  String get pdfFieldLabel => 'Campo';

  @override
  String get pdfFieldValue => 'Informação';

  @override
  String get pdfFieldName => 'Nome Completo';

  @override
  String get pdfFieldBreed => 'Raça';

  @override
  String get pdfFieldAge => 'Idade Exata';

  @override
  String get pdfFieldSex => 'Sexo';

  @override
  String get pdfFieldMicrochip => 'Microchip';

  @override
  String get pdfFieldCurrentWeight => 'Peso Atual';

  @override
  String get pdfFieldIdealWeight => 'Peso Ideal';

  @override
  String get pdfFieldReproductiveStatus => 'Status Reprodutivo';

  @override
  String get pdfFieldActivityLevel => 'Nível de Atividade';

  @override
  String get pdfFieldBathFrequency => 'Frequência de Banho';

  @override
  String get pdfPreferenciasAlimentares => 'Preferências Alimentares';

  @override
  String get pdfHistClinico =>
      'Histórico Clínico (Vacinas, Meds, Procedimentos)';

  @override
  String get pdfExamesLab => 'Exames Laboratoriais';

  @override
  String get pdfAnaliseFeridas => 'Histórico de Análises de Feridas';

  @override
  String get pdfCardapioDetalhado => 'Cardápio Semanal Detalhado';

  @override
  String get pdfRefeicao => 'Refeição';

  @override
  String get pdfKcal => 'kcal';

  @override
  String get pdfSemDescricao => 'Sem descrição';

  @override
  String get pdfPesoStatusUnder => 'Abaixo do ideal';

  @override
  String get pdfPesoStatusOver => 'Acima do ideal';

  @override
  String get pdfPesoStatusIdeal => 'Ideal';

  @override
  String get pdfPesoStatusNormal => 'Peso normal';

  @override
  String get pdfPesoStatusMeta => 'Meta';

  @override
  String get pdfVacinaV10 => 'V10/V8 (Polivalente)';

  @override
  String get pdfVacinaAntirrabica => 'Antirrábica';

  @override
  String get pdfVacinaNaoRegistrada => 'Não registrado';

  @override
  String pdfAlergiasAviso(Object allergies) {
    return '⚠️ ATENÇÃO: $allergies';
  }

  @override
  String get pdfAlergiasNenhuma => '✓ Nenhuma alergia conhecida registrada';

  @override
  String pdfExtractedText(Object text) {
    return 'Texto extraído: $text';
  }

  @override
  String pdfAiAnalysis(Object analysis) {
    return 'Análise IA: $analysis';
  }

  @override
  String pdfDiagnosis(Object diagnosis) {
    return 'Diagnóstico: $diagnosis';
  }

  @override
  String get pdfRecommendations => 'Recomendações';

  @override
  String get pdfAgendaTitle => 'AGENDA GLOBAL';

  @override
  String get pdfObservationsTitle => 'HISTÓRICO DE OBSERVAÇÕES:';

  @override
  String get pdfMetric => 'Métrica';

  @override
  String get pdfWeightControl => 'Controle de Peso';

  @override
  String get pdfWeightHistory => 'Histórico de Pesagens';

  @override
  String get pdfType => 'Tipo';

  @override
  String get pdfDescription => 'Descrição';

  @override
  String get pdfCompleted => 'Concluído';

  @override
  String get pdfPending => 'Pendente';

  @override
  String get pdfEstimatedNote => '* Estimado/Calculado';

  @override
  String get pdfNoPlan => 'Sem plano alimentar registrado.';

  @override
  String get pdfAgendaReport => 'Relatório de Agenda';

  @override
  String get pdfTotalEvents => 'Total de Eventos';

  @override
  String get pdfCompletedEvents => 'Concluídos';

  @override
  String get pdfPendingEvents => 'Pendentes';

  @override
  String get pdfFieldTime => 'Hora';

  @override
  String get pdfFieldEvent => 'Evento';

  @override
  String get pdfFieldPet => 'Pet';

  @override
  String get pdfAgendaToday => 'Hoje';

  @override
  String get pdfObservations => 'Observações';

  @override
  String get pdfSummaryReport => 'Relatório Resumido';

  @override
  String get pdfNoImages => 'Nenhuma imagem encontrada na galeria.';

  @override
  String get pdfAttachedDocs => 'Documentos Anexados (PDFs/Arquivos):';

  @override
  String get pdfLinkedPartners => 'Parceiros Vinculados:';

  @override
  String pdfPartnerLoadError(Object count) {
    return '⚠️ $count parceiro(s) vinculado(s), mas não foi possível carregar os detalhes.';
  }

  @override
  String get pdfServiceHistory => 'Histórico de Atendimentos:';

  @override
  String get pdfNoPartners => 'Nenhum parceiro vinculado a este perfil.';

  @override
  String get pdfAgendaEvents => 'Agenda e Eventos';

  @override
  String get pdfHistoryUpcoming => 'Histórico e Próximos Compromissos';

  @override
  String get pdfUpcomingEvents => 'Próximos Eventos';

  @override
  String get pdfRecentHistory => 'Histórico Recente';

  @override
  String get partnersSelectTitle => 'Selecionar Parceiro';

  @override
  String get partnersExportPdf => 'Exportar PDF';

  @override
  String get partnersCategory => 'Categoria';

  @override
  String get partnersDetailLevel => 'Nível de Detalhe';

  @override
  String get partnersSummary => 'Resumo';

  @override
  String get partnersDetailed => 'Detalhado';

  @override
  String get partnersExportDisclaimer =>
      'Relatório PDF completo da rede de parceiros.';

  @override
  String get partnersGenerateReport => 'Gerar Relatório';

  @override
  String get partnersBack => 'Voltar';

  @override
  String get partnersRegister => 'Cadastrar';

  @override
  String get partnersNoneFound => 'Nenhum parceiro encontrado na base.';

  @override
  String partnersNoneInCategory(Object category) {
    return 'Nenhum parceiro na categoria $category.';
  }

  @override
  String get partnersRadarHint =>
      'Use o botão \'Radar\' para buscar locais reais.';

  @override
  String get partnersLocationDenied => 'Permissão de localização negada.';

  @override
  String get partnersLocationPermanentlyDenied =>
      'Permissão negada permanentemente nas configurações.';

  @override
  String get partnersLocationError =>
      'Não foi possível obter sua localização atual.';

  @override
  String get partnersRadarDetecting =>
      'Detectamos estabelecimentos reais na sua região';

  @override
  String get partnersRadarTracking => 'Rastreando estabelecimentos via GPS...';

  @override
  String get partnersRadarNoResults => 'Nenhum local nesta categoria.';

  @override
  String get menuDietType => 'Tipo de Dieta';

  @override
  String get pdfError => 'Erro ao gerar PDF:';

  @override
  String get pdfFieldPhone => 'Telefone';

  @override
  String get pdfFieldEmail => 'E-mail';

  @override
  String get pdfFieldAddress => 'Endereço';

  @override
  String get pdfFieldDetails => 'Detalhes e Especialidades';

  @override
  String get partnerTeamMembers => 'Integrantes da Equipe/Corpo Clínico';

  @override
  String get partnerNotesTitle => 'Notas e Observações';

  @override
  String get partnerNotesEmpty =>
      'Nenhuma anotação ainda.\nEscreva ou grave lembretes sobre este parceiro.';

  @override
  String get petWoundDeleteTitle => 'Excluir Análise';

  @override
  String get petWoundDeleteConfirm =>
      'Tem certeza que deseja excluir esta análise de ferida? Esta ação não pode ser desfeita.';

  @override
  String get petWoundDeleteSuccess => 'Análise de ferida excluída com sucesso';

  @override
  String get petWoundDeleteError => 'Erro ao excluir análise:';

  @override
  String get selectRegime => 'Selecione ao menos um regime.';

  @override
  String get selectDatesError => 'Selecione as datas.';

  @override
  String get menuPlannedSuccess => '✅ Cardápio Inteligente Planejado!';

  @override
  String get goalWeightMaintenance => 'Manutenção de Peso';

  @override
  String get goalWeightLoss => 'Perda de Peso';

  @override
  String get goalMuscleGain => 'Ganho de Massa';

  @override
  String get goalRecovery => 'Recuperação/Convalescença';

  @override
  String get menuProfileHeader => '⚠️ PERFIL ESPECÍFICO DO PET:';

  @override
  String get menuAllergiesForbidden => '- ALERGIAS (PROIBIDO)';

  @override
  String get menuPreferences => '- PREFERÊNCIAS';

  @override
  String get menuRecentMeals => '- ÚLTIMAS REFEIÇÕES (PARA VARIAÇÃO)';

  @override
  String get petSizeSmall => 'Pequeno';

  @override
  String get petSizeMedium => 'Médio';

  @override
  String get petSizeLarge => 'Grande';

  @override
  String get petSizeGiant => 'Gigante';

  @override
  String get petCoatShort => 'Curto';

  @override
  String get petCoatLong => 'Longo';

  @override
  String get petCoatDouble => 'Duplo';

  @override
  String get petCoatWire => 'Duro';

  @override
  String get petCoatCurly => 'Encaracolado';

  @override
  String get petFullAnalysisTitle => 'Análise Completa da Raça';

  @override
  String get petGeneticAnalysisSub => 'Análise Genética Detalhada';

  @override
  String get petGeneticId => '🧬 Identificação Genética';

  @override
  String get petPrimaryRace => 'Raça Predominante';

  @override
  String get petSecondaryRaces => 'Raças Secundárias';

  @override
  String get petPhysicalChars => '📏 Características Físicas';

  @override
  String get petWeightEstimated => 'Peso Estimado';

  @override
  String get petHeight => 'Altura';

  @override
  String get petExpectancy => 'Expectativa de Vida';

  @override
  String get petCommonColors => 'Cores Comuns';

  @override
  String get petTemperamentTitle => '🎭 Temperamento e Personalidade';

  @override
  String get petPersonality => 'Personalidade';

  @override
  String get petSocialBehavior => 'Comportamento Social';

  @override
  String get petEnergyLevel => 'Nível de Energia';

  @override
  String get petRecommendedCare => '💚 Cuidados Recomendados';

  @override
  String get petExercise => '🏃 Exercício';

  @override
  String get petOriginHistory => '📜 Origem e História';

  @override
  String get petCuriositiesTitle => '✨ Curiosidades';

  @override
  String get petNotIdentifiedPlural => 'Não identificadas';

  @override
  String get petVaried => 'Variadas';

  @override
  String get petDetailsUnavailable =>
      'Detalhes completos indisponíveis. Realize uma nova análise.';

  @override
  String get agendaExportTitle => 'Exportar Agenda';

  @override
  String get agendaReportType => 'Tipo de Relatório:';

  @override
  String get agendaReportSummary => 'Resumo';

  @override
  String get agendaReportDetail => 'Detalhamento';

  @override
  String get agendaNoEventsDay => 'Sem eventos neste dia';

  @override
  String agendaEventsCount(Object count) {
    return '$count eventos';
  }

  @override
  String get agendaGeneratePDF => 'Gerar PDF';

  @override
  String get agendaGlobalTitle => 'Agenda Global';

  @override
  String get agendaViewCalendar => 'Ver Calendário';

  @override
  String get agendaViewAll => 'Ver Lista Completa';

  @override
  String get agendaNoEventsRegistered => 'Nenhum evento registado na agenda.';

  @override
  String get agendaNoEventsTodayDetail => 'Nenhum evento para este dia.';

  @override
  String get agendaAllPets => 'Todos os Animais';

  @override
  String get agendaExportPDF => 'Exportar Relatório PDF';

  @override
  String get agendaReportingPeriod => 'Período do Relatório';

  @override
  String get agendaFilterPet => 'Filtrar por Animal';

  @override
  String get agendaFilterCategory => 'Filtrar por Categoria';

  @override
  String get agendaDetailLevel => 'Nível de Detalhe';

  @override
  String get agendaDetailedTable => 'Tabela Detalhada';

  @override
  String get agendaSummaryOnly => 'Apenas Resumo';

  @override
  String get agendaButtonGenerate => 'Gerar PDF';

  @override
  String get agendaAllCategories => 'Todas as Categorias';

  @override
  String get agendaNoPartnerLinked =>
      'Nenhum parceiro vinculado a este evento.';

  @override
  String agendaProfileNotFound(Object name, Object petName) {
    return 'Perfil de $petName não encontrado.';
  }

  @override
  String get agendaServiceRecord => 'Ficha do Atendimento';

  @override
  String get agendaAppointmentDetails => 'Detalhes do Agendamento';

  @override
  String get agendaResponsiblePartner => 'Parceiro Responsável';

  @override
  String get agendaPartnerNotFound => 'Parceiro não encontrado ou excluído.';

  @override
  String get agendaMarkCompleted => 'MARCAR COMO CONCLUÍDO';

  @override
  String get agendaEventCompleted => 'Evento marcado como concluído!';

  @override
  String get agendaEventUpdated => 'Evento atualizado com sucesso!';

  @override
  String get agendaViewRegistration => 'Toque para ver o cadastro';

  @override
  String get agendaWhatsAppChat => 'Falar pelo WhatsApp';

  @override
  String get agendaWebsiteError => 'Erro ao abrir site';

  @override
  String get agendaViewProfile => '(Toque para ver o perfil)';

  @override
  String get agendaOriginalDataMissing =>
      'Dados originais do evento não encontrados para edição.';

  @override
  String get agendaEditEvent => 'Editar Evento';

  @override
  String get agendaChange => 'Alterar';

  @override
  String get agendaAttendantSpecialist => 'Atendente / Especialista';

  @override
  String get agendaSelectAttendant => 'Selecione o atendente';

  @override
  String get agendaEventTitle => 'Título do Evento';

  @override
  String get agendaTitleExample => 'ex: Vacina Polivalente V10';

  @override
  String get agendaObservationsHint => 'Digite ou use o microfone...';

  @override
  String get agendaAttachmentsFull => 'Anexos (PDF ou Fotos)';

  @override
  String get agendaEnterTitle => 'Por favor, insira um título';

  @override
  String get agendaSaveChanges => 'SALVAR ALTERAÇÕES';

  @override
  String get agendaConfirmEvent => 'CONFIRMAR EVENTO';

  @override
  String get commonCamera => 'Câmera';

  @override
  String get commonGallery => 'Galeria';

  @override
  String get commonPDFFile => 'Arquivo PDF';

  @override
  String get petConsultVet => 'Consulte veterinário';

  @override
  String get petHemogramaCheckup => 'Hemograma';

  @override
  String get petPositiveReinforcement => 'Reforço Positivo';

  @override
  String get petInteractiveToys => 'Brinquedos Interativos';

  @override
  String get petConsultVetCare => 'Cuidados Veterinários';

  @override
  String get pdfFieldObservations => 'Observações';

  @override
  String get petBreedMixed => 'Raça Mista';

  @override
  String get petAllergies => 'Alergias';

  @override
  String get explainExam => 'Explicar Exame';

  @override
  String get attendantName => 'Nome do Atendente';

  @override
  String get partnerDetailsRole => 'Função';

  @override
  String get pdfDiagnosisTriage => 'Triage Veterinária';

  @override
  String get pdfFieldBreedSpecies => 'Raça/Espécie';

  @override
  String get pdfFieldUrgency => 'Urgência';

  @override
  String get pdfFieldProfessionalRecommendation => 'Recomendação Profissional';

  @override
  String get pdfDossierTitle => 'Dossiê 360º de Pet';

  @override
  String get pdfSectionIdentity => '1. IDENTIDADE E PERFIL';

  @override
  String get pdfSectionNutrition => '2. NUTRIÇÃO E DIETA ESTRATÉGICA';

  @override
  String get pdfSectionGrooming => '3. GROOMING & HIGIENE';

  @override
  String get pdfSectionHealth => '4. SAÚDE PREVENTIVA';

  @override
  String get pdfSectionLifestyle => '5. LIFESTYLE & EDUCAÇÃO';

  @override
  String get pdfFieldPredominantBreed => 'Raça Predominante';

  @override
  String get pdfFieldBehavioralProfile => 'Perfil Comportamental';

  @override
  String get pdfFieldEnergyLevel => 'Nível de Energia';

  @override
  String get pdfFieldIntelligence => 'Inteligência';

  @override
  String get pdfFieldSociability => 'Sociabilidade';

  @override
  String get pdfFieldAncestralDrive => 'Drive Ancestral';

  @override
  String get pdfFieldEstimatedGrowthCurve => 'Curva de Crescimento Estimada';

  @override
  String get pdfFieldDailyCaloricGoals => 'Metas Calóricas Diárias';

  @override
  String get pdfFieldPuppy => 'Filhote';

  @override
  String get pdfFieldAdult => 'Adulto';

  @override
  String get pdfFieldSenior => 'Sênior';

  @override
  String get pdfFieldTargetNutrients => 'Nutrientes Alvo';

  @override
  String get pdfFieldSuggestedSupplementation => 'Suplementação Sugerida';

  @override
  String get pdfFieldFoodSafety => 'Segurança Alimentar';

  @override
  String get pdfAlertObesity => '⚠️ ALERTA: Tendência à obesidade detectada';

  @override
  String get pdfFieldSafeFoods => 'Alimentos Seguros (Benigna)';

  @override
  String get pdfFieldToxicFoods => 'Alimentos Tóxicos (Maligna)';

  @override
  String get pdfFieldFoodName => 'Alimento';

  @override
  String get pdfFieldBenefit => 'Benefício';

  @override
  String get pdfFieldRisk => 'Risco';

  @override
  String get pdfFieldWeeklyMenu => 'Cardápio Semanal (Dieta Natural)';

  @override
  String get pdfFieldReason => 'Motivo';

  @override
  String get pdfFieldCoatType => 'Tipo de Pelo';

  @override
  String get pdfFieldBrushingFrequency => 'Frequência de Escovação';

  @override
  String get pdfFieldRecommendedProducts => 'Produtos Recomendados';

  @override
  String get pdfFieldDiseasePredisposition => 'Predisposição a Doenças';

  @override
  String get pdfFieldAnatomicalCriticalPoints => 'Pontos Críticos Anatômicos';

  @override
  String get pdfFieldVeterinaryCheckup => 'Checkup Veterinário';

  @override
  String get pdfFieldMandatoryExams => 'Exames';

  @override
  String get pdfFieldClimateSensitivity => 'Sensibilidade Climática';

  @override
  String get pdfFieldHeat => 'Calor';

  @override
  String get pdfFieldCold => 'Frio';

  @override
  String get pdfSectionImmunization => '4.1 Protocolo de Imunização';

  @override
  String get pdfFieldEssentialVaccines => 'Vacinas Essenciais';

  @override
  String get pdfFieldVaccineGoal => 'Objetivo';

  @override
  String get pdfFieldFirstDose => '1ª dose';

  @override
  String get pdfFieldBooster => 'Reforço';

  @override
  String get pdfFieldPreventiveCalendar => 'Calendário Preventivo';

  @override
  String get pdfFieldPuppies => 'Filhotes';

  @override
  String get pdfFieldAdults => 'Adultos';

  @override
  String get pdfFieldParasitePrevention => 'Prevenção Parasitária';

  @override
  String get pdfFieldDewormer => 'Vermífugo';

  @override
  String get pdfFieldTickFlea => 'Pulgas/Carrapatos';

  @override
  String get pdfFieldOralBoneHealth => 'Saúde Bucal e Óssea';

  @override
  String get pdfFieldPermittedBones => 'Ossos Permitidos';

  @override
  String get pdfFieldFrequency => 'Frequência';

  @override
  String get pdfFieldTraining => 'Treinamento';

  @override
  String get pdfFieldTrainingDifficulty => 'Dificuldade de Adestramento';

  @override
  String get pdfFieldRecommendedMethods => 'Métodos Recomendados';

  @override
  String get pdfFieldIdealEnvironment => 'Ambiente Ideal';

  @override
  String get pdfFieldOpenSpace => 'Espaço Aberto';

  @override
  String get pdfFieldApartmentAdaptation => 'Adaptação Apartamento';

  @override
  String get pdfFieldPeriod => 'Período';

  @override
  String get pdfFieldRegime => 'Regime';

  @override
  String get pdfFieldDailyKcalMeta => 'Meta Calórica Diária';

  @override
  String get pdfFieldDetailsComposition =>
      'COMPOSIÇÃO E DETALHAMENTO (5 PILARES):';

  @override
  String get pdfPeriodWeekly => 'Semanal';

  @override
  String get pdfNoMealsPlanned => 'Nenhuma refeição planejada.';

  @override
  String get pdfFieldGeneralGuidelines => 'ORIENTAÇÕES GERAIS';

  @override
  String get pdfFieldMainNutrients => 'Principais Nutrientes';

  @override
  String get pdfLastDose => 'Última Aplicação';

  @override
  String get pdfNextDose => 'Próxima Dose';

  @override
  String get eventVaccine => 'Vacina';

  @override
  String get eventBath => 'Banho';

  @override
  String get eventGrooming => 'Tosa';

  @override
  String get eventVeterinary => 'Veterinário';

  @override
  String get eventMedication => 'Medicamento';

  @override
  String get eventOther => 'Outro';

  @override
  String get pdfFieldMentalStimulus => 'Estímulo Mental';

  @override
  String get pdfFieldSuggestedActivities => 'Atividades';

  @override
  String get pdfFieldExpertInsight => 'INSIGHT DO ESPECIALISTA';

  @override
  String get pdfDisclaimer =>
      'Aviso: Este relatório foi gerado por IA e não substitui consulta veterinária profissional.';

  @override
  String get btnCancel => 'Cancelar';

  @override
  String get processingAnalysis => 'Processando Análise...';

  @override
  String get labExamsSubtitle => 'Histórico e Resultados';

  @override
  String get labExamsTitle => 'Exames Laboratoriais';

  @override
  String get pdfFilterTitle => 'Filtrar Seções do PDF';

  @override
  String get pdfFilterSubtitle =>
      'Selecione as seções que deseja incluir no relatório:';

  @override
  String get pdfFilterDisclaimer =>
      'O relatório incluirá apenas as seções selecionadas';

  @override
  String get pdfSelectAll => 'Selecionar Tudo';

  @override
  String get pdfGenerate => 'Gerar PDF';

  @override
  String get sectionIdentity => 'Identidade';

  @override
  String get sectionHealth => 'Saúde';

  @override
  String get sectionNutrition => 'Nutrição';

  @override
  String get sectionGallery => 'Galeria';

  @override
  String get sectionPartners => 'Parceiros';

  @override
  String get sectionDescIdentity => 'Informações básicas e perfil biológico';

  @override
  String get sectionDescHealth => 'Histórico de vacinas, peso e exames';

  @override
  String get sectionDescNutrition => 'Plano alimentar semanal e preferências';

  @override
  String get sectionDescGallery => 'Fotos e documentos anexados';

  @override
  String get sectionDescPartners => 'Rede de apoio e parceiros vinculados';

  @override
  String get observationNew => 'Nova Observação';

  @override
  String get observationHint => 'Digite sua observação...';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get voiceNotAvailable => 'Reconhecimento de voz não disponível';

  @override
  String shopItems(int count) {
    return '$count Itens';
  }

  @override
  String get shopSyncPlan => 'Sincronizar Plano';

  @override
  String get shopClearDone => 'Limpar Concluídos';

  @override
  String get shopEmptyTitle => 'Sua lista está vazia';

  @override
  String get shopEmptySubtitle =>
      'Adicione itens manualmente ou\ngere a partir do seu cardápio.';

  @override
  String get shopGenerateFromMenu => 'Gerar do Cardápio Semanal';

  @override
  String get shopNoMenuError => 'Crie um cardápio primeiro!';

  @override
  String get shopReplaceTitle => 'Substituir lista?';

  @override
  String get shopReplaceContent =>
      'Isso vai apagar a lista atual e criar uma nova baseada no cardápio.';

  @override
  String get shopGenerateBtn => 'Gerar Lista';

  @override
  String get shopGeneratedSuccess => '✅ Lista gerada com sucesso!';

  @override
  String get shopAddItemTitle => 'Adicionar Item';

  @override
  String get shopItemName => 'Nome do Item';

  @override
  String get shopItemQty => 'Quantidade (ex: 2kg, 1 un)';

  @override
  String get shopDefaultQty => '1 porção';

  @override
  String get backupOptimizeTitle => 'Backup e Otimização';

  @override
  String get backupOptimizeDesc =>
      'Gera um PDF completo com todo o histórico do pet (incluindo fotos e anexos) e permite limpar registros antigos para liberar espaço.';

  @override
  String get backupNoPets => 'Nenhum pet encontrado.';

  @override
  String get backupSelectPet => 'Selecione o Pet';

  @override
  String get backupProcessing => 'Processando...';

  @override
  String get backupGenerateBtn => 'Gerar e Otimizar';

  @override
  String get backupOptimizationTitle => 'Otimização de Armazenamento';

  @override
  String get backupOptimizationContent =>
      'Backup PDF gerado com sucesso!\n\nDeseja remover registros com mais de 2 anos (Observações e Feridas) para liberar espaço no dispositivo? O histórico antigo permanecerá salvo no PDF que você acabou de exportar.';

  @override
  String get backupKeepAll => 'Manter Tudo';

  @override
  String get backupCleanOld => 'Limpar Antigos';

  @override
  String get backupSuccessClean => 'Limpeza concluída! App otimizado.';

  @override
  String get backupNoDataClean => 'Nenhum dado antigo encontrado para limpeza.';

  @override
  String get backupProfileNotFound => 'Perfil não encontrado';

  @override
  String commonSyncError(String error) {
    return 'Erro ao sincronizar: $error';
  }

  @override
  String get petDefaultName => 'este pet';

  @override
  String get diagnosisPending => 'Sem diagnóstico';

  @override
  String get severityLow => 'Baixa';

  @override
  String get severityMedium => 'Média';

  @override
  String get severityHigh => 'Alta';

  @override
  String get commonSaveNameFirst => 'Salve o pet ou insira o nome primeiro.';

  @override
  String get commonFilePrefix => 'Arquivo: ';

  @override
  String get commonNoAttachments => 'Nenhum documento anexado.';

  @override
  String get commonView => 'Visualizar';

  @override
  String get aiAnalysis => 'Análise Assistida';

  @override
  String get commonError => 'Erro';

  @override
  String get commonEdit => 'Editar';

  @override
  String get agendaTabUpcoming => 'Próximos';

  @override
  String get agendaTabPast => 'Passados';

  @override
  String get agendaTabAll => 'Todos';

  @override
  String get agendaNoUpcoming => 'Nenhum evento próximo';

  @override
  String get agendaNoPast => 'Nenhum evento passado';

  @override
  String get agendaNoEvents => 'Nenhum evento cadastrado';

  @override
  String get agendaNoFiltered => 'Nenhum evento deste tipo';

  @override
  String get agendaDeleteTitle => 'Excluir Evento?';

  @override
  String agendaDeleteContent(String title) {
    return 'Tem certeza que deseja excluir \"$title\"?';
  }

  @override
  String get agendaDeleted => 'Evento excluído';

  @override
  String get agendaCreated => 'Evento criado!';

  @override
  String get agendaUpdated => 'Evento atualizado!';

  @override
  String get agendaStatusOverdue => 'ATRASADO';

  @override
  String get agendaStatusToday => 'HOJE';

  @override
  String get agendaFieldTitle => 'Título';

  @override
  String get agendaFieldType => 'Tipo';

  @override
  String get agendaFieldVaccineSelect => 'Selecione a Vacina';

  @override
  String get agendaFieldVaccineName => 'Nome da Vacina';

  @override
  String get agendaVaccineOther => 'Outra vacina';

  @override
  String get agendaRequired => 'Campo obrigatório';

  @override
  String get btnDelete => 'Excluir';

  @override
  String get partnerRegisterTitle => 'Cadastrar Parceiro';

  @override
  String get partnerEditTitle => 'Editar Parceiro';

  @override
  String get partnerDeleteTitle => 'Excluir Parceiro';

  @override
  String partnerDeleteContent(String name) {
    return 'Deseja remover \"$name\" da sua rede de apoio?';
  }

  @override
  String get partnerDeleted => 'Parceiro removido.';

  @override
  String partnerSaved(String name) {
    return 'Parceiro \"$name\" salvo com sucesso!';
  }

  @override
  String partnerSaveError(String error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String get partnerCantDeleteLinked =>
      'Não é possível excluir: Este parceiro está vinculado a um Pet.';

  @override
  String get partnerBtnSave => 'SALVAR PARCEIRO';

  @override
  String get partnerBtnDelete => 'EXCLUIR PARCEIRO';

  @override
  String get partnerDangerZone => 'Zona de Perigo';

  @override
  String get partnerDangerZoneDesc =>
      'Ao excluir este parceiro, ele será removido permanentemente. Esta ação é irreversível.';

  @override
  String get partnerRadarTitle => 'Radar Geo';

  @override
  String get partnerRadarHint => 'Toque para alterar o raio de busca';

  @override
  String get partnerRadarScanning => 'Sintonizando Radar e GPS...';

  @override
  String get partnerRadarNoResults => 'Nenhum local encontrado.';

  @override
  String get partnerRadarPermission => 'Permissão de localização necessária.';

  @override
  String get partnerRadarGPSCallbackError =>
      'GPS não retornou coordenadas válidas. Verifique as permissões.';

  @override
  String get partnerRadarFoundTitle =>
      'Estabelecimentos reais detectados na sua região:';

  @override
  String get partnerFieldEstablishment => 'Nome do Estabelecimento';

  @override
  String get partnerFieldPhone => 'Telefone / WhatsApp';

  @override
  String get partnerFieldInstagram => 'Instagram (ex: @meupet)';

  @override
  String get partnerFieldHours => 'Horário de Funcionamento';

  @override
  String get partnerField24h => 'Plantão 24h / Emergência';

  @override
  String get partnerField24hSub => 'Local funciona ininterruptamente';

  @override
  String get partnerFieldSpecialties => 'Especialidades (separe por vírgula)';

  @override
  String get partnerFieldWebsite => 'Website';

  @override
  String get partnerFieldEmail => 'E-mail';

  @override
  String get partnerFieldAddress => 'Endereço Completo';

  @override
  String get partnerTeamTitle => 'Corpo Clínico / Equipe';

  @override
  String get partnerTeamAddHint => 'Adicionar nome (ex: Dra. Ana)';

  @override
  String get partnerCategory => 'Categoria';

  @override
  String get partnerNotesHint => 'Nova observação...';

  @override
  String get partnerRadarButtonTitle => 'Busca Inteligente por Radar';

  @override
  String get partnerRadarButtonDesc => 'Encontre e import dados via GPS';

  @override
  String partnersRadiusInfo(String radius) {
    return 'Mostrando parceiros em um raio de ${radius}km';
  }

  @override
  String get partnersEmpty =>
      'Nenhum parceiro encontrado\nneste raio de busca.';

  @override
  String get partnersIncreaseRadius => 'Aumentar Raio de Busca';

  @override
  String get partnersSuggestion =>
      'Baseado na análise do seu pet, encontramos estes especialistas para você.';

  @override
  String partnersKmFromYou(String dist) {
    return '$dist km de você';
  }

  @override
  String get partnersCall => 'Ligar';

  @override
  String get partnersMap => 'Mapa';

  @override
  String get partnersLinkTitle => 'Vincular Parceiro';

  @override
  String partnersLinkContent(String name) {
    return 'Deseja adicionar \"$name\" à sua Rede de Apoio personalizada?';
  }

  @override
  String partnersLinkSuccess(String name) {
    return '\"$name\" vinculado com sucesso!';
  }

  @override
  String get partnersBtnLink => 'Vincular';

  @override
  String get backupGoogleDrive => 'Backup no Google Drive';

  @override
  String get backupSignIn => 'Conectar ao Google Drive';

  @override
  String get backupSignOut => 'Desconectar';

  @override
  String get backupCreate => 'Fazer Backup Agora';

  @override
  String get backupRestore => 'Restaurar Dados';

  @override
  String get backupDelete => 'Eliminar Backup';

  @override
  String get backupDeleteAll => 'Eliminar Todos os Dados';

  @override
  String get backupStatus => 'Status do Backup';

  @override
  String get backupLastBackup => 'Último backup';

  @override
  String get backupNoBackup => 'Nenhum backup encontrado';

  @override
  String get backupSignedInAs => 'Conectado como';

  @override
  String get backupNotSignedIn => 'Não conectado';

  @override
  String get backupInProgress => 'Fazendo backup...';

  @override
  String get backupSuccess => 'Backup concluído com sucesso!';

  @override
  String get backupFailed => 'Falha no backup. Tente novamente.';

  @override
  String get backupRestoreInProgress => 'Restaurando dados...';

  @override
  String get backupRestoreSuccess =>
      'Dados restaurados com sucesso! Reinicie o app para garantir total integridade.';

  @override
  String get backupRestoreFailed => 'Falha na restauração. Tente novamente.';

  @override
  String get backupDeleteConfirmTitle => 'Eliminar Backup?';

  @override
  String get backupDeleteConfirmBody =>
      'Tem certeza que deseja eliminar o backup do Google Drive?';

  @override
  String get backupDeleteSuccess => 'Backup eliminado do Google Drive';

  @override
  String get backupDeleteFailed => 'Falha ao eliminar backup';

  @override
  String get backupDeleteAllConfirmTitle => 'Eliminar TODOS os Dados?';

  @override
  String get backupDeleteAllConfirmBody =>
      'Tem certeza? Esta ação apagará permanentemente todos os seus pets e histórico do telemóvel e do Google Drive. Esta ação não pode ser desfeita.';

  @override
  String get backupDeleteAllSuccess => 'Todos os dados foram eliminados';

  @override
  String get backupDeleteAllFailed => 'Falha ao eliminar dados';

  @override
  String get backupLoginCancelled => 'Login cancelado';

  @override
  String get backupDriveFullError =>
      'Google Drive cheio. Libere espaço e tente novamente.';

  @override
  String get backupNetworkError =>
      'Sem conexão com a internet. Verifique sua rede.';

  @override
  String get backupDescription =>
      'Seus dados são salvos de forma segura e privada na pasta oculta do app no seu Google Drive. Apenas você tem acesso.';

  @override
  String get petBreedUnknown => 'Raça não identificada';

  @override
  String get petSRD => 'Sem Raça Definida (SRD)';

  @override
  String get agendaNoAttendants => 'Sem membros na equipe';

  @override
  String get petAnalysisResults => 'Resultados Análise';

  @override
  String get petAnalysisEmpty => 'Nenhuma análise registrada.';

  @override
  String get petAnalysisDateUnknown => 'Data não registrada';

  @override
  String get petAnalysisProfileDate => ' (Data do Perfil)';

  @override
  String get petAnalysisViewImage => 'Ver Imagem Analisada';

  @override
  String get commonFileNotFound => 'Arquivo não encontrado no dispositivo.';

  @override
  String get petAnalysisDefaultTitle => 'ANÁLISE';

  @override
  String get errorScreenTitle => 'Ops! Tivemos um imprevisto.';

  @override
  String get errorScreenBody =>
      'Ocorreu um erro ao processar sua solicitação. Não se preocupe, seus dados estão seguros.';

  @override
  String get errorScreenButton => 'Voltar';

  @override
  String get errorScreenTechnicalDetails => 'Detalhes técnicos:';

  @override
  String get backupSectionTitle => '💾 Backup do Banco de Dados';

  @override
  String get helpBackupRestoreSecurity =>
      '🔒 Segurança: O backup está criptografado. Para restaurar, você deve estar logado com a mesma conta que criou o arquivo.';

  @override
  String get helpSecurityEndToEnd => 'Criptografia de Ponta a Ponta';

  @override
  String get helpSecurityAes => '✅ Banco de Dados AES-256 (Padrão Bancário)';

  @override
  String get helpSecurityKey => '✅ Chave derivada da sua senha pessoal';

  @override
  String get helpSecurityAccess =>
      '✅ Somente você (o proprietário do login) acessa os dados';

  @override
  String get helpSecurityBackupProtection =>
      '✅ Mesma proteção aplicada aos backups exportados';

  @override
  String get backupSuccessTitle => 'Backup Concluído!';

  @override
  String get backupSuccessBody =>
      'Seu arquivo de backup foi salvo com sucesso. Você pode encontrá-lo na pasta que selecionou.';

  @override
  String get backupErrorGeneric =>
      'Operação cancelada ou falha. Tente selecionar outra pasta (como Downloads) ou use Compartilhar.';

  @override
  String get backupSecurityNotice =>
      'Os backups são criptografados com sua senha atual. Apenas o proprietário do login original pode restaurar estes dados.';

  @override
  String get backupTechnicalErrorTitle => 'Erro Técnico';

  @override
  String backupTechnicalErrorBody(String error) {
    return 'Falha ao exportar:\n\n$error\n\nVerifique as permissões do sistema.';
  }

  @override
  String get backupExcellent => 'Excelente';

  @override
  String get backupShare => 'Compartilhar';

  @override
  String get backupSave => 'Salvar';

  @override
  String get backupImport => 'Importar Backup';

  @override
  String get backupLocalTitle => 'Backup Local';

  @override
  String get backupDescriptionText =>
      'Exporte seus dados para um arquivo ou restaure de um backup anterior. Recomendamos salvar na pasta Downloads.';

  @override
  String get backupPermissionError =>
      'Permissão de arquivos necessária para exportar.';

  @override
  String get backupRestoreConfirmTitle => 'Restaurar Backup?';

  @override
  String get backupRestoreConfirmBody =>
      'Esta ação irá substituir todos os dados atuais pelos dados do arquivo. Deseja continuar?';

  @override
  String get backupRestoreError =>
      'Falha ao importar backup. Verifique se o arquivo é válido.';

  @override
  String get helpBackupExportTitle => 'Exportar Backup';

  @override
  String get helpBackupExportDesc =>
      '1. Vá em Ajustes → Backup Local\n2. Clique em \"Exportar\"\n3. Escolha a pasta \"Downloads\" e salve o arquivo .scannut\n\n✅ Seus dados ficam salvos em um arquivo seguro no seu celular';

  @override
  String get helpBackupImportTitle => 'Restaurar Backup';

  @override
  String get helpBackupImportDesc =>
      '1. Vá em Ajustes → Backup Local\n2. Clique em \"Importar\"\n3. Selecione o arquivo .scannut';

  @override
  String get helpSecurityTitle => 'PROTEÇÃO E CRIPTOGRAFIA';

  @override
  String get helpSecuritySubtitle =>
      'O banco de dados é protegido localmente. Mantenha seu backup em dia para evitar perda da chave de acesso.';

  @override
  String get helpSecurityAesItem =>
      '🔒 Criptografia AES-256: Seus dados são embaralhados para garantir que ninguém consiga ler o arquivo fora deste app.';

  @override
  String get helpSecurityKeyItem =>
      '🔑 Chave de Segurança: O app gera uma chave única salva no armazenamento seguro do seu celular.';

  @override
  String get helpSecurityWarningItem =>
      '⚠️ Atenção: Se você limpar todos os dados do sistema ou formatar o celular sem um backup externo, a chave pode ser perdida e os dados ficarão inacessíveis.';

  @override
  String get helpProSection => '💎 ScanNut Pro';

  @override
  String get helpPrivacySection => '🔒 Privacidade e Segurança';

  @override
  String get helpProBenefitsTitle => 'Benefícios da Assinatura';

  @override
  String get helpProBenefitsList =>
      '✅ Análises ilimitadas\n✅ Relatórios PDF completos\n✅ Planos alimentares personalizados\n✅ Rede de parceiros expandida\n✅ Suporte prioritário';

  @override
  String get helpAppBarTitle => 'Ajuda e Documentação';

  @override
  String get helpPetModule => '🐾 Módulo Pet';

  @override
  String get helpPlantModule => '🌿 Módulo Plantas';

  @override
  String get helpFoodModule => '🍎 Módulo Alimentos';

  @override
  String get helpFaqSection => '❓ Perguntas Frequentes';

  @override
  String get helpSupportSection => '📞 Suporte';

  @override
  String get helpPetBreedTitle => 'Identificação de Raça';

  @override
  String get helpPetBreedDesc =>
      'Tire uma foto do seu pet e receba:\n• Identificação da raça\n• Perfil biológico completo\n• Recomendações de cuidados\n• Plano alimentar personalizado';

  @override
  String get helpPetWoundTitle => 'Análise de Feridas';

  @override
  String get helpPetWoundDesc =>
      'Triagem visual de lesões:\n• Descrição clínica detalhada\n• Possíveis causas\n• Nível de urgência (Verde/Amarelo/Vermelho)\n• Primeiros socorros\n⚠️ NÃO substitui consulta veterinária!';

  @override
  String get helpPetDossierTitle => 'Prontuário Completo';

  @override
  String get helpPetDossierDesc =>
      'Gerencie a saúde do seu pet:\n• Histórico de vacinas\n• Controle de peso\n• Exames laboratoriais (OCR)\n• Agenda de eventos\n• Rede de parceiros (vets, pet shops)';

  @override
  String get helpPlantIdTitle => 'Identificação Botânica';

  @override
  String get helpPlantIdDesc =>
      'Descubra tudo sobre plantas:\n• Nome científico e popular\n• Família botânica\n• Cuidados necessários (água, luz, solo)\n• Toxicidade para pets e crianças\n• Poderes biofílicos';

  @override
  String get helpFoodAnalysisTitle => 'Análise Nutricional';

  @override
  String get helpFoodAnalysisDesc =>
      'Informações nutricionais instantâneas:\n• Calorias, proteínas, carboidratos, gorduras\n• Comparação com metas diárias\n• Histórico de análises\n• Planejamento semanal';

  @override
  String get helpNeedSupportTitle => 'Precisa de Ajuda?';

  @override
  String get helpSupportDesc =>
      '📧 Email: abreuretto72@gmail.com\n🌐 GitHub: github.com/abreuretto72/ScanNut\n📱 Versão: 1.0.0';

  @override
  String get faqOfflineQ => 'O app funciona offline?';

  @override
  String get faqOfflineA =>
      'Não. O ScanNut precisa de internet para enviar as fotos para a IA do Google Gemini e receber as análises.';

  @override
  String get faqPhotosQ => 'Minhas fotos ficam salvas?';

  @override
  String get faqPhotosA =>
      'Não. As fotos são enviadas para análise e deletadas automaticamente após o processamento. Apenas os resultados são salvos no histórico.';

  @override
  String get faqDevicesQ => 'Posso usar em vários celulares?';

  @override
  String get faqDevicesA =>
      'No momento, o ScanNut salva os dados localmente no seu dispositivo.';

  @override
  String get faqWoundQ => 'A análise de feridas substitui o veterinário?';

  @override
  String get faqWoundA =>
      'NÃO! A análise é apenas uma triagem informativa. SEMPRE consulte um veterinário para diagnóstico e tratamento.';

  @override
  String get privacySecurityTitle => 'Segurança e Proteção de Dados';

  @override
  String get privacySecurityBody =>
      'O ScanNut prioriza a privacidade do usuário através de uma arquitetura de dados local. Utilizamos criptografia de nível militar (AES-256) para cifrar o banco de dados armazenado no seu dispositivo. As chaves de segurança são mantidas em ambiente isolado (Keystore/Keychain), garantindo que, mesmo em caso de perda do aparelho, os dados permaneçam inacessíveis sem as devidas credenciais ou chaves do sistema.\n\nO usuário está ciente de que, por não utilizarmos armazenamento em nuvem (Cloud), a manutenção e segurança dos arquivos de Backup Local exportados são de sua inteira responsabilidade.';

  @override
  String get helpMenuTitle => 'Cardápios e Lista de Compras';

  @override
  String get helpMenuGenTitle => '🗓️ Geração de Cardápios';

  @override
  String get helpMenuGenDesc =>
      'No ScanNut, você tem total controle sobre como e quando seu cardápio é gerado.\n\nVocê pode escolher entre três modos de geração:\n• Cardápio semanal — para 7 dias a partir da data escolhida\n• Cardápio mensal — para 30 dias consecutivos\n• Cardápio personalizado — escolha a data de início e a data de fim (até 60 dias)\n\nSempre que você gerar um cardápio, o app mostrará um filtro para que você possa confirmar ou ajustar suas escolhas antes da geração.';

  @override
  String get helpMenuHistTitle => '💾 Histórico de Cardápios';

  @override
  String get helpMenuHistDesc =>
      'Todos os cardápios gerados ficam salvos no histórico do app.\n\nIsso permite que você:\n• Consulte cardápios antigos\n• Gere novas versões sem perder as anteriores\n• Edite cardápios já criados\n• Exclua cardápios que não deseja mais manter\n\nNada é apagado automaticamente sem a sua confirmação.';

  @override
  String get helpMenuObjTitle => '🎯 Objetivos Nutricionais';

  @override
  String get helpMenuObjDesc =>
      'Ao gerar um cardápio, você pode escolher o objetivo nutricional, como:\n• Manter o peso\n• Emagrecimento\n• Alimentação equilibrada\n\nO objetivo influencia a escolha dos alimentos e a distribuição das calorias.';

  @override
  String get helpMenuPrefTitle => '🥗 Preferências Alimentares';

  @override
  String get helpMenuPrefDesc =>
      'Você também pode informar preferências alimentares, como:\n• Sem glúten\n• Sem lactose\n• Vegetariano\n\nEssas opções são opcionais. Se nenhuma for selecionada, o cardápio será gerado no formato padrão.';

  @override
  String get helpMenuEditTitle => '✏️ Edição de Ingredientes';

  @override
  String get helpMenuEditDesc =>
      'Após gerar um cardápio, você pode editar os ingredientes de qualquer dia.\n\nÉ possível:\n• Ajustar ingredientes\n• Alterar quantidades\n• Adicionar ou remover itens\n\nSempre que um ingrediente é alterado, as listas de compras são atualizadas automaticamente.';

  @override
  String get helpMenuShopTitle => '🛒 Lista de Compras Semanal';

  @override
  String get helpMenuShopDesc =>
      'O ScanNut gera listas de compras organizadas para facilitar sua ida ao mercado.\n\nImportante:\n• As listas de compras são sempre SEMANAIS\n• Mesmo em cardápios mensais ou personalizados\n• Os itens são consolidados (não se repetem)\n• A quantidade total a comprar é sempre exibida\n• A lista pode ser impressa em PDF com checkbox para marcar os itens';

  @override
  String get helpMenuPdfTitle => '📄 PDF do Cardápio';

  @override
  String get helpMenuPdfDesc =>
      'Ao gerar o PDF:\n• O cardápio é organizado por semanas\n• Cada semana possui sua própria lista de compras\n• Ideal para imprimir e usar no dia a dia';

  @override
  String get helpMenuTipTitle => 'ℹ️ Dica Importante';

  @override
  String get petTechnicalDetails => 'Detalhes Técnicos';

  @override
  String get petObservedSigns => 'Sinais Observados';

  @override
  String get petHomeCare => 'Cuidados em Casa';

  @override
  String get petVetCare => 'Cuidados Veterinários';

  @override
  String get petResult => 'Resultado';

  @override
  String get petNoRelevantChanges => 'Nenhuma alteração relevante detectada';

  @override
  String get commonNormal => 'Normal';

  @override
  String get commonModerate => 'Moderado';

  @override
  String get commonShare => 'Compartilhar';

  @override
  String get petResult_viewProfile => 'Ver Perfil do Pet';

  @override
  String get helpMenuTipDesc =>
      'Sempre revise o resumo antes de gerar um cardápio.\nAssim você garante que o período, o objetivo e as preferências estão corretos.';

  @override
  String get petAnalysisDisclaimer =>
      'Este conteúdo é gerado por IA e deve ser usado apenas como referência informativa. Não substitui o diagnóstico veterinário profissional.';

  @override
  String get petLabelUrgencyLevel => 'Nível de Urgência';

  @override
  String get petLabelConfidence => 'Confiabilidade';

  @override
  String get petLabelDiagnosis => 'Diagnóstico';

  @override
  String get petLabelVisualAspects => 'Aspectos Visuais';

  @override
  String get petLabelPossibleCauses => 'Causas Possíveis';

  @override
  String get petLabelRecommendations => 'Recomendações';

  @override
  String get petLabelBreed => 'Raça';

  @override
  String get petLabelSpecies => 'Espécie';

  @override
  String get petLabelColor => 'Cor';

  @override
  String get petLabelCoatType => 'Tipo de Pelo';

  @override
  String get petLabelSize => 'Porte';

  @override
  String get petLabelLifeExpectancy => 'Expectativa de Vida';

  @override
  String get petLabelOrigin => 'Origem';

  @override
  String get petLabelTemperament => 'Temperamento';

  @override
  String get petLabelPersonality => 'Personalidade';

  @override
  String get petLabelSocialBehavior => 'Comportamento Social';

  @override
  String get petLabelIdentification => 'Identificação';

  @override
  String get petLabelGrowthCurve => 'Curva de Crescimento';

  @override
  String get petLabelNutrition => 'Nutrição';

  @override
  String get petLabelGrooming => 'Higiene';

  @override
  String get petLabelHealth => 'Saúde';

  @override
  String get petLabelLifestyle => 'Estilo de Vida';

  @override
  String get petLabelBehavior => 'Comportamento';

  @override
  String get petMenuFilterTitle => 'Gerar Cardápio Pet';

  @override
  String get petMenuModeWeekly => 'Semanal (7 dias)';

  @override
  String get petMenuModeMonthly => 'Mensal (28 dias)';

  @override
  String get petMenuModeCustom => 'Personalizado';

  @override
  String get petMenuStartDate => 'Data de Início';

  @override
  String get petMenuEndDate => 'Data de Fim';

  @override
  String get petMenuGenerateBtn => 'Gerar Cardápio';

  @override
  String get petMenuDateRangeError => 'O período não pode exceder 60 dias.';

  @override
  String get petMenuSuccess => 'Cardápio gerado com sucesso!';

  @override
  String get petMenuShoppingList => 'Lista de Compras';

  @override
  String get petMenuShoppingListEmpty => 'Nenhum item na lista.';

  @override
  String get petTabGenerate => 'Gerar Cardápio';

  @override
  String get petTabHistory => 'Histórico';

  @override
  String get petMenuDeleteWeekConfirm => 'Excluir esta semana do histórico?';

  @override
  String get petMenuDeleteDayConfirm => 'Excluir o cardápio deste dia?';

  @override
  String get petMenuEditDayTitle => 'Editar Refeições do Dia';

  @override
  String petMenuGeneratePdfMulti(int count) {
    return 'Gerar PDF ($count semanas)';
  }

  @override
  String get petMenuSelectionClear => 'Limpar seleção';

  @override
  String get petMenuEmptyHistory =>
      'Nenhum histórico encontrado. Gere um cardápio para começar!';

  @override
  String get petMenuEditIngredientsHint =>
      'Edite os ingredientes ou descrição...';

  @override
  String get petMenuSaveSuccess => 'Alterações salvas com sucesso!';

  @override
  String get petMenuDeletedSuccess => 'Item excluído com sucesso!';

  @override
  String get petMenuPdfGenerated => 'PDF gerado com sucesso!';

  @override
  String get petViewMenu => 'Ver Cardápio';

  @override
  String get commonItem => 'Item';

  @override
  String get commonQuantity => 'Quantidade';

  @override
  String get commonCategory => 'Categoria';

  @override
  String get dietTypeLabel => 'Tipo de Dieta';

  @override
  String get petDietGeneral => 'Geral (Sem restrição)';

  @override
  String get dietRenal => 'Renal';

  @override
  String get dietHepatic => 'Hepática';

  @override
  String get dietGastrointestinal => 'Gastrointestinal';

  @override
  String get dietHypoallergenic => 'Hipoalergênica';

  @override
  String get dietObesity => 'Obesidade (Perda de peso)';

  @override
  String get dietDiabetes => 'Diabetes';

  @override
  String get dietCardiac => 'Cardíaca';

  @override
  String get dietUrinary => 'Urinária';

  @override
  String get dietMuscleGain => 'Ganho muscular';

  @override
  String get dietPediatric => 'Infantil';

  @override
  String get dietGrowth => 'Crescimento';

  @override
  String get dietOther => 'Outra';

  @override
  String get dietOtherHint => 'Especifique (máx 60 caracteres)';

  @override
  String get dietRequiredError => 'Selecione um tipo de dieta';

  @override
  String get dietOtherRequiredError => 'Especifique a dieta';

  @override
  String get petEvent_addTitle => 'Registrar Evento';

  @override
  String get petEvent_notes => 'Notas/Observações';

  @override
  String get petEvent_save => 'Salvar Evento';

  @override
  String get petEvent_cancel => 'Cancelar';

  @override
  String get petEvent_details => 'Detalhes Adicionais';

  @override
  String get petEvent_group_food => 'Alimentação';

  @override
  String get petEvent_group_health => 'Saúde';

  @override
  String get petEvent_group_elimination => 'Fezes/Urina';

  @override
  String get petEvent_group_grooming => 'Higiene';

  @override
  String get petEvent_group_activity => 'Atividade';

  @override
  String get petEvent_group_behavior => 'Comportamento';

  @override
  String get petEvent_group_schedule => 'Agenda';

  @override
  String get petEvent_group_media => 'Mídia';

  @override
  String get petEvent_group_metrics => 'Métricas';

  @override
  String get petEvent_group_medication => 'Medicação';

  @override
  String get petEvent_group_documents => 'Documentos';

  @override
  String get petEvent_group_exams => 'Exames';

  @override
  String get petEvent_group_allergies => 'Alergias';

  @override
  String get petEvent_group_dentistry => 'Odontologia';

  @override
  String get petEvent_group_other => 'Outros';

  @override
  String get petEvent_savedSuccess => 'Evento registrado ✅';

  @override
  String get petEvent_saveError => 'Não foi possível salvar. Tente novamente.';

  @override
  String get petEvent_attachError => 'Não foi possível anexar este arquivo.';

  @override
  String get petEvent_todayCount => 'Hoje';

  @override
  String get petEvent_historyTitle => 'Linha do Tempo';

  @override
  String get petEvent_includeInPdf => 'Incluir no Relatório PDF';

  @override
  String get petEvent_emptyHistory => 'Nenhum evento registrado ainda.';

  @override
  String get petEvent_group => 'Grupo';

  @override
  String get petEvent_type => 'Subtipo';

  @override
  String get petEvent_reportTitle => 'Relatório de Eventos do Pet';

  @override
  String get petEvent_generateReport => 'Gerar Relatório (PDF)';

  @override
  String get petEvent_reportCustom => 'Personalizado';

  @override
  String get petEvent_reportWeekly => 'Semanal';

  @override
  String get petEvent_reportMonthly => 'Mensal';

  @override
  String get petEvent_reportStartDate => 'Data Inicial';

  @override
  String get petEvent_reportEndDate => 'Data Final';

  @override
  String get petEvent_reportFilterGroup => 'Filtrar por Grupo';

  @override
  String get petEvent_reportIncludesOnlyPdf => 'Apenas marcados para PDF';

  @override
  String get petEvent_reportSuccess => 'PDF gerado e salvo em Downloads ✅';

  @override
  String get petEvent_reportError => 'Erro ao gerar PDF';

  @override
  String get petEvent_reportShare => 'Compartilhar Relatório';

  @override
  String get petEvent_reportSummary => 'Resumo do Período';

  @override
  String get petEvent_reportTotal => 'Total de Eventos';

  @override
  String get petEvent_reportPeriod => 'Período';

  @override
  String get lastUpdated => 'Atualizado em';

  @override
  String get petEdit => 'Editar Perfil';

  @override
  String get petDelete => 'Excluir Pet';

  @override
  String get petMenuGenerate => 'Gerar Cardápio';

  @override
  String get feedingEventGroupLabel => 'Grupo de Evento';

  @override
  String get feedingEventTypeLabel => 'Tipo de Ocorrência';

  @override
  String get feedingEventSeverityLabel => 'Gravidade';

  @override
  String get feedingEventAcceptanceLabel => 'Aceitação';

  @override
  String get feedingEventQuantityLabel => 'Quantidade Ingerida';

  @override
  String get feedingEventRelatedToMeal => 'Relacionado à Refeição';

  @override
  String get feedingGroup_normalFeeding => 'Alimentação Normal';

  @override
  String get feedingGroup_behavioralOccurrence => 'Ocorrência Comportamental';

  @override
  String get feedingGroup_digestiveIntercurrence => 'Intercorrência Digestiva';

  @override
  String get feedingGroup_intestinalIntercurrence =>
      'Intercorrência Intestinal';

  @override
  String get feedingGroup_nutritionalMetabolic => 'Nutricional/Metabólica';

  @override
  String get feedingGroup_therapeuticDiet => 'Dieta Terapêutica';

  @override
  String get feedingType_mealCompleted => 'Refeição realizada';

  @override
  String get feedingType_mealDelayed => 'Refeição atrasada';

  @override
  String get feedingType_mealSkipped => 'Refeição pulada';

  @override
  String get feedingType_foodChange => 'Troca de alimento';

  @override
  String get feedingType_reducedIntake => 'Redução da ingestão';

  @override
  String get feedingType_increasedAppetite => 'Aumento do apetite';

  @override
  String get feedingType_reluctantToEat => 'Relutância em comer';

  @override
  String get feedingType_eatsSlowly => 'Come devagar';

  @override
  String get feedingType_eatsTooFast => 'Come muito rápido';

  @override
  String get feedingType_selectiveEating => 'Seleciona alimento';

  @override
  String get feedingType_hidesFood => 'Esconde comida';

  @override
  String get feedingType_aggressiveWhileEating => 'Agressividade ao comer';

  @override
  String get feedingType_anxietyWhileEating => 'Ansiedade ao se alimentar';

  @override
  String get feedingType_vomitingImmediate => 'Vômito imediato';

  @override
  String get feedingType_vomitingDelayed => 'Vômito tardio';

  @override
  String get feedingType_nausea => 'Náusea';

  @override
  String get feedingType_choking => 'Engasgo';

  @override
  String get feedingType_regurgitation => 'Regurgitação';

  @override
  String get feedingType_excessiveFlatulence => 'Flatulência excessiva';

  @override
  String get feedingType_apparentAbdominalPain => 'Dor abdominal aparente';

  @override
  String get feedingType_diarrhea => 'Diarreia';

  @override
  String get feedingType_softStool => 'Fezes amolecidas';

  @override
  String get feedingType_constipation => 'Constipação';

  @override
  String get feedingType_stoolWithMucus => 'Fezes com muco';

  @override
  String get feedingType_stoolWithBlood => 'Fezes com sangue';

  @override
  String get feedingType_stoolColorChange => 'Alteração de cor das fezes';

  @override
  String get feedingType_abnormalStoolOdor => 'Odor fecal anormal';

  @override
  String get feedingType_weightGain => 'Ganho de peso';

  @override
  String get feedingType_weightLoss => 'Perda de peso';

  @override
  String get feedingType_excessiveThirst => 'Sede excessiva';

  @override
  String get feedingType_lowWaterIntake => 'Baixa ingestão de água';

  @override
  String get feedingType_suspectedFoodIntolerance =>
      'Suspeita de intolerância alimentar';

  @override
  String get feedingType_suspectedFoodAllergy =>
      'Suspeita de alergia alimentar';

  @override
  String get feedingType_adverseFoodReaction => 'Reação adversa ao alimento';

  @override
  String get feedingType_dietNotTolerated => 'Dieta não tolerada';

  @override
  String get feedingType_therapeuticDietRefusal =>
      'Recusa de dieta terapêutica';

  @override
  String get feedingType_clinicalImprovementWithDiet =>
      'Melhora clínica com dieta';

  @override
  String get feedingType_clinicalWorseningAfterMeal =>
      'Piora clínica após refeição';

  @override
  String get feedingType_needForDietAdjustment =>
      'Necessidade de ajuste de dieta';

  @override
  String get feedingType_feedingWithMedication =>
      'Alimentação associada a medicamento';

  @override
  String get feedingType_assistedFeeding =>
      'Alimentação assistida (seringa/sonda)';

  @override
  String get feedingSeverity_none => 'Sem gravidade';

  @override
  String get feedingSeverity_mild => 'Leve';

  @override
  String get feedingSeverity_moderate => 'Moderada';

  @override
  String get feedingSeverity_severe => 'Grave';

  @override
  String get feedingAcceptance_good => 'Boa';

  @override
  String get feedingAcceptance_partial => 'Parcial';

  @override
  String get feedingAcceptance_refused => 'Recusou';

  @override
  String get feedingClinicalIntercurrence => 'Intercorrência Clínica';

  @override
  String get feedingMarkAsClinical => 'Marcar como intercorrência clínica';

  @override
  String get feedingClinicalAlert =>
      '⚠️ Este evento será destacado no PDF como intercorrência clínica';

  @override
  String get healthEventTitle => 'Registrar Saúde';

  @override
  String get healthEventSelectType => 'Selecione o tipo de ocorrência';

  @override
  String get healthEventSeverityLabel => 'Gravidade';

  @override
  String get healthEventEmergencyToggle => 'Marcar como emergência';

  @override
  String get healthEventEmergencyAlert =>
      '🚨 Se o pet estiver em risco, procure atendimento veterinário imediatamente.';

  @override
  String get healthEventDetailsHint => 'Registrar a ocorrência em detalhes';

  @override
  String get healthEventSpeechToText => 'Usar voz para registrar';

  @override
  String get healthEventListening => 'Ouvindo...';

  @override
  String get healthEventSpeechError =>
      'Erro ao reconhecer voz. Tente novamente.';

  @override
  String get health_group_daily_monitoring => 'Monitoramento Diário';

  @override
  String get health_group_acute_symptoms => 'Sintomas Agudos';

  @override
  String get health_group_infectious => 'Infeccioso/Parasitário';

  @override
  String get health_group_dermatological => 'Dermatológico';

  @override
  String get health_group_mobility => 'Mobilidade/Ortopédico';

  @override
  String get health_group_neurological => 'Neurológico/Sensorial';

  @override
  String get health_group_treatment => 'Tratamento/Procedimento';

  @override
  String get health_type_temperature_check => 'Verificação de Temperatura';

  @override
  String get health_type_weight_check => 'Verificação de Peso';

  @override
  String get health_type_appetite_monitoring => 'Monitoramento de Apetite';

  @override
  String get health_type_hydration_check => 'Verificação de Hidratação';

  @override
  String get health_type_energy_level => 'Nível de Energia';

  @override
  String get health_type_behavior_observation => 'Observação de Comportamento';

  @override
  String get health_type_fever => 'Febre';

  @override
  String get health_type_vomiting => 'Vômito';

  @override
  String get health_type_diarrhea => 'Diarreia';

  @override
  String get health_type_lethargy => 'Letargia';

  @override
  String get health_type_loss_of_appetite => 'Perda de Apetite';

  @override
  String get health_type_excessive_thirst => 'Sede Excessiva';

  @override
  String get health_type_difficulty_breathing => 'Dificuldade Respiratória';

  @override
  String get health_type_coughing => 'Tosse';

  @override
  String get health_type_sneezing => 'Espirros';

  @override
  String get health_type_nasal_discharge => 'Secreção Nasal';

  @override
  String get health_type_suspected_infection => 'Suspeita de Infecção';

  @override
  String get health_type_wound_infection => 'Infecção em Ferida';

  @override
  String get health_type_ear_infection => 'Infecção de Ouvido';

  @override
  String get health_type_eye_infection => 'Infecção Ocular';

  @override
  String get health_type_urinary_infection => 'Infecção Urinária';

  @override
  String get health_type_parasite_detected => 'Parasita Detectado';

  @override
  String get health_type_tick_found => 'Carrapato Encontrado';

  @override
  String get health_type_flea_infestation => 'Infestação de Pulgas';

  @override
  String get health_type_skin_rash => 'Erupção Cutânea';

  @override
  String get health_type_itching => 'Coceira';

  @override
  String get health_type_hair_loss => 'Queda de Pelo';

  @override
  String get health_type_hot_spot => 'Hot Spot';

  @override
  String get health_type_wound => 'Ferida';

  @override
  String get health_type_abscess => 'Abscesso';

  @override
  String get health_type_allergic_reaction => 'Reação Alérgica';

  @override
  String get health_type_swelling => 'Inchaço';

  @override
  String get health_type_limping => 'Manqueira';

  @override
  String get health_type_joint_pain => 'Dor Articular';

  @override
  String get health_type_difficulty_walking => 'Dificuldade para Andar';

  @override
  String get health_type_stiffness => 'Rigidez';

  @override
  String get health_type_muscle_weakness => 'Fraqueza Muscular';

  @override
  String get health_type_fall => 'Queda';

  @override
  String get health_type_fracture_suspected => 'Suspeita de Fratura';

  @override
  String get health_type_seizure => 'Convulsão';

  @override
  String get health_type_tremors => 'Tremores';

  @override
  String get health_type_disorientation => 'Desorientação';

  @override
  String get health_type_loss_of_balance => 'Perda de Equilíbrio';

  @override
  String get health_type_vision_problems => 'Problemas de Visão';

  @override
  String get health_type_hearing_problems => 'Problemas de Audição';

  @override
  String get health_type_head_tilt => 'Inclinação da Cabeça';

  @override
  String get health_type_medication_administered => 'Medicamento Administrado';

  @override
  String get health_type_vaccine_given => 'Vacina Aplicada';

  @override
  String get health_type_wound_cleaning => 'Limpeza de Ferida';

  @override
  String get health_type_bandage_change => 'Troca de Curativo';

  @override
  String get health_type_vet_visit => 'Consulta Veterinária';

  @override
  String get health_type_surgery => 'Cirurgia';

  @override
  String get health_type_emergency_care => 'Atendimento de Emergência';

  @override
  String get health_type_hospitalization => 'Internação';

  @override
  String get petActionAgenda => 'Ocorrência';

  @override
  String get petActionMenu => 'Cardápio';

  @override
  String get petAgendaTitle => 'Agenda do Pet';

  @override
  String get foodHelpTitle => 'Exemplos de Ocorrências';

  @override
  String get foodHelpRoutine =>
      '• Rotina: Alimentação normal, recusa ou aumento de apetite';

  @override
  String get foodHelpAcute =>
      '• Agudo: Vômito pós-refeição, engasgo ou dificuldade';

  @override
  String get foodHelpDietChange =>
      '• Dieta: Troca de ração, início de AN ou ingestão indevida';

  @override
  String get foodHelpSupplements => '• Suplementos: Vitaminas ou probióticos';

  @override
  String get foodHelpHydration =>
      '• Hidratação: Consumo excessivo ou recusa de água';

  @override
  String get petAttachmentAnalyzeTitle => 'Análise Inteligente';

  @override
  String get petAttachmentAnalyzeQuestion => 'Como deseja analisar este anexo?';

  @override
  String get petAttachmentOptionPhoto => 'Analisar Foto (Visual)';

  @override
  String get petAttachmentOptionOCR => 'Ler Documento (OCR)';

  @override
  String get petAttachmentAnalyzeButton => 'Analisar';

  @override
  String get petAttachmentAnalysing => 'C.Ai analisando...';

  @override
  String get petAttachmentAnalysisSuccess => 'Análise concluída!';

  @override
  String get petAttachmentAnalysisError => 'Falha na análise.';

  @override
  String get petAnalysisViewResult => 'Ver Análise IA';

  @override
  String get petAttachmentNameTitle => 'Nomear Anexo';

  @override
  String get petAttachmentNameHint => 'Ex: Exame, Receita...';

  @override
  String get analysis_title => 'Resultado da Análise IA';

  @override
  String get btn_close => 'Entendi';

  @override
  String get petEvent_errorRequired => 'Por favor, descreva a ocorrência.';

  @override
  String get petProfile_breed => 'Raça';

  @override
  String get petProfile_breedHint => 'Ex: Labrador/SRD';

  @override
  String get petProfile_reproductiveStatus => 'Status Reprodutivo';

  @override
  String get petProfile_neutered => 'Castrado';

  @override
  String get petProfile_intact => 'Não Castrado (Inteiro)';

  @override
  String get petProfile_errorBreed => 'Informe a raça.';

  @override
  String get petProfile_errorReproductive => 'Informe o status reprodutivo.';

  @override
  String get petProfile_errorGender => 'Selecione o sexo.';

  @override
  String get gender_male => 'Macho';

  @override
  String get gender_female => 'Fêmea';

  @override
  String get gender_required => 'Selecione o sexo do pet';

  @override
  String get breed_required => 'Informe a raça';

  @override
  String get petProfile_male => 'Macho';

  @override
  String get petProfile_female => 'Fêmea';

  @override
  String get showEvents => 'Mostrar Eventos';

  @override
  String petMenuCalculating(String name) {
    return 'Calculando a melhor dieta para $name...';
  }

  @override
  String get petMenuIncompleteTitle => 'Perfil Incompleto';

  @override
  String get petMenuIncompleteProfile =>
      'Dados incompletos. Por favor, preencha o perfil do pet (Peso, Idade, Sexo, Status Reprodutivo) para garantir uma dieta segura.';

  @override
  String get commonRequired => 'Campo obrigatório';

  @override
  String get detecting_pet => 'Identificando seu pet...';

  @override
  String get auto_fill_success => 'Campos preenchidos automaticamente!';

  @override
  String is_pet_breed_correct(Object breed) {
    return 'Identificamos que seu pet é um $breed. Isso está correto?';
  }

  @override
  String get species_label => 'Espécie';

  @override
  String get species_dog => 'Cão';

  @override
  String get species_cat => 'Gato';

  @override
  String get petMenuSpeciesRequired =>
      'Selecione se o seu pet é um cão ou gato para continuar.';

  @override
  String get missing_species_alert =>
      'Selecione se o seu pet é um cão ou gato para continuar.';

  @override
  String get reliability_label => 'Confiança da Análise';

  @override
  String get activitySedentary => 'Sedentário';

  @override
  String get activityModerate => 'Moderado';

  @override
  String get activityActive => 'Ativo';

  @override
  String get activityVeryActive => 'Muito Ativo';

  @override
  String get bathFrequencyWeekly => 'Semanal';

  @override
  String get bathFrequencyBiweekly => 'Quinzenal';

  @override
  String get bathFrequencyMonthly => 'Mensal';

  @override
  String get bathFrequencyAsNeeded => 'Sob Demanda';

  @override
  String get reproductiveNeutered => 'Castrado';

  @override
  String get reproductiveIntact => 'Inteiro';

  @override
  String get reproductiveNursing => 'Gesta/Lactante';

  @override
  String get petFoodRestrictions => 'Restrições Alimentares';

  @override
  String get petFoodRestrictionsDesc =>
      'Ingredientes proibidos ou a evitar (ex: sem frango, sem glúten).';

  @override
  String get petAddRestriction => 'Adicionar restrição';

  @override
  String get petDossierTitle => 'Análise Veterinária 360°';

  @override
  String get petDossierDisclaimer =>
      'Conteúdo gerado por IA. Use como referência. Não substitui avaliação veterinária.';

  @override
  String get petDossierAnalyzedImage => 'Imagem Analisada';

  @override
  String get petDossierViewFull => 'Expandir';

  @override
  String get petDossierSignals => 'Sinais';

  @override
  String get petDossierRisk => 'Risco';

  @override
  String get petDossierPrecision => 'Precisão';

  @override
  String get petDossierStatus => 'Status';

  @override
  String get petSectionIdentity => 'Identificação Visual';

  @override
  String get petSectionPreventive => 'Saúde Preventiva';

  @override
  String get petSectionGrowth => 'Curva de Crescimento';

  @override
  String get petActionViewProfile => 'Ver Perfil do Pet';

  @override
  String get petActionSharePDF => 'Compartilhar PDF';

  @override
  String petIndexing_aiTitle(Object type) {
    return 'Análise de IA: $type';
  }

  @override
  String get petIndexing_aiNotes =>
      'Análise clínica gerada por Inteligência Artificial.';

  @override
  String petIndexing_occurrenceTitle(Object title) {
    return 'Ocorrência: $title';
  }

  @override
  String petIndexing_agendaTitle(Object attendant, Object pet) {
    return '$attendant + $pet';
  }

  @override
  String petIndexing_partnerFavorited(Object name) {
    return 'Parceiro Favoritado: $name';
  }

  @override
  String petIndexing_partnerScheduled(Object name) {
    return 'Interação agendada com $name';
  }

  @override
  String petIndexing_partnerContacted(Object name) {
    return 'Contato via WhatsApp/GPS: $name';
  }

  @override
  String petIndexing_partnerLinked(Object name) {
    return 'Parceiro vinculado ao perfil: $name';
  }

  @override
  String get petIndexing_partnerInteractionNotes =>
      'Interação registrada via Radar Geo.';

  @override
  String petIndexing_vaultTitle(Object name) {
    return 'Arquivo: $name';
  }

  @override
  String get petIndexing_vaultNotes => 'Documento indexado no Media Vault.';

  @override
  String get petEvent_tapToViewDetails => 'Toque para ver detalhes';

  @override
  String petIndexing_taskCompleted(Object task) {
    return 'Tarefa concluída: $task';
  }

  @override
  String get agendaLoadError => 'Erro ao carregar a agenda. Tente novamente.';

  @override
  String get pdfPrecision => 'Precisão';

  @override
  String get soundAnalysisTitle => 'Análise Vocal';

  @override
  String get soundAnalysisDesc =>
      'Identifique emoções e necessidades através do latido ou miado.';

  @override
  String get soundRecording => 'Gravando...';

  @override
  String get soundProcessing => 'Analisando...';

  @override
  String get soundStartRecord => 'Toque para gravar';

  @override
  String get soundResultType => 'Tipo';

  @override
  String get soundResultEmotion => 'Emoção';

  @override
  String get soundResultAction => 'Recomendação';

  @override
  String get soundError => 'Erro ao analisar';

  @override
  String get soundEmotionSimple => 'O que ele sente';

  @override
  String get soundReasonSimple => 'Motivo provável';

  @override
  String get soundActionTip => 'Dica rápida';

  @override
  String get soundUploadBtn => 'Enviar Áudio';

  @override
  String get petFoodCardTitle => 'Análise de Rótulo';

  @override
  String get petFoodVerdict => 'Veredito';

  @override
  String get petFoodReason => 'Motivo';

  @override
  String get petFoodTip => 'Dica Diária';

  @override
  String get petFoodStart => 'Analisar Rótulo';

  @override
  String get petFoodError => 'Erro na leitura';

  @override
  String get plansTabTitle => 'Planos';

  @override
  String get plansTabSubtitle =>
      'Informações sobre planos, seguros e assistência de saúde do seu pet.';

  @override
  String get healthPlanToggle => 'Possui plano de saúde veterinária?';

  @override
  String get healthPlanOperator => 'Nome do plano / operadora';

  @override
  String get healthPlanCoverage => 'O que o plano cobre?';

  @override
  String get healthPlanType => 'Tipo de atendimento';

  @override
  String get healthPlanNetwork => 'Rede credenciada';

  @override
  String get healthPlanReimbursement => 'Reembolso';

  @override
  String get healthPlanValue => 'Valor mensal do plano (opcional)';

  @override
  String get healthPlanConsultations => 'Consultas';

  @override
  String get healthPlanExams => 'Exames';

  @override
  String get healthPlanSurgeries => 'Cirurgias';

  @override
  String get healthPlanEmergencies => 'Emergências';

  @override
  String get healthPlanHospitalization => 'Internação';

  @override
  String get healthPlanVaccines => 'Vacinas';

  @override
  String get healthPlanHelpText =>
      'Ajuda a reduzir custos com consultas, exames e emergências veterinárias.';

  @override
  String get assistancePlanToggle =>
      'Possui plano de assistência ou reembolso?';

  @override
  String get assistancePlanOperator => 'Nome da empresa / plano';

  @override
  String get assistancePlanReimbursementType => 'Tipo de reembolso';

  @override
  String get assistancePlanTotal => 'Total';

  @override
  String get assistancePlanPartial => 'Parcial';

  @override
  String get assistancePlanMaxValue =>
      'Valor máximo de reembolso (mensal ou anual)';

  @override
  String get assistancePlanNeedsInvoice => 'Exige nota fiscal para reembolso?';

  @override
  String get assistancePlanHelpText =>
      'Ideal para quem utiliza o veterinário de confiança e solicita reembolso posteriormente.';

  @override
  String get funeralPlanToggle => 'Possui plano funerário para pet?';

  @override
  String get funeralPlanOperator => 'Empresa / plano funerário';

  @override
  String get funeralPlanServices => 'Serviços incluídos';

  @override
  String get funeralPlanWake => 'Velório';

  @override
  String get funeralPlanIndivCremation => 'Cremação individual';

  @override
  String get funeralPlanCollCremation => 'Cremação coletiva';

  @override
  String get funeralPlanTransport => 'Traslado';

  @override
  String get funeralPlanMemorial => 'Urna ou memorial';

  @override
  String get funeralPlan24h => 'Atendimento 24h?';

  @override
  String get funeralPlanEmergencyContact => 'Contato de emergência';

  @override
  String get funeralPlanHelpText =>
      'Garante organização e apoio em momentos delicados.';

  @override
  String get lifeInsurancePlanToggle => 'Possui seguro de vida para o pet?';

  @override
  String get lifeInsuranceInsurer => 'Seguradora';

  @override
  String get lifeInsuranceInsuredValue => 'Valor segurado';

  @override
  String get lifeInsuranceCoverages => 'Coberturas incluídas';

  @override
  String get lifeInsuranceDeath => 'Falecimento';

  @override
  String get lifeInsuranceGraveIllness => 'Doença grave';

  @override
  String get lifeInsuranceEuthanasia =>
      'Eutanásia (quando indicada por veterinário)';

  @override
  String get lifeInsuranceEconomicValue =>
      'Pet possui valor econômico especial? (ex: competição)';

  @override
  String get lifeInsuranceHelpText =>
      'Indicado para pets com valor econômico ou funcional elevado.';

  @override
  String get planTitleHealth => 'Saúde do Pet';

  @override
  String get planTitleAssistance => 'Assistência / Reembolso';

  @override
  String get planTitleFuneral => 'Plano Funerário';

  @override
  String get planTitleLife => 'Seguro de Vida';

  @override
  String get planObservations => 'Observações';

  @override
  String get petBodyAnalysisTitle => 'Analise Corporal & Postural';

  @override
  String get petBodyAnalysisDesc =>
      'Avalie o bem-estar fisico e sinais de dor atraves da postura.';

  @override
  String get petBodyHealthScore => 'Nivel de Bem-Estar';

  @override
  String get petBodySignals => 'Sinais Observados';

  @override
  String get petBodyAdvice => 'Dica de Cuidado';

  @override
  String get petBodyRelaxed => 'Relaxado & Saudavel';

  @override
  String get petBodyDiscomfort => 'Sinais de Desconforto';

  @override
  String get petBodyPain => 'Sinais de Dor ou Estresse';

  @override
  String get petBodyProcessing => 'Lendo Linguagem Corporal...';

  @override
  String get petBodyError => 'Falha na analise postural';

  @override
  String get petBodyDeleteConfirm => 'Excluir esta analise corporal?';
}

/// The translations for Portuguese, as used in Portugal (`pt_PT`).
class AppLocalizationsPtPt extends AppLocalizationsPt {
  AppLocalizationsPtPt() : super('pt_PT');

  @override
  String get appTitle => 'ScanNut';

  @override
  String get splashPoweredBy => 'Tecnologia AI Vision';

  @override
  String get tabFood => 'Alimentação';

  @override
  String get tabPlants => 'Plantas';

  @override
  String get tabPets => 'Animais';

  @override
  String get disclaimerTitle => 'Aviso Importante';

  @override
  String get disclaimerBody =>
      'Esta aplicação realiza apenas triagem informativa e NÃO substitui o conselho profissional de Nutricionistas, Agrónomos ou Veterinários.';

  @override
  String get disclaimerButton => 'Entendi';

  @override
  String get emergencyCall => 'Ligar Veterinário Próximo';

  @override
  String get cameraPermission =>
      'A permissão da câmara é necessária para usar este recurso.';

  @override
  String get petNamePromptTitle => 'Nome do Animal';

  @override
  String get petNamePromptHint => 'Introduza o nome do seu animal';

  @override
  String get petNamePromptCancel => 'Cancelar';

  @override
  String get petNameEmptyError =>
      'Nome do animal não fornecido. Modo animal cancelado.';

  @override
  String get settingsTitle => 'Definições';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsProfile => 'Perfil';

  @override
  String get settingsNutrition => 'Metas Nutricionais Humanas';

  @override
  String get settingsDangerZone => 'Zona de Perigo';

  @override
  String get pdfReportTitle => 'PRONTUÁRIO VETERINÁRIO COMPLETO';

  @override
  String get pdfGeneratedOn => 'Gerado a';

  @override
  String get pdfIdentitySection => 'Identidade e Perfil Biológico';

  @override
  String get pdfHealthSection => 'Saúde e Histórico Clínico';

  @override
  String get pdfNutritionSection => 'Nutrição e Plano Alimentar';

  @override
  String get pdfGallerySection => 'Galeria e Documentos';

  @override
  String get pdfParcSection => 'Rede de Apoio e Comportamento';

  @override
  String get pdfDisclaimerTitle => 'AVISO LEGAL IMPORTANTE';

  @override
  String get pdfDisclaimerBody =>
      'Este relatório é uma ferramenta de apoio. NÃO substitui consultas veterinárias.';

  @override
  String get termScreen => 'Ecrã';

  @override
  String get termMobile => 'Telemóvel';

  @override
  String get termFood => 'Comida';

  @override
  String get breedMixed => 'Raça Indefinida / Rafeiro';

  @override
  String get porteSmall => 'Pequeno';

  @override
  String get porteMedium => 'Médio';

  @override
  String get porteLarge => 'Grande';

  @override
  String get porteGiant => 'Gigante';

  @override
  String get weightStatusUnderweight => 'Abaixo do peso ideal';

  @override
  String get weightStatusOverweight => 'Acima do peso ideal';

  @override
  String get weightStatusNormal => 'Peso Normal';

  @override
  String get weightRecUnderweight =>
      'Considere consultar o veterinário para avaliar a nutrição e saúde geral do animal.';

  @override
  String get weightRecOverweight =>
      'Agende uma consulta com o veterinário no separador \'Parc.\' para ajustar a dieta e exercícios.';

  @override
  String get weightRecNormal =>
      'Continue com os cuidados atuais! Mantenha a rotina de alimentação e exercícios.';

  @override
  String get termSeverity => 'Gravidade';

  @override
  String get termDiagnosis => 'Diagnóstico';

  @override
  String get termRecommendations => 'Recomendações';

  @override
  String get tabIdentity => 'IDENTIDADE';

  @override
  String get tabNutrition => 'NUTRIÇÃO';

  @override
  String get tabGrooming => 'GROOMING';

  @override
  String get tabHealth => 'SAÚDE';

  @override
  String get tabLifestyle => 'LIFESTYLE';

  @override
  String get emptyPastWeek => 'Nenhum histórico recente.';

  @override
  String get emptyCurrentWeek => 'Nenhum cardápio para esta semana.';

  @override
  String get emptyNextWeek => 'Nenhum planeamento futuro.';

  @override
  String get tabPastWeek => 'Semana Passada';

  @override
  String get tabCurrentWeek => 'Semana Atual';

  @override
  String get tabNextWeek => 'Próxima Semana';

  @override
  String get menuPlanTitle => 'Planeamento de Menu Inteligente';

  @override
  String get menuPeriod => 'Período do Menu';

  @override
  String get dietType => 'Regime Alimentar';

  @override
  String get dietNatural => 'Alimentação Natural';

  @override
  String get dietKibble => 'Comida Comercial';

  @override
  String get dietHybrid => 'Modo Híbrido Ativado';

  @override
  String get nutritionalGoal => 'Meta Nutricional';

  @override
  String get generateMenu => 'Gerar Menu';

  @override
  String get selectDates => 'Selecionar Datas';

  @override
  String get cancel => 'Cancelar';

  @override
  String get permissionCameraDisclosureTitle => 'Uso da Câmara';

  @override
  String get permissionCameraDisclosureBody =>
      'A ScanNut precisa de aceder à sua câmara para analisar a saúde da pele, pelo e olhos do seu animal, e para permitir o registo de documentos veterinários.';

  @override
  String get permissionMicrophoneDisclosureTitle => 'Uso do Microfone';

  @override
  String get permissionMicrophoneDisclosureBody =>
      'A ScanNut solicita acesso ao microfone para permitir que faça anotações por voz sobre as observações do seu animal.';

  @override
  String get continueButton => 'Continuar';

  @override
  String get deleteAccount => 'Eliminar Conta e Dados';

  @override
  String get deleteAccountConfirmTitle => 'Eliminar permanentemente?';

  @override
  String get deleteAccountConfirmBody =>
      'Esta ação removerá todos os seus animais, fotos, históricos e dados do nosso sistema de forma irreversível. Deseja continuar?';

  @override
  String get deleteAccountButton => 'Eliminar Tudo';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get aiDisclaimer =>
      'Esta análise é informativa e baseada em IA. Não substitui o diagnóstico de um médico veterinário.';

  @override
  String get onboardingTitle1 => 'Transforme a sua Nutrição';

  @override
  String get onboardingBody1 =>
      'Utilize a nossa IA para analisar alimentos em segundos. Descubra calorias, macronutrientes e receba dicas de biohacking e receitas rápidas de 15 minutos para a sua alta performance.';

  @override
  String get onboardingTitle2 => 'Domine o seu Ecossistema';

  @override
  String get onboardingBody2 =>
      'Identifique plantas, diagnostique doenças e aprenda sobre propagação. Saiba instantaneamente se uma planta é segura para humanos através do nosso Semáforo de Sobrevivência.';

  @override
  String get onboardingTitle3 => 'O Prontuário Clínico Definitivo';

  @override
  String get onboardingBody3 =>
      'Acompanhe a saúde do seu animal com análise de pele por IA, histórico de vacinas e exames laboratoriais explicados. Tudo organizado e pronto para exportar em PDF para o seu veterinário.';

  @override
  String get onboardingTitle4 => 'Os seus dados são seus';

  @override
  String get onboardingBody4 =>
      'No ScanNut, a sua privacidade é prioridade. Todos os seus registos são guardados localmente no seu telemóvel (Hive) e não em nuvens externas.';

  @override
  String get onboardingAcceptTerms =>
      'Li e aceito os Termos de Uso e Política de Privacidade da Multiverso Digital';

  @override
  String get onboardingGetStarted => 'Começar';

  @override
  String get analysisErrorAiFailure =>
      'Todas as IAs falharam em analisar a imagem.';

  @override
  String get analysisErrorJsonFormat => 'Erro ao processar dados da IA.';

  @override
  String get analysisErrorUnexpected => 'Erro inesperado. Tente novamente.';

  @override
  String get loadingFood => 'Analisando alimento...';

  @override
  String get loadingPlant => 'Diagnosticando planta...';

  @override
  String get loadingPetBreed => 'Identificando raça...';

  @override
  String get loadingPetHealth => 'Analisando saúde...';

  @override
  String get nutrientsAdvancedMacros => 'Macronutrientes Avançados';

  @override
  String get nutrientsProteins => 'Proteínas';

  @override
  String get nutrientsCarbs => 'Carboidratos';

  @override
  String get nutrientsFats => 'Gorduras';

  @override
  String get nutrientsMinerals => 'Minerais e Vitaminas';

  @override
  String get nutrientsSynergy => 'Sinergia';

  @override
  String get recipesQuick => 'Receitas Rápidas (até 15 min)';

  @override
  String get recipesCulinaryIntel => 'Inteligência Culinária';

  @override
  String get recipesExpertTip => 'Dica do Especialista';

  @override
  String get labelGlycemicImpact => 'Impacto Glicêmico';

  @override
  String get labelFattyAcids => 'Ácidos Graxos';

  @override
  String get labelAminoProfile => 'Perfil de Aminoácidos';

  @override
  String get foodSafetyBio => 'Segurança & Bioquímica';

  @override
  String get foodIdealMoment => 'Momento Ideal';

  @override
  String get foodCriticalAlerts => 'Alertas Críticos';

  @override
  String get foodBioChem => 'Bioquímica e Neutralização';

  @override
  String get foodPreservation => 'Preservação';

  @override
  String get foodSmartSwap => 'Smart Swap (Troca)';

  @override
  String get foodDisclaimer =>
      'Nota: As informações nutricionais são estimadas. Consulte sempre um profissional de saúde.';

  @override
  String get foodVerdict => 'Veredito da IA';

  @override
  String get foodPros => 'Pontos Positivos';

  @override
  String get foodCons => 'Pontos de Atenção';

  @override
  String get foodBiohacking => 'Performance Biohacking';

  @override
  String get foodSatietyIndex => 'Índice de Saciedade';

  @override
  String get foodBodyBenefits => 'Benefícios para o Corpo';

  @override
  String get foodAttention => 'Atenção';

  @override
  String get foodFocusEnergy => 'Foco e Energia';

  @override
  String get paywallTitle => 'Desbloqueie o Poder Total';

  @override
  String get paywallSubtitle =>
      'Obtenha acesso ilimitado a todas as ferramentas de IA e análises detalhadas.';

  @override
  String get paywallSubscribeButton => 'Subscrever Agora';

  @override
  String get paywallSelectPlan => 'Selecione um plano';

  @override
  String get paywallRestore => 'Restaurar Compras';

  @override
  String get paywallTerms => 'Termos';

  @override
  String get paywallMonthly => 'Mensal';

  @override
  String get paywallYearly => 'Anual';

  @override
  String get paywallBestValue => 'MELHOR VALOR';

  @override
  String get paywallSuccess =>
      'Subscrição ativada com sucesso! Bem-vindo ao Pro! 🚀';

  @override
  String get paywallError => 'A compra não foi concluída. Tente novamente.';

  @override
  String get paywallRestoreSuccess => 'Compras restauradas com sucesso!';

  @override
  String get paywallRestoreFail =>
      'Nenhuma subscrição ativa encontrada para restaurar.';

  @override
  String get paywallLoadingOfferings =>
      'Não foi possível carregar as ofertas no momento.';

  @override
  String get drawerProTitle => 'ScanNut Pro';

  @override
  String get drawerProSubtitle => 'Desbloqueie tudo';

  @override
  String get settingsNameLabel => 'Nome';

  @override
  String get settingsNameHint => 'Como gostaria de ser tratado?';

  @override
  String get settingsWeightUnit => 'Unidade de Peso';

  @override
  String get settingsKg => 'Quilogramas (kg)';

  @override
  String get settingsLbs => 'Libras (lbs)';

  @override
  String get settingsPreferences => 'Preferências';

  @override
  String get settingsShowTips => 'Mostrar Dicas';

  @override
  String get settingsShowTipsSubtitle =>
      'Exibir dicas nutricionais nas análises';

  @override
  String get settingsPartnerManagement => 'Gestão de Parceiros';

  @override
  String get settingsSearchRadius => 'Raio de Pesquisa Padrão';

  @override
  String get settingsSearchRadiusSubtitle =>
      'Sugere parceiros próximos do seu animal baseando-se neste limite.';

  @override
  String get settingsSystemMaintenance => 'Manutenção do Sistema';

  @override
  String get settingsBackupOptimize => 'Gerar Backup e Otimizar';

  @override
  String get settingsBackupOptimizeSubtitle =>
      'Gera PDF completo e liberta espaço antigo.';

  @override
  String get settingsDeletePets => 'Eliminar Histórico de Animais';

  @override
  String get settingsDeletePetsSubtitle =>
      'Apagar todos os animais guardados permanentemente.';

  @override
  String get settingsDeletePlants => 'Eliminar Histórico de Plantas';

  @override
  String get settingsDeletePlantsSubtitle =>
      'Apagar todas as plantas guardadas permanentemente.';

  @override
  String get settingsDeleteFood => 'Eliminar Histórico de Alimentos';

  @override
  String get settingsDeleteFoodSubtitle =>
      'Apagar todos os alimentos guardados permanentemente.';

  @override
  String get settingsClearPartners => 'Limpar Rede de Apoio';

  @override
  String get settingsClearPartnersSubtitle =>
      'Remover todos os parceiros registados permanentemente.';

  @override
  String get settingsResetDefaults => 'Restaurar Predefinições';

  @override
  String get settingsResetDialogTitle => 'Restaurar Predefinições';

  @override
  String get settingsResetDialogContent =>
      'Tem a certeza que deseja restaurar todas as definições para os valores padrão?';

  @override
  String get settingsResetSuccess => 'Definições restauradas';

  @override
  String get settingsAutoSaveInfo =>
      'As suas definições são guardadas automaticamente';

  @override
  String get settingsConfirmDeleteTitle => 'Confirmar Eliminação';

  @override
  String settingsConfirmDeleteContent(Object itemType) {
    return 'Tem a certeza que deseja apagar permanentemente todo o histórico de $itemType? Essa ação não pode ser desfeita.';
  }

  @override
  String settingsDeleteSuccess(Object itemType) {
    return 'Histórico de $itemType apagado com sucesso.';
  }

  @override
  String get modePetIdentification => 'Raça e ID';

  @override
  String get modePetHealth => 'Saúde';

  @override
  String get instructionPetBody =>
      'Aponte a câmara para o corpo inteiro do seu animal';

  @override
  String get instructionPetWound =>
      'Aponte a câmara para a ferida do seu animal';

  @override
  String get tooltipNutritionHistory => 'Histórico Alimentar';

  @override
  String get tooltipNutritionManagement => 'Gestão da Nutrição';

  @override
  String get tooltipBotanyHistory => 'Histórico Botânico';

  @override
  String get exitDialogTitle => 'Sair da Aplicação';

  @override
  String get exitDialogContent => 'Deseja realmente sair da ScanNut?';

  @override
  String get exit => 'Sair';

  @override
  String get redirectShop => 'A redirecionar para loja parceira...';

  @override
  String get cameraError => 'Erro ao iniciar câmara: ';

  @override
  String petSavedSuccess(Object petName) {
    return 'Dossiê do $petName guardado/atualizado com sucesso!';
  }

  @override
  String savedSuccess(Object type) {
    return '$type guardado nas boxes especializadas!';
  }

  @override
  String get errorPetNameNotFound => 'Erro: Nome do animal não encontrado.';

  @override
  String healthAnalysisSaved(String petName) {
    return 'Análise guardada no histórico de saúde de $petName';
  }

  @override
  String errorSavingAnalysis(String error) {
    return 'Erro ao guardar análise: $error';
  }

  @override
  String get menuHello => 'Olá!';

  @override
  String menuHelloUser(Object userName) {
    return 'Olá, $userName!';
  }

  @override
  String get menuAiAssistant => 'Assistente IA ScanNut';

  @override
  String get menuSettings => 'Configuração';

  @override
  String menuSettingsSubtitle(Object calories) {
    return 'Meta diária: $calories kcal';
  }

  @override
  String get menuNutritionalPillars => 'Pilares da Nutrição';

  @override
  String get menuNutritionalPillarsSubtitle => 'Conceitos da ScanNut';

  @override
  String get menuEnergyBalance => 'Balanço Energético';

  @override
  String get menuEnergyBalanceSubtitle => 'Painel Fitness e Biohacking';

  @override
  String get menuNutritionHistory => 'Histórico de Nutrição';

  @override
  String get menuNutritionHistorySubtitle => 'Análises de Alimentos';

  @override
  String get menuBotanyHistory => 'Histórico Botânico';

  @override
  String get menuBotanyHistorySubtitle => 'Saúde e Guia de Cultivo';

  @override
  String get menuPetHistory => 'Histórico de Animais';

  @override
  String get menuPetHistorySubtitle => 'Dossiês e Exames';

  @override
  String get menuHelp => 'Ajuda';

  @override
  String get menuHelpSubtitle => 'Como usar a app';

  @override
  String get menuAbout => 'Sobre';

  @override
  String get menuPrivacySubtitle => 'Consultar termos e dados';

  @override
  String get menuDeleteAccountSubtitle => 'Remover todos os registos';

  @override
  String get menuExit => 'Sair';

  @override
  String get menuExitSubtitle => 'Fechar a aplicação';

  @override
  String get logoutTitle => 'Sair e Desconectar';

  @override
  String get logoutSubtitle => 'Encerrar sessão no ScanNut';

  @override
  String get contactSubject => 'Contacto ScanNut';

  @override
  String get helpWelcomeTitle => 'Bem-vindo ao ScanNut!';

  @override
  String get helpWelcomeSubtitle => 'O seu assistente visual de IA';

  @override
  String get helpDisclaimerTitle => '⚠️ AVISO IMPORTANTE';

  @override
  String get helpDisclaimerBody =>
      'A Inteligência Artificial pode cometer erros na análise de imagens. O ScanNut NÃO se responsabiliza pelas informações geradas pela IA.\n\n• As análises são apenas ORIENTATIVAS\n• NÃO substituem profissionais qualificados\n• Consulte sempre veterinários, nutricionistas ou botânicos\n• Use a app como ferramenta de apoio, não como diagnóstico final';

  @override
  String get helpFooter =>
      'ScanNut v1.5.1\nDesenvolvido com ❤️ por Abreu Retto';

  @override
  String get footerDevelopedBy => 'Desenvolvido por Abreu Retto';

  @override
  String get footerMadeWith => 'Feito com ❤️ usando Gemini AI';

  @override
  String get aboutTitle => 'Sobre a ScanNut';

  @override
  String get aboutSubtitle => 'ScanNut IA Visual Assistant';

  @override
  String get aboutPoweredBy => 'Powered by Google Gemini 2.5 Flash';

  @override
  String get aboutDescription =>
      'Análise inteligente de:\n• Alimentos 🍎\n• Plantas 🌿\n• Animais 🐾';

  @override
  String get nutritionGuideTitle => 'Guia de Nutrição Animal ScanNut';

  @override
  String get nutritionIntro =>
      'Diferente dos humanos, os cães e gatos possuem um metabolismo acelerado e exigências nutricionais únicas. A ScanNut utiliza IA para equilibrar estes 5 pilares vitais para a longevidade do seu animal.';

  @override
  String get ngProteinTitle => 'Proteína Animal';

  @override
  String get ngProteinSubtitle => 'A Força do Animal';

  @override
  String get ngProteinWhatIs =>
      'Animais são carnívoros (estritos como gatos ou facultativos como cães). Eles precisam de aminoácidos específicos encontrados na carne que o corpo deles não produz.';

  @override
  String get ngProteinAction =>
      'Priorizamos fontes como frango, carne bovina, peixes, ovos ou proteínas selecionadas em rações premium.';

  @override
  String get ngFatsTitle => 'Gorduras Específicas';

  @override
  String get ngFatsSubtitle => 'A Proteção';

  @override
  String get ngFatsWhatIs =>
      'Além da energia, a gordura correta previne dermatites e garante que o animal absorva as vitaminas A, D, E e K. O Ómega 3 é o maior aliado contra inflamações.';

  @override
  String get ngFatsAction =>
      'Sugerimos o equilíbrio de Ómegas 3 e 6, provenientes de óleos de peixe ou gorduras boas.';

  @override
  String get ngCarbsTitle => 'Fibras e Hidratos Selecionados';

  @override
  String get ngCarbsSubtitle => 'O Intestino';

  @override
  String get ngCarbsWhatIs =>
      'O sistema digestivo do animal é mais curto. Usamos hidratos de fácil digestão (como batata-doce ou arroz) e fibras que auxiliam na formação correta das fezes.';

  @override
  String get ngCarbsAction =>
      'Sugerimos vegetais como abóbora e cenoura, e grãos como arroz integral ou aveia.';

  @override
  String get ngVitaminsTitle => 'Minerais e Vitaminas';

  @override
  String get ngVitaminsSubtitle => 'Cuidado com a Dose';

  @override
  String get ngVitaminsWhatIs =>
      'Crucial: O excesso de cálcio pode prejudicar crias e a falta pode fragilizar idosos. A ScanNut foca no equilíbrio mineral exato para a estrutura óssea canina e felina.';

  @override
  String get ngVitaminsAction =>
      'A app sinaliza a necessidade de suplementação, especialmente em dietas Naturais, para evitar carências.';

  @override
  String get ngHydrationTitle => 'Hidratação Biológica';

  @override
  String get ngHydrationSubtitle => 'O Ponto Fraco';

  @override
  String get ngHydrationWhatIs =>
      'Muitos animais não sentem sede proporcional à necessidade. A app incentiva alimentos húmidos para evitar cálculos renais, uma das maiores causas de óbito em gatos e cães idosos.';

  @override
  String get ngHydrationAction =>
      'Sugerimos a inclusão de alimentos húmidos, caldos ou adição de água na ração para proteger os rins.';

  @override
  String get ngWarningTitle => 'ATENÇÃO:';

  @override
  String get ngWarningText =>
      'Nunca ofereça alimentos proibidos para animais (como chocolate, uvas, cebola e xilitol). As sugestões da ScanNut respeitam estas restrições de segurança.';

  @override
  String get ngSectionWhatIs => 'O que é:';

  @override
  String get ngSectionScanNut => 'Na ScanNut:';

  @override
  String get fitnessDashboardTitle => 'Painel Fitness';

  @override
  String get fitnessBalanceKcal => 'Saldo kcal';

  @override
  String fitnessMetaDaily(Object goal) {
    return 'Meta diária: $goal kcal';
  }

  @override
  String get fitnessConsumed => 'Consumido';

  @override
  String get fitnessBurned => 'Queimado';

  @override
  String get fitnessPerformance => 'Performance Biohacking';

  @override
  String get fitnessTip =>
      'Dica do Dia: Treine em jejum hoje para otimizar a queima de gordura de acordo com o seu último consumo de hidratos.';

  @override
  String get fitnessAddWorkout => 'Adicionar Treino';

  @override
  String get fitnessRegWorkout => 'Registar Treino';

  @override
  String get fitnessExerciseHint => 'Exercício (ex: Corrida)';

  @override
  String get fitnessCaloriesHint => 'Calorias Queimadas';

  @override
  String get fitnessDurationHint => 'Duração (min)';

  @override
  String get botanyTitle => 'Inteligência Botânica';

  @override
  String get botanyEmpty => 'Nenhuma planta analisada ainda.';

  @override
  String get botanyStatus => 'ESTADO';

  @override
  String get botanyToxicHuman => 'TÓXICA para humanos';

  @override
  String get botanyDangerousPet => 'PERIGOSA para animais';

  @override
  String get botanyRecovery => 'Recuperação';

  @override
  String get botanyRecoveryPlan => 'Plano de Recuperação';

  @override
  String get botanyFengShui => 'Feng Shui e Simbolismo';

  @override
  String botanyDossierTitle(String plantName) {
    return 'Dossiê Botânico: $plantName';
  }

  @override
  String get petHistoryTitle => 'Os Meus Animais Guardados';

  @override
  String get petHistoryEmpty => 'Nenhum animal guardado ainda.';

  @override
  String get petBreed => 'N/D';

  @override
  String get petLinkPartnerError =>
      'Vincule um parceiro no separador \"Parc.\" para aceder à agenda';

  @override
  String get petNoRecentMenu => 'Sem cardápio recente.';

  @override
  String get petEditSaved => 'Alterações guardadas.';

  @override
  String get foodHistoryTitle => 'Histórico de Alimentos';

  @override
  String get foodHistoryEmpty => 'Nenhuma análise guardada ainda.';

  @override
  String get foodReload => 'Recarregar';

  @override
  String get foodKcalPer100g => 'kcal / 100g';

  @override
  String get foodProt => 'Prot.';

  @override
  String get foodCarb => 'Hidr.';

  @override
  String get foodFat => 'Gord.';

  @override
  String get foodDeleteConfirmTitle => 'Eliminar Análise?';

  @override
  String get foodDeleteConfirmContent => 'Esta ação não pode ser desfeita.';

  @override
  String get commonUnderstand => 'Entendido';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get linkError => 'Não foi possível abrir a ligação.';

  @override
  String get helpTitle => 'Ajuda e Suporte';

  @override
  String get helpCommonQuestions => 'Perguntas Frequentes';

  @override
  String get helpContactUs => 'Contacte-nos';

  @override
  String get helpTutorials => 'Tutoriais em Vídeo';

  @override
  String get helpAppVersion => 'Versão da Aplicação';

  @override
  String get helpUserGuide => 'Guia do Utilizador';

  @override
  String get helpTermsPrivacy => 'Termos e Privacidade';

  @override
  String get guideVitalsTitle => 'SECÇÕES DO PERFIL DO ANIMAL';

  @override
  String get guideIdentity => 'Identidade';

  @override
  String get guideIdentityDesc =>
      'Gerira os dados vitais do animal: peso, raça, idade e análise comportamental genética completa.';

  @override
  String get guideHealth => 'Saúde';

  @override
  String get guideHealthDesc =>
      'Histórico médico completo com controlo de vacinas, desparasitantes, exames laboratoriais e lembretes de consultas.';

  @override
  String get guideNutrition => 'Nutrição';

  @override
  String get guideNutritionDesc =>
      'Planeamento alimentar semanal detalhado com cálculos de Kcal, datas (DD/MM) e os 5 pilares nutricionais.';

  @override
  String get guideGallery => 'Galeria';

  @override
  String get guideGalleryDesc =>
      'Documente visualmente a evolução e momentos especiais do seu animal com fotos e vídeos.';

  @override
  String get guidePrac => 'Prac';

  @override
  String get guidePracDesc =>
      'Prontuário de Acompanhamento Comportamental para registar rotinas, mudanças de hábito e rede de apoio.';

  @override
  String get guideObservationsTitle => 'OBSERVAÇÕES E HISTÓRICO';

  @override
  String get guideHistory => 'Histórico Cumulativo';

  @override
  String get guideHistoryDesc =>
      'Cada secção possui um campo de observações. Novas anotações NÃO apagam as antigas - tudo fica registado!';

  @override
  String get guideTimestamps => 'Timestamps Automáticos';

  @override
  String get guideTimestampsDesc =>
      'O sistema insere automaticamente Data e Hora em cada entrada, criando um histórico cronológico completo.';

  @override
  String get guideOrder => 'Ordem Inteligente';

  @override
  String get guideOrderDesc =>
      'A entrada mais recente aparece sempre no topo, facilitando a leitura e acompanhamento.';

  @override
  String get guideVoice => 'Ditado por Voz';

  @override
  String get guideVoiceDesc =>
      'Use o ícone de microfone para ditar observações em vez de escrever. Mais rápido e prático!';

  @override
  String get guideExportTitle => 'EXPORTAÇÃO EM PDF';

  @override
  String get guidePdfTitle => 'Prontuário Veterinário Completo';

  @override
  String get guidePdfDesc =>
      'É gerado automaticamente com TODAS as informações (Perfil + Saúde + Nutrição + Observações). Ideal para levar ao veterinário!';

  @override
  String get guideBotanyTitle => 'ANÁLISE DE PLANTAS';

  @override
  String get guideBotanyLeaf => 'Ícone de Folha (Verde)';

  @override
  String get guideBotanyLeafDesc =>
      'Indica que a planta está SAUDÁVEL. Nenhuma intervenção urgente necessária.';

  @override
  String get guideBotanyAlert => 'Ícone de Alerta (Amarelo/Laranja)';

  @override
  String get guideBotanyAlertDesc =>
      'Planta requer ATENÇÃO. Pode estar com deficiências nutricionais ou stress hídrico.';

  @override
  String get guideBotanyCritical => 'Ícone de Emergência (Vermelho)';

  @override
  String get guideBotanyCriticalDesc =>
      'Estado CRÍTICO. A planta necessita de tratamento imediato para sobreviver.';

  @override
  String get guideBotanyTraffic => 'Semáforo de Sobrevivência';

  @override
  String get guideBotanyTrafficDesc =>
      'Verde = Ideal | Amarelo = Atenção | Vermelho = Urgente. Aparece nos cartões de histórico.';

  @override
  String get guideFinalTip =>
      'A ScanNut é uma ferramenta de longo prazo para acompanhar toda a vida do seu animal!';

  @override
  String get tabSummary => 'RESUMO';

  @override
  String get tabNutrients => 'NUTRIENTES';

  @override
  String get tabGastronomy => 'GASTRONOMIA';

  @override
  String get labelTrafficLight => 'Semáforo';

  @override
  String get cardTapForRecipes => 'Toque para ver receitas ✨';

  @override
  String get cardScore => 'Score';

  @override
  String get cardTabOverview => 'Visão Geral';

  @override
  String get cardTabDetails => 'Detalhes';

  @override
  String get cardTabTips => 'Dicas';

  @override
  String get cardTotalCalories => 'Calorias Totais';

  @override
  String get cardDailyGoal => 'da meta diária';

  @override
  String get cardMacroDist => 'Distribuição de Macronutrientes';

  @override
  String get cardQuickSummary => 'Resumo Rápido';

  @override
  String get cardBenefits => 'Benefícios';

  @override
  String get cardAlerts => 'Alertas';

  @override
  String get cardVitalityScore => 'Score de Vitalidade';

  @override
  String get cardDetailedInfo => 'Informações Detalhadas';

  @override
  String get cardDisclaimer =>
      'Nota: Esta é uma análise feita por IA e não substitui um diagnóstico de nutricionista.';

  @override
  String get pdfFoodTitle => 'Análise Nutricional & Biohacking';

  @override
  String get pdfDate => 'Data';

  @override
  String get pdfCalories => 'Calorias';

  @override
  String get pdfTrafficLight => 'Semáforo';

  @override
  String get pdfProcessing => 'Processamento';

  @override
  String get pdfExSummary => 'Resumo Executivo';

  @override
  String get pdfAiVerdict => 'Veredito da IA';

  @override
  String get pdfPros => 'Pontos Positivos';

  @override
  String get pdfCons => 'Pontos de Atenção';

  @override
  String get pdfDetailedNutrition => 'Nutrição Detalhada';

  @override
  String get pdfMacros => 'Macronutrientes';

  @override
  String get pdfNutrient => 'Nutriente';

  @override
  String get pdfQuantity => 'Quantidade';

  @override
  String get pdfDetails => 'Detalhes';

  @override
  String get pdfMicros => 'Micronutrientes e Vitaminas';

  @override
  String get pdfSynergy => 'Sinergia Nutricional';

  @override
  String get pdfBiohacking => 'Biohacking e Saúde';

  @override
  String get pdfPerformance => 'Performance';

  @override
  String get pdfSatiety => 'Índice de Saciedade';

  @override
  String get pdfFocus => 'Foco e Energia';

  @override
  String get pdfIdealMoment => 'Momento Ideal';

  @override
  String get pdfSecurity => 'Segurança';

  @override
  String get pdfAlerts => 'Alertas';

  @override
  String get pdfBiochem => 'Bioquímica';

  @override
  String get pdfGastronomy => 'Gastronomia e Dicas';

  @override
  String get pdfQuickRecipes => 'Receitas Rápidas';

  @override
  String pdfGeneratedBy(Object date, Object owner) {
    return 'Gerado por ScanNut';
  }

  @override
  String pdfPage(Object current, Object total) {
    return 'Página $current de $total';
  }

  @override
  String weeklyPlanTitle(Object date) {
    return 'Plano da Semana de $date';
  }

  @override
  String weeklyPlanSubtitle(Object count) {
    return '$count dias planeados';
  }

  @override
  String get tipsTitle => 'Dicas de Batch Cooking';

  @override
  String get caloriesEstimated => 'kcal est.';

  @override
  String get todayLabel => 'HOJE';

  @override
  String get mealBreakfast => 'Pequeno-Almoço';

  @override
  String get mealLunch => 'Almoço';

  @override
  String get mealSnack => 'Lanche';

  @override
  String get mealDinner => 'Jantar';

  @override
  String get regeneratePlanTitle => 'Regenerar Menu';

  @override
  String get regeneratePlanBody =>
      'Deseja criar um novo menu para esta semana? O plano atual será substituído.';

  @override
  String get regenerateAction => 'Regenerar';

  @override
  String get regenerateSuccess => 'Novo menu gerado!';

  @override
  String get planError => 'Erro ao carregar menu';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get noPlanTitle => 'Nenhum menu para esta semana';

  @override
  String get createPlanButton => 'Criar Menu';

  @override
  String get historyTitle => 'Histórico de Menus';

  @override
  String get noHistory => 'Nenhum histórico encontrado.';

  @override
  String daysPlanned(Object count) {
    return '$count dias planeados';
  }

  @override
  String get deletePlanTitle => 'Eliminar Menu';

  @override
  String get deletePlanBody =>
      'Tem a certeza? Não poderá recuperar este planeamento.';

  @override
  String get ingredientsTitle => 'INGREDIENTES';

  @override
  String get mealDefault => 'Refeição';

  @override
  String get creatingProfile => 'Perfil básico criado automaticamente.';

  @override
  String get planCreatedSuccess => 'Menu criado com sucesso!';

  @override
  String get openingConfig => 'A abrir configuração...';

  @override
  String get pdfMenuPlanTitle => 'Plano Alimentar Semanal';

  @override
  String get menuCreationTitle => 'Criar Menu Semanal';

  @override
  String get menuCreationSubtitle => 'Configure como quer o seu menu';

  @override
  String get mealsPerDay => 'Refeições por dia';

  @override
  String get mealsUnit => 'refeições';

  @override
  String get menuStyleTitle => 'Estilo do menu';

  @override
  String get styleSimple => 'Simples';

  @override
  String get styleBudget => 'Económico';

  @override
  String get styleQuick => 'Rápido';

  @override
  String get styleHealthy => 'Saudável';

  @override
  String get dietaryRestrictions => 'Restrições alimentares';

  @override
  String get allowRepetition => 'Pode repetir receitas na semana';

  @override
  String get allowRepetitionSubtitle =>
      'Se desligado, cada receita aparece apenas 1 vez';

  @override
  String get restVegetarian => 'Vegetariano';

  @override
  String get restVegan => 'Vegano';

  @override
  String get restLactoseFree => 'Sem Lactose';

  @override
  String get restGlutenFree => 'Sem Glúten';

  @override
  String get restDiabetes => 'Diabetes';

  @override
  String get restHypertension => 'Hipertensão';

  @override
  String get pdfPersonalizedPlanTitle => 'PLANO ALIMENTAR PERSONALIZADO';

  @override
  String get pdfGoalLabel => 'OBJETIVO';

  @override
  String get pdfGeneratedByLine =>
      'RELATÓRIO DE NUTRIÇÃO SEMANAL GERADO POR ScanNut AI';

  @override
  String get pdfBatchCookingTips => '💡 DICAS DE BATCH COOKING E PREPARAÇÃO';

  @override
  String get tipBeans =>
      '💡 Cozinhe uma panela grande de feijão logo no início da semana e congele porções para economizar gás e tempo.';

  @override
  String get tipRice =>
      '💡 Mantenha uma base de arroz branco pronta no frigorífico; é o acompanhamento coringa para quase todos os seus pratos.';

  @override
  String get tipChicken =>
      '💡 Cozinhe e desfie o frango de uma única vez. Use-o no sanduíche natural, no wrap e no que vier à sexta-feira.';

  @override
  String get tipEggs =>
      '💡 Ovos são a sua proteína económica e rápida. Mantenha-os sempre à mão para substituir carnes em dias corridos.';

  @override
  String get tipVeggies =>
      '💡 Lave e pique todos os vegetais da estação assim que chegar do mercado. Guarde-os em caixas herméticas para durarem mais.';

  @override
  String get tipRoots =>
      '💡 Raízes como mandioca e batata doce podem ser cozidas em grande quantidade e guardadas na água no frigorífico por 3 dias.';

  @override
  String get tipGroundMeat =>
      '💡 A carne picada é a base perfeita: use-a pura no almoço e no recheio da panqueca ou sanduíche no dia seguinte.';

  @override
  String get tipFruits =>
      '💡 Frutas muito maduras? Congele-as em pedaços para turbinar as suas vitaminas e batidos matinais.';

  @override
  String get tipDefault =>
      'Planeie as suas compras com foco em itens da estação para economizar e ganhar saúde.';

  @override
  String get foodRice => 'Arroz';

  @override
  String get foodBeans => 'Feijão';

  @override
  String get foodChicken => 'Frango';

  @override
  String get foodMeat => 'Carne';

  @override
  String get foodFish => 'Peixe';

  @override
  String get foodEgg => 'Ovo';

  @override
  String get foodBread => 'Pão';

  @override
  String get foodMilk => 'Leite';

  @override
  String get foodCoffee => 'Café';

  @override
  String get foodYogurt => 'Iogurte';

  @override
  String get foodFruit => 'Fruta';

  @override
  String get foodSalad => 'Salada';

  @override
  String get foodVegetables => 'Legumes';

  @override
  String get foodPasta => 'Massa';

  @override
  String get foodPotato => 'Batata';

  @override
  String get foodCassava => 'Mandioca';

  @override
  String get foodCheese => 'Queijo';

  @override
  String get foodJuice => 'Sumo';

  @override
  String get foodWater => 'Água';

  @override
  String get defaultWoundAnalysis => 'Análise de Ferida/Lesão';

  @override
  String get petSelectionTitle => 'De qual animal é esta análise?';

  @override
  String get petNew => 'Novo Animal';

  @override
  String get petQuickAnalysis => 'Análise rápida sem guardar';

  @override
  String get plantCareGuide => 'Guia de Tratamento';

  @override
  String get toxicityWarning => 'Atenção: Tóxica para Pets';

  @override
  String get featureMenuPlanTitle => 'Planeamento de Ementa Inteligente';

  @override
  String get featureMenuPlanDesc =>
      'Crie ementas semanais personalizadas baseadas nas suas metas e restrições alimentares.';

  @override
  String get pdfAgendaTitle => 'AGENDA GLOBAL';

  @override
  String get pdfAgendaReport => 'Relatório de Agenda';

  @override
  String get agendaGlobalTitle => 'Agenda Global';

  @override
  String get agendaViewCalendar => 'Ver Calendário';

  @override
  String get agendaViewAll => 'Ver Lista Completa';

  @override
  String get agendaNoEventsRegistered => 'Nenhum evento registado na agenda.';

  @override
  String get agendaNoEventsTodayDetail => 'Nenhum evento para este dia.';

  @override
  String get agendaAllPets => 'Todos os Animais';

  @override
  String get agendaReportingPeriod => 'Período do Relatório';

  @override
  String get agendaFilterPet => 'Filtrar por Animal';

  @override
  String get agendaFilterCategory => 'Filtrar por Categoria';

  @override
  String get agendaDetailLevel => 'Nível de Detalhe';

  @override
  String get agendaDetailedTable => 'Tabela Detalhada';

  @override
  String get agendaSummaryOnly => 'Apenas Resumo';

  @override
  String get agendaButtonGenerate => 'Gerar PDF';

  @override
  String get agendaAllCategories => 'Todas as Categorias';

  @override
  String get agendaNoPartnerLinked =>
      'Nenhum parceiro vinculado a este evento.';

  @override
  String agendaProfileNotFound(Object name, Object petName) {
    return 'Perfil de $petName não encontrado.';
  }

  @override
  String get privacySecurityTitle => 'Segurança e Proteção de Dados';

  @override
  String get privacySecurityBody =>
      'O ScanNut prioriza a privacidade do utilizador através de uma arquitetura de dados local. Utilizamos criptografia de nível militar (AES-256) para cifrar a base de dados armazenada no seu dispositivo. As chaves de segurança são mantidas em ambiente isolado (Keystore/Keychain), garantindo que, mesmo em caso de perda do telemóvel, os dados permaneçam inacessíveis sem as devidas credenciais ou chaves do sistema.\n\nO utilizador está ciente de que, por não utilizarmos armazenamento na nuvem (Cloud), a manutenção e segurança dos ficheiros de Cópia de Segurança Local exportados são da sua inteira responsabilidade.';

  @override
  String get agendaLoadError => 'Erro ao carregar a agenda. Tente novamente.';

  @override
  String get soundAnalysisTitle => 'Análise Vocal';

  @override
  String get soundAnalysisDesc =>
      'Identifique emoções e necessidades através do latido ou miado.';

  @override
  String get soundRecording => 'Gravando...';

  @override
  String get soundProcessing => 'Analisando...';

  @override
  String get soundStartRecord => 'Toque para gravar';

  @override
  String get soundResultType => 'Tipo';

  @override
  String get soundResultEmotion => 'Emoção';

  @override
  String get soundResultAction => 'Recomendação';

  @override
  String get soundError => 'Erro ao analisar';

  @override
  String get soundEmotionSimple => 'O que ele sente';

  @override
  String get soundReasonSimple => 'Motivo provável';

  @override
  String get soundActionTip => 'Dica rápida';

  @override
  String get soundUploadBtn => 'Enviar Áudio';

  @override
  String get petFoodCardTitle => 'Análise de Rótulo';

  @override
  String get petFoodVerdict => 'Veredito';

  @override
  String get petFoodReason => 'Motivo';

  @override
  String get petFoodTip => 'Dica Diária';

  @override
  String get petFoodStart => 'Analisar Rótulo';

  @override
  String get petFoodError => 'Erro na leitura';
}
