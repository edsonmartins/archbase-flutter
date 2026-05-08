import 'package:flutter/material.dart';

/// Recorte em onda na borda inferior. Útil para headers cativantes.
class ArchbaseWaveClipper extends CustomClipper<Path> {
  ArchbaseWaveClipper({this.amplitude = 24, this.flipped = false});

  final double amplitude;
  final bool flipped;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (flipped) {
      path.lineTo(0, amplitude);
      path.quadraticBezierTo(
        size.width * 0.25,
        0,
        size.width * 0.5,
        amplitude,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        amplitude * 2,
        size.width,
        amplitude,
      );
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.lineTo(0, size.height - amplitude);
      path.quadraticBezierTo(
        size.width * 0.25,
        size.height,
        size.width * 0.5,
        size.height - amplitude,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height - amplitude * 2,
        size.width,
        size.height - amplitude,
      );
      path.lineTo(size.width, 0);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant ArchbaseWaveClipper old) =>
      old.amplitude != amplitude || old.flipped != flipped;
}

/// Recorte em arco na borda inferior.
class ArchbaseArcClipper extends CustomClipper<Path> {
  ArchbaseArcClipper({this.depth = 30});

  final double depth;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - depth)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + depth,
        size.width,
        size.height - depth,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant ArchbaseArcClipper old) => old.depth != depth;
}

/// Recorte diagonal — corta a borda inferior em diagonal.
class ArchbaseDiagonalClipper extends CustomClipper<Path> {
  ArchbaseDiagonalClipper({this.slope = 60, this.fromLeft = true});

  final double slope;
  final bool fromLeft;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (fromLeft) {
      path
        ..lineTo(0, size.height)
        ..lineTo(size.width, size.height - slope)
        ..lineTo(size.width, 0);
    } else {
      path
        ..lineTo(0, size.height - slope)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, 0);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant ArchbaseDiagonalClipper old) =>
      old.slope != slope || old.fromLeft != fromLeft;
}

/// Atalho widget que aplica um clipper sobre [child] preenchendo com
/// uma cor sólida ou gradiente.
class ArchbaseClippedHeader extends StatelessWidget {
  const ArchbaseClippedHeader({
    super.key,
    required this.child,
    this.clipper,
    this.color,
    this.gradient,
    this.height = 200,
  });

  final Widget child;
  final CustomClipper<Path>? clipper;
  final Color? color;
  final Gradient? gradient;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: clipper ?? ArchbaseWaveClipper(),
      child: Container(
        height: height,
        decoration: BoxDecoration(color: color, gradient: gradient),
        child: child,
      ),
    );
  }
}
