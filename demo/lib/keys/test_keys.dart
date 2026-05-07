/// Identificadores estáveis usados em widgets para os flows Maestro
/// poderem localizá-los de forma robusta (independente de texto/idioma).
///
/// Uso típico:
/// ```dart
/// TextField(key: const ValueKey(TestKeys.loginUsername), ...)
/// ```
///
/// No Maestro:
/// ```yaml
/// - tapOn:
///     id: "login_username"
/// ```
class TestKeys {
  TestKeys._();

  // Login
  static const String loginUsername = 'login_username';
  static const String loginPassword = 'login_password';
  static const String loginSubmit = 'login_submit';
  static const String loginError = 'login_error';

  // Home / nav
  static const String tabVisitas = 'tab_visitas';
  static const String tabHistorico = 'tab_historico';
  static const String tabSettings = 'tab_settings';

  // Visitas
  static const String visitasList = 'visitas_list';
  static const String visitasFab = 'visitas_fab';
  static const String visitaCardPrefix = 'visita_card_';
  static const String visitaSearch = 'visita_search';

  // Form de visita
  static const String formPdv = 'form_pdv';
  static const String formObservacao = 'form_observacao';
  static const String formSalvar = 'form_salvar';
  static const String formExcluir = 'form_excluir';
  static const String formStatus = 'form_status';

  // Sync banner
  static const String syncBanner = 'sync_banner';

  // Settings
  static const String settingsTema = 'settings_tema';
  static const String settingsFonte = 'settings_fonte';
  static const String settingsContraste = 'settings_contraste';
  static const String settingsLogout = 'settings_logout';

  // Dialogs
  static const String dialogConfirm = 'dialog_confirm';
  static const String dialogCancel = 'dialog_cancel';

  // Mock dev controls (toggle online/offline)
  static const String devToggleOffline = 'dev_toggle_offline';
}
