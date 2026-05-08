import 'package:flutter/material.dart';

import '../../theme/archbase_theme_extensions.dart';

class ArchbaseIntroPage {
  const ArchbaseIntroPage({
    required this.title,
    required this.description,
    this.image,
    this.icon,
    this.backgroundColor,
  });

  final String title;
  final String description;
  final Widget? image;
  final IconData? icon;
  final Color? backgroundColor;
}

/// Tela de onboarding com páginas paginadas, indicators e botões de
/// "pular" / "próximo" / "começar".
class ArchbaseIntroScreen extends StatefulWidget {
  const ArchbaseIntroScreen({
    super.key,
    required this.pages,
    required this.onDone,
    this.onSkip,
    this.skipLabel = 'Pular',
    this.nextLabel = 'Próximo',
    this.doneLabel = 'Começar',
    this.showSkip = true,
  });

  final List<ArchbaseIntroPage> pages;
  final VoidCallback onDone;
  final VoidCallback? onSkip;
  final String skipLabel;
  final String nextLabel;
  final String doneLabel;
  final bool showSkip;

  @override
  State<ArchbaseIntroScreen> createState() => _ArchbaseIntroScreenState();
}

class _ArchbaseIntroScreenState extends State<ArchbaseIntroScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == widget.pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _skip() {
    (widget.onSkip ?? widget.onDone).call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.archbase;
    final page = widget.pages[_index];

    return Scaffold(
      backgroundColor:
          page.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, idx) {
                  final p = widget.pages[idx];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (p.image != null)
                          Expanded(child: p.image!)
                        else if (p.icon != null)
                          Icon(p.icon,
                              size: 120, color: colors.archbase.primary)
                        else
                          const Spacer(),
                        const SizedBox(height: 24),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  );
                },
              ),
            ),
            _Indicator(count: widget.pages.length, current: _index),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.showSkip && !_isLast)
                    TextButton(
                      onPressed: _skip,
                      child: Text(widget.skipLabel),
                    )
                  else
                    const SizedBox(width: 88),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(_isLast ? widget.doneLabel : widget.nextLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final color = context.archbase.archbase.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current ? color : color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
