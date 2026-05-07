import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/material.dart';

/// Wrapper para widget tests — fornece [MaterialApp] com [ArchbaseTheme]
/// e localização pt-BR.
class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    required this.child,
    this.dark = false,
  });

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ArchbaseTheme.light(),
      darkTheme: ArchbaseTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Material(child: child),
      debugShowCheckedModeBanner: false,
    );
  }
}
