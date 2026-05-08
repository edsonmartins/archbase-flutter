import 'dart:async';

import 'package:flutter/material.dart';

/// Carousel horizontal com paginação, autoplay e loop infinito opcional.
class ArchbaseCarousel extends StatefulWidget {
  const ArchbaseCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 200,
    this.autoplay = false,
    this.autoplayInterval = const Duration(seconds: 4),
    this.viewportFraction = 0.92,
    this.showIndicators = true,
    this.loop = true,
    this.onPageChanged,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double height;
  final bool autoplay;
  final Duration autoplayInterval;
  final double viewportFraction;
  final bool showIndicators;
  final bool loop;
  final ValueChanged<int>? onPageChanged;

  @override
  State<ArchbaseCarousel> createState() => _ArchbaseCarouselState();
}

class _ArchbaseCarouselState extends State<ArchbaseCarousel> {
  late PageController _controller;
  Timer? _timer;
  int _logicalIndex = 0;

  // Para loop, usamos um índice grande inicial; mod para mapear ao real.
  static const int _loopBase = 1000000;

  @override
  void initState() {
    super.initState();
    final initial = widget.loop ? _loopBase : 0;
    _controller = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: initial,
    );
    if (widget.autoplay) _startAutoplay();
  }

  void _startAutoplay() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoplayInterval, (_) {
      if (!_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  int _toLogical(int page) => page % widget.itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.loop ? null : widget.itemCount,
            onPageChanged: (page) {
              final logical = _toLogical(page);
              setState(() => _logicalIndex = logical);
              widget.onPageChanged?.call(logical);
            },
            itemBuilder: (context, page) {
              final logical = _toLogical(page);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: widget.itemBuilder(context, logical),
              );
            },
          ),
        ),
        if (widget.showIndicators) ...[
          const SizedBox(height: 12),
          _Dots(count: widget.itemCount, current: _logicalIndex),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
              color: i == current ? primary : primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
