import 'archbase_exception.dart';

/// Exceções da camada de autenticação.
class AuthException extends ArchbaseException {
  AuthException(super.message, {super.cause, super.stackTrace});
}

class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException([super.message = 'Credenciais inválidas']);
}

class TokenExpiredException extends AuthException {
  TokenExpiredException([super.message = 'Sessão expirada']);
}

class RefreshFailedException extends AuthException {
  RefreshFailedException([super.message = 'Não foi possível renovar a sessão']);
}

class AccountLockedException extends AuthException {
  AccountLockedException(this.unlockAt)
      : super('Conta bloqueada por excesso de tentativas');

  final DateTime unlockAt;
}
