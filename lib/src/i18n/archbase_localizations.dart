import 'package:flutter/widgets.dart';

/// Bundle de strings da `archbase_flutter`. Use [current] para o bundle
/// ativo em escopo global (default pt-BR) ou [of] para resolver via
/// `BuildContext` quando o app instalou um `Localizations` próprio.
///
/// Para sobrescrever, herde [ArchbaseLocalizations] e chame
/// `ArchbaseLocalizations.set(MyEnLocalizations())` no bootstrap, ou
/// instale via [ArchbaseLocalizationsScope].
abstract class ArchbaseLocalizations {
  const ArchbaseLocalizations();

  // ---- Validators ----------------------------------------------------------
  String get fieldRequired;
  String get emailInvalid;
  String get cpfInvalid;
  String get cnpjInvalid;
  String get cpfOrCnpjRequired;
  String get cpfOrCnpjInvalid;
  String get phoneBrInvalid;
  String get cnhInvalid;
  String get plateInvalid;
  String get cardInvalid;
  String get urlInvalid;
  String get valuesMismatch;
  String get valuesMustDiffer;
  String get formatInvalid;
  String get numberInvalid;
  String get dateInvalid;
  String get strongPasswordMessage;
  String minLengthMessage(int n);
  String maxLengthMessage(int n);
  String minAgeMessage(int years);
  String numericBetweenMessage(num min, num max);

  // ---- Botões / labels comuns ---------------------------------------------
  String get save;
  String get cancel;
  String get confirm;
  String get delete;
  String get edit;
  String get close;
  String get retry;
  String get tryAgain;
  String get next;
  String get previous;
  String get done;
  String get skip;
  String get logout;
  String get search;
  String get clear;

  // ---- Diálogos / mensagens -----------------------------------------------
  String get somethingWentWrong;
  String get confirmDeletion;
  String get deletionWarning;
  String get discardChangesTitle;
  String get discardChangesMessage;
  String get discard;
  String get logoutTitle;
  String get logoutMessage;
  String get loading;
  String get noData;
  String get nothingHere;

  // ---- Errors HTTP --------------------------------------------------------
  String get errorConnection;
  String get errorTimeout;
  String get errorCancelled;
  String get errorBadRequest;
  String get errorUnauthorized;
  String get errorForbidden;
  String get errorNotFound;
  String get errorConflict;
  String get errorValidation;
  String get errorServer;
  String errorGeneric(int? statusCode);

  // ---- Auth ---------------------------------------------------------------
  String get invalidCredentials;
  String get sessionExpired;
  String get refreshFailed;
  String get notAuthenticated;

  // ---- Sync banner --------------------------------------------------------
  String get offlineNoChanges;
  String offlinePending(int count);
  String syncingChanges(int count);
  String pendingChanges(int count);

  // ---- Login --------------------------------------------------------------
  String get loginTitle;
  String get loginRememberMe;
  String get loginForgotPassword;
  String get loginEnter;
  String get loginEnterBiometric;
  String get loginEmailLabel;
  String get loginPasswordLabel;
  String get loginNoAccount;
  String get loginSignUp;
  String get loginTestUser;

  // ---- Settings -----------------------------------------------------------
  String get settingsTitle;
  String get appearanceSection;
  String get themeLabel;
  String get themeLight;
  String get themeDark;
  String get themeSystem;
  String get fontSizeLabel;
  String get fontSmall;
  String get fontNormal;
  String get fontLarge;
  String get fontXLarge;
  String get highContrast;
  String get accountSection;
  String get exit;
  String get youWillNeedToLogIn;

  // -------------------------------------------------------------------------

  static ArchbaseLocalizations _current = const ArchbaseLocalizationsPtBr();

  /// Bundle ativo globalmente. Default: pt-BR.
  static ArchbaseLocalizations get current => _current;

  /// Substitui o bundle global (afeta validators que usam mensagem
  /// padrão e widgets que leem direto, sem context).
  static void set(ArchbaseLocalizations bundle) {
    _current = bundle;
  }

  /// Resolve via [ArchbaseLocalizationsScope] se houver — senão usa o
  /// bundle global.
  static ArchbaseLocalizations of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ArchbaseLocalizationsScope>();
    return scope?.bundle ?? _current;
  }
}

/// Provedor de [ArchbaseLocalizations] via árvore de widgets.
class ArchbaseLocalizationsScope extends InheritedWidget {
  const ArchbaseLocalizationsScope({
    super.key,
    required this.bundle,
    required super.child,
  });

  final ArchbaseLocalizations bundle;

  @override
  bool updateShouldNotify(ArchbaseLocalizationsScope oldWidget) =>
      bundle != oldWidget.bundle;
}

/// Implementação default em pt-BR.
class ArchbaseLocalizationsPtBr extends ArchbaseLocalizations {
  const ArchbaseLocalizationsPtBr();

  @override
  String get fieldRequired => 'Campo obrigatório';
  @override
  String get emailInvalid => 'E-mail inválido';
  @override
  String get cpfInvalid => 'CPF inválido';
  @override
  String get cnpjInvalid => 'CNPJ inválido';
  @override
  String get cpfOrCnpjRequired => 'CPF/CNPJ obrigatório';
  @override
  String get cpfOrCnpjInvalid => 'CPF/CNPJ inválido';
  @override
  String get phoneBrInvalid => 'Telefone inválido';
  @override
  String get cnhInvalid => 'CNH inválida';
  @override
  String get plateInvalid => 'Placa inválida';
  @override
  String get cardInvalid => 'Número de cartão inválido';
  @override
  String get urlInvalid => 'URL inválida';
  @override
  String get valuesMismatch => 'Os valores não coincidem';
  @override
  String get valuesMustDiffer => 'Valor não pode ser igual';
  @override
  String get formatInvalid => 'Formato inválido';
  @override
  String get numberInvalid => 'Número inválido';
  @override
  String get dateInvalid => 'Data inválida';
  @override
  String get strongPasswordMessage =>
      'Senha precisa ter 8+ caracteres, com maiúscula, minúscula, número e símbolo';
  @override
  String minLengthMessage(int n) => 'Mínimo de $n caracteres';
  @override
  String maxLengthMessage(int n) => 'Máximo de $n caracteres';
  @override
  String minAgeMessage(int years) => 'Idade mínima não atingida';
  @override
  String numericBetweenMessage(num min, num max) =>
      'Valor deve estar entre $min e $max';

  @override
  String get save => 'Salvar';
  @override
  String get cancel => 'Cancelar';
  @override
  String get confirm => 'Confirmar';
  @override
  String get delete => 'Excluir';
  @override
  String get edit => 'Editar';
  @override
  String get close => 'Fechar';
  @override
  String get retry => 'Tentar novamente';
  @override
  String get tryAgain => 'Tentar novamente';
  @override
  String get next => 'Próximo';
  @override
  String get previous => 'Anterior';
  @override
  String get done => 'Concluir';
  @override
  String get skip => 'Pular';
  @override
  String get logout => 'Sair';
  @override
  String get search => 'Buscar';
  @override
  String get clear => 'Limpar';

  @override
  String get somethingWentWrong => 'Algo deu errado';
  @override
  String get confirmDeletion => 'Confirmar exclusão';
  @override
  String get deletionWarning => 'Esta ação não pode ser desfeita.';
  @override
  String get discardChangesTitle => 'Descartar alterações?';
  @override
  String get discardChangesMessage =>
      'Você tem alterações não salvas. Descartar?';
  @override
  String get discard => 'Descartar';
  @override
  String get logoutTitle => 'Sair?';
  @override
  String get logoutMessage => 'Você precisará entrar novamente.';
  @override
  String get loading => 'Carregando…';
  @override
  String get noData => 'Sem dados para exibir';
  @override
  String get nothingHere => 'Nada por aqui';

  @override
  String get errorConnection =>
      'Sem conexão com o servidor. Verifique sua internet.';
  @override
  String get errorTimeout => 'Tempo de conexão esgotado. Tente novamente.';
  @override
  String get errorCancelled => 'Requisição cancelada.';
  @override
  String get errorBadRequest => 'Requisição inválida.';
  @override
  String get errorUnauthorized => 'Sessão expirada. Faça login novamente.';
  @override
  String get errorForbidden => 'Você não tem permissão para esta ação.';
  @override
  String get errorNotFound => 'Recurso não encontrado.';
  @override
  String get errorConflict => 'Conflito com o estado atual do recurso.';
  @override
  String get errorValidation => 'Dados inválidos.';
  @override
  String get errorServer => 'Falha no servidor. Tente novamente em instantes.';
  @override
  String errorGeneric(int? statusCode) =>
      'Falha na operação${statusCode != null ? ' (HTTP $statusCode)' : ''}.';

  @override
  String get invalidCredentials => 'Credenciais inválidas';
  @override
  String get sessionExpired => 'Sessão expirada';
  @override
  String get refreshFailed => 'Não foi possível renovar a sessão';
  @override
  String get notAuthenticated => 'Usuário não autenticado';

  @override
  String get offlineNoChanges => 'Sem conexão';
  @override
  String offlinePending(int count) =>
      'Offline — $count alterações aguardando envio';
  @override
  String syncingChanges(int count) => 'Sincronizando $count alterações…';
  @override
  String pendingChanges(int count) => '$count alterações pendentes';

  @override
  String get loginTitle => 'Entrar';
  @override
  String get loginRememberMe => 'Lembrar-me';
  @override
  String get loginForgotPassword => 'Esqueci minha senha';
  @override
  String get loginEnter => 'Entrar';
  @override
  String get loginEnterBiometric => 'Entrar com biometria';
  @override
  String get loginEmailLabel => 'E-mail';
  @override
  String get loginPasswordLabel => 'Senha';
  @override
  String get loginNoAccount => 'Não tem conta?';
  @override
  String get loginSignUp => 'Cadastre-se';
  @override
  String get loginTestUser => 'Usuário de teste';

  @override
  String get settingsTitle => 'Configurações';
  @override
  String get appearanceSection => 'Aparência';
  @override
  String get themeLabel => 'Tema';
  @override
  String get themeLight => 'Claro';
  @override
  String get themeDark => 'Escuro';
  @override
  String get themeSystem => 'Padrão do sistema';
  @override
  String get fontSizeLabel => 'Tamanho da fonte';
  @override
  String get fontSmall => 'Pequeno';
  @override
  String get fontNormal => 'Normal';
  @override
  String get fontLarge => 'Grande';
  @override
  String get fontXLarge => 'Muito grande';
  @override
  String get highContrast => 'Alto contraste';
  @override
  String get accountSection => 'Conta';
  @override
  String get exit => 'Sair';
  @override
  String get youWillNeedToLogIn => 'Você precisará entrar novamente.';
}
