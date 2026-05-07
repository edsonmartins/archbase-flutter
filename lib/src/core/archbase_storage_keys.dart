/// Chaves usadas internamente pela biblioteca para armazenamento.
///
/// Apps consumidores podem definir as próprias chaves; estas servem como
/// padrão e evitam colisão entre apps que usam o framework.
class ArchbaseStorageKeys {
  ArchbaseStorageKeys._();

  // Auth
  static const String accessToken = 'archbase.access_token';
  static const String refreshToken = 'archbase.refresh_token';
  static const String tokenExpiresAt = 'archbase.token_expires_at';
  static const String currentUser = 'archbase.current_user';

  // App
  static const String deviceId = 'archbase.device_id';
  static const String appVersion = 'archbase.app_version';
  static const String firstRun = 'archbase.first_run';

  // Theme
  static const String themeMode = 'archbase.theme_mode';
  static const String fontSize = 'archbase.font_size';
  static const String highContrast = 'archbase.high_contrast';

  // Auth UX
  static const String rememberedEmail = 'archbase.remembered_email';
  static const String biometricEnabled = 'archbase.biometric_enabled';
  static const String failedLoginAttempts = 'archbase.failed_login_attempts';
  static const String loginLockUntil = 'archbase.login_lock_until';

  // Push
  static const String fcmToken = 'archbase.fcm_token';

  // Hive boxes
  static const String cacheBox = 'archbase_cache';
  static const String syncQueueBox = 'archbase_sync_queue';
}
