import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/archbase_theme_extensions.dart';
import '../../utils/validators/archbase_validators.dart';
import '../../widgets/forms/archbase_button.dart';
import '../../widgets/forms/archbase_password_field.dart';
import '../../widgets/forms/archbase_text_field.dart';

/// Modelo de usuário "dev" para preencher rapidamente o login em ambientes
/// de desenvolvimento.
class ArchbaseDevUser {
  const ArchbaseDevUser({
    required this.label,
    required this.username,
    required this.password,
    this.description,
  });

  final String label;
  final String username;
  final String password;
  final String? description;
}

/// Tela de login pronta. Aceita callbacks para login, esqueci senha,
/// biometric login etc. Não amarra a um state management específico.
class ArchbaseLoginScreen extends StatefulWidget {
  const ArchbaseLoginScreen({
    super.key,
    required this.onLogin,
    this.onForgotPassword,
    this.onSignUp,
    this.onBiometricLogin,
    this.logo,
    this.appName,
    this.tagline,
    this.usernameLabel = 'E-mail',
    this.usernameHint,
    this.passwordLabel = 'Senha',
    this.usernameValidator,
    this.passwordValidator,
    this.usernameKeyboardType = TextInputType.emailAddress,
    this.devUsers = const [],
    this.versionLabel,
    this.rememberInitial = false,
  });

  /// Função chamada com (username, password, rememberMe). Deve devolver `null`
  /// em sucesso ou uma mensagem de erro a exibir.
  final Future<String?> Function(
    String username,
    String password,
    bool rememberMe,
  ) onLogin;

  final VoidCallback? onForgotPassword;
  final VoidCallback? onSignUp;
  final Future<void> Function()? onBiometricLogin;

  final Widget? logo;
  final String? appName;
  final String? tagline;
  final String usernameLabel;
  final String? usernameHint;
  final String passwordLabel;
  final String? Function(String?)? usernameValidator;
  final String? Function(String?)? passwordValidator;
  final TextInputType usernameKeyboardType;
  final List<ArchbaseDevUser> devUsers;
  final String? versionLabel;
  final bool rememberInitial;

  @override
  State<ArchbaseLoginScreen> createState() => _ArchbaseLoginScreenState();
}

class _ArchbaseLoginScreenState extends State<ArchbaseLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  late bool _remember;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _remember = widget.rememberInitial;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await widget.onLogin(
      _username.text.trim(),
      _password.text,
      _remember,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.logo != null)
                      Center(child: widget.logo)
                    else
                      const Center(child: FlutterLogo(size: 80)),
                    const SizedBox(height: 24),
                    if (widget.appName != null)
                      Text(
                        widget.appName!,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    if (widget.tagline != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.tagline!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),
                    ArchbaseTextField(
                      controller: _username,
                      label: widget.usernameLabel,
                      hint: widget.usernameHint,
                      required: true,
                      keyboardType: widget.usernameKeyboardType,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(LucideIcons.user),
                      validator: widget.usernameValidator ??
                          ArchbaseValidators.required,
                    ),
                    const SizedBox(height: 12),
                    ArchbasePasswordField(
                      controller: _password,
                      label: widget.passwordLabel,
                      validator: widget.passwordValidator ??
                          ArchbaseValidators.required,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _remember,
                          onChanged: (v) =>
                              setState(() => _remember = v ?? false),
                        ),
                        const Flexible(
                          child: Text(
                            'Lembrar-me',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        if (widget.onForgotPassword != null)
                          Flexible(
                            child: TextButton(
                              onPressed: widget.onForgotPassword,
                              child: const Text(
                                'Esqueci minha senha',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.archbase.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.circleAlert,
                                color: colors.archbase.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: colors.archbase.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ArchbaseButton(
                      label: 'Entrar',
                      onPressed: _loading ? null : _submit,
                      isLoading: _loading,
                      fullWidth: true,
                      size: ArchbaseButtonSize.large,
                    ),
                    if (widget.onBiometricLogin != null) ...[
                      const SizedBox(height: 8),
                      ArchbaseButton(
                        label: 'Entrar com biometria',
                        icon: LucideIcons.fingerprint,
                        variant: ArchbaseButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: _loading
                            ? null
                            : () async => widget.onBiometricLogin!(),
                      ),
                    ],
                    if (widget.devUsers.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _DevUserPicker(
                        users: widget.devUsers,
                        onPick: (u) {
                          _username.text = u.username;
                          _password.text = u.password;
                        },
                      ),
                    ],
                    if (widget.onSignUp != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Não tem conta?'),
                          TextButton(
                            onPressed: widget.onSignUp,
                            child: const Text('Cadastre-se'),
                          ),
                        ],
                      ),
                    ],
                    if (widget.versionLabel != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.versionLabel!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DevUserPicker extends StatelessWidget {
  const _DevUserPicker({required this.users, required this.onPick});

  final List<ArchbaseDevUser> users;
  final ValueChanged<ArchbaseDevUser> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.archbase.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.archbase.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.flaskConical, color: colors.archbase.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ArchbaseDevUser>(
                isExpanded: true,
                hint: const Text('Usuário de teste'),
                items: users
                    .map(
                      (u) => DropdownMenuItem<ArchbaseDevUser>(
                        value: u,
                        child: Text('${u.label} (${u.username})'),
                      ),
                    )
                    .toList(),
                onChanged: (u) => u == null ? null : onPick(u),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
