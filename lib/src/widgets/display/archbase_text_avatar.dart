import 'package:flutter/material.dart';

import '../../utils/extensions/archbase_extensions.dart';

/// Avatar circular com iniciais coloridas, gerando cor de fundo
/// determinística a partir do hash do texto.
class ArchbaseTextAvatar extends StatelessWidget {
  const ArchbaseTextAvatar({
    super.key,
    required this.text,
    this.size = 40,
    this.imageUrl,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
    this.shape = BoxShape.circle,
    this.maxInitials = 2,
  });

  final String text;
  final double size;
  final String? imageUrl;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final BoxShape shape;
  final int maxInitials;

  /// Paleta usada para gerar o fundo quando [backgroundColor] não é informado.
  static const _palette = <Color>[
    Color(0xFF2E7D32),
    Color(0xFF1976D2),
    Color(0xFFD32F2F),
    Color(0xFFFF9800),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFF5E35B1),
    Color(0xFFC2185B),
    Color(0xFFEF6C00),
    Color(0xFF558B2F),
  ];

  Color _generateColor() {
    int hash = 0;
    for (final code in text.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? _generateColor();
    final fg = foregroundColor ?? Colors.white;
    final initials = text.initials(max: maxInitials);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(8) : null,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: imageUrl != null
          ? null
          : Text(
              initials,
              style: TextStyle(
                color: fg,
                fontSize: fontSize ?? size * 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

/// Stack de avatares (sobrepostos) — útil para mostrar participantes,
/// reactions, etc.
class ArchbaseAvatarStack extends StatelessWidget {
  const ArchbaseAvatarStack({
    super.key,
    required this.avatars,
    this.size = 32,
    this.overlap = 12,
    this.maxVisible = 4,
    this.borderColor,
  });

  final List<ArchbaseTextAvatar> avatars;
  final double size;
  final double overlap;
  final int maxVisible;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final visible = avatars.take(maxVisible).toList();
    final extra = avatars.length - visible.length;
    final border = borderColor ?? Theme.of(context).scaffoldBackgroundColor;

    return SizedBox(
      width: visible.length * (size - overlap) +
          overlap +
          (extra > 0 ? size - overlap : 0),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 2),
                ),
                child: visible[i],
              ),
            ),
          if (extra > 0)
            Positioned(
              left: visible.length * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade400,
                  border: Border.all(color: border, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
