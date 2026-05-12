import 'archbase_localizations.dart';

/// Implementação en-US (referência para apps fazerem suas próprias).
class ArchbaseLocalizationsEnUs extends ArchbaseLocalizations {
  const ArchbaseLocalizationsEnUs();

  @override
  String get fieldRequired => 'Required field';
  @override
  String get emailInvalid => 'Invalid e-mail';
  @override
  String get cpfInvalid => 'Invalid CPF';
  @override
  String get cnpjInvalid => 'Invalid CNPJ';
  @override
  String get cpfOrCnpjRequired => 'CPF/CNPJ required';
  @override
  String get cpfOrCnpjInvalid => 'Invalid CPF/CNPJ';
  @override
  String get phoneBrInvalid => 'Invalid phone number';
  @override
  String get cnhInvalid => 'Invalid driver license';
  @override
  String get plateInvalid => 'Invalid plate';
  @override
  String get cardInvalid => 'Invalid card number';
  @override
  String get urlInvalid => 'Invalid URL';
  @override
  String get valuesMismatch => 'Values do not match';
  @override
  String get valuesMustDiffer => 'Value must be different';
  @override
  String get formatInvalid => 'Invalid format';
  @override
  String get numberInvalid => 'Invalid number';
  @override
  String get dateInvalid => 'Invalid date';
  @override
  String get strongPasswordMessage =>
      'Password must have 8+ chars with uppercase, lowercase, number and symbol';
  @override
  String minLengthMessage(int n) => 'Minimum $n characters';
  @override
  String maxLengthMessage(int n) => 'Maximum $n characters';
  @override
  String minAgeMessage(int years) => 'Minimum age not met';
  @override
  String numericBetweenMessage(num min, num max) =>
      'Value must be between $min and $max';

  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirm => 'Confirm';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get close => 'Close';
  @override
  String get retry => 'Retry';
  @override
  String get tryAgain => 'Try again';
  @override
  String get next => 'Next';
  @override
  String get previous => 'Previous';
  @override
  String get done => 'Done';
  @override
  String get skip => 'Skip';
  @override
  String get logout => 'Log out';
  @override
  String get search => 'Search';
  @override
  String get clear => 'Clear';

  @override
  String get somethingWentWrong => 'Something went wrong';
  @override
  String get confirmDeletion => 'Confirm deletion';
  @override
  String get deletionWarning => 'This action cannot be undone.';
  @override
  String get discardChangesTitle => 'Discard changes?';
  @override
  String get discardChangesMessage => 'You have unsaved changes. Discard?';
  @override
  String get discard => 'Discard';
  @override
  String get logoutTitle => 'Log out?';
  @override
  String get logoutMessage => 'You will need to sign in again.';
  @override
  String get loading => 'Loading…';
  @override
  String get noData => 'No data to display';
  @override
  String get nothingHere => 'Nothing here';

  @override
  String get errorConnection => 'No server connection. Check your internet.';
  @override
  String get errorTimeout => 'Connection timed out. Try again.';
  @override
  String get errorCancelled => 'Request cancelled.';
  @override
  String get errorBadRequest => 'Invalid request.';
  @override
  String get errorUnauthorized => 'Session expired. Please sign in again.';
  @override
  String get errorForbidden => 'You are not allowed to do this.';
  @override
  String get errorNotFound => 'Resource not found.';
  @override
  String get errorConflict => 'Conflict with current resource state.';
  @override
  String get errorValidation => 'Invalid data.';
  @override
  String get errorServer => 'Server failure. Try again shortly.';
  @override
  String errorGeneric(int? statusCode) =>
      'Operation failed${statusCode != null ? ' (HTTP $statusCode)' : ''}.';

  @override
  String get invalidCredentials => 'Invalid credentials';
  @override
  String get sessionExpired => 'Session expired';
  @override
  String get refreshFailed => 'Could not refresh session';
  @override
  String get notAuthenticated => 'User not authenticated';

  @override
  String get offlineNoChanges => 'No connection';
  @override
  String offlinePending(int count) =>
      'Offline — $count changes waiting to upload';
  @override
  String syncingChanges(int count) => 'Syncing $count changes…';
  @override
  String pendingChanges(int count) => '$count pending changes';

  @override
  String get loginTitle => 'Sign in';
  @override
  String get loginRememberMe => 'Remember me';
  @override
  String get loginForgotPassword => 'Forgot password';
  @override
  String get loginEnter => 'Sign in';
  @override
  String get loginEnterBiometric => 'Sign in with biometrics';
  @override
  String get loginEmailLabel => 'E-mail';
  @override
  String get loginPasswordLabel => 'Password';
  @override
  String get loginNoAccount => 'No account?';
  @override
  String get loginSignUp => 'Sign up';
  @override
  String get loginTestUser => 'Test user';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get appearanceSection => 'Appearance';
  @override
  String get themeLabel => 'Theme';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get themeSystem => 'System default';
  @override
  String get fontSizeLabel => 'Font size';
  @override
  String get fontSmall => 'Small';
  @override
  String get fontNormal => 'Normal';
  @override
  String get fontLarge => 'Large';
  @override
  String get fontXLarge => 'Extra large';
  @override
  String get highContrast => 'High contrast';
  @override
  String get accountSection => 'Account';
  @override
  String get exit => 'Sign out';
  @override
  String get youWillNeedToLogIn => 'You will need to sign in again.';
}
