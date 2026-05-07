import 'package:flutter/material.dart';

import '../core/archbase_storage_keys.dart';
import '../core/state/archbase_service.dart';
import '../services/storage/archbase_storage_service.dart';
import 'archbase_text_styles.dart';

/// Estado de tema do app.
class ArchbaseThemeState {
  const ArchbaseThemeState({
    this.themeMode = ThemeMode.system,
    this.fontScale = ArchbaseFontScale.normal,
    this.highContrast = false,
  });

  final ThemeMode themeMode;
  final ArchbaseFontScale fontScale;
  final bool highContrast;

  ArchbaseThemeState copyWith({
    ThemeMode? themeMode,
    ArchbaseFontScale? fontScale,
    bool? highContrast,
  }) {
    return ArchbaseThemeState(
      themeMode: themeMode ?? this.themeMode,
      fontScale: fontScale ?? this.fontScale,
      highContrast: highContrast ?? this.highContrast,
    );
  }
}

/// Controla theme mode + acessibilidade, persistindo no [ArchbaseStorageService].
class ArchbaseThemeController extends ArchbaseService {
  ArchbaseThemeController(this._storage);

  final ArchbaseStorageService _storage;

  ArchbaseThemeState _state = const ArchbaseThemeState();
  ArchbaseThemeState get state => _state;

  ThemeMode get themeMode => _state.themeMode;
  ArchbaseFontScale get fontScale => _state.fontScale;
  bool get highContrast => _state.highContrast;

  bool isDarkMode(BuildContext context) {
    if (_state.themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _state.themeMode == ThemeMode.dark;
  }

  @override
  Future<void> onInit() async {
    final mode = await _storage.read(ArchbaseStorageKeys.themeMode);
    final fontStr = await _storage.read(ArchbaseStorageKeys.fontSize);
    final hc = await _storage.readBool(ArchbaseStorageKeys.highContrast);

    _state = ArchbaseThemeState(
      themeMode: _modeFromString(mode),
      fontScale: _scaleFromString(fontStr),
      highContrast: hc ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _state = _state.copyWith(themeMode: mode);
    await _storage.write(ArchbaseStorageKeys.themeMode, mode.name);
    notifyListeners();
  }

  Future<void> toggleThemeMode() async {
    const order = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    final next = order[(order.indexOf(_state.themeMode) + 1) % order.length];
    await setThemeMode(next);
  }

  Future<void> setFontScale(ArchbaseFontScale scale) async {
    _state = _state.copyWith(fontScale: scale);
    await _storage.write(ArchbaseStorageKeys.fontSize, scale.name);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _state = _state.copyWith(highContrast: value);
    await _storage.writeBool(ArchbaseStorageKeys.highContrast, value);
    notifyListeners();
  }

  ThemeMode _modeFromString(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  ArchbaseFontScale _scaleFromString(String? raw) {
    return ArchbaseFontScale.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => ArchbaseFontScale.normal,
    );
  }
}
