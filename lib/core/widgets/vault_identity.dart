import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Static vector atmosphere: no network images, blur layers or perpetual motion.
class VaultAtmosphere extends StatelessWidget {
  const VaultAtmosphere({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        gradient: RadialGradient(
          center: const Alignment(0.9, -1),
          radius: 1.3,
          colors: [
            scheme.tertiary.withValues(alpha: 0.09),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          stops: const [0, 0.8],
        ),
      ),
      child: child,
    );
  }
}

class VaultMark extends StatelessWidget {
  const VaultMark({super.key, this.size = 56, this.orbits = false});
  final double size;
  final bool orbits;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _VaultMarkPainter(scheme.primary, scheme.tertiary, orbits),
          child: Center(
            child: Icon(
              Icons.lock_outline_rounded,
              size: size * (orbits ? 0.24 : 0.42),
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _VaultMarkPainter extends CustomPainter {
  _VaultMarkPainter(this.mint, this.violet, this.orbits);
  final Color mint, violet;
  final bool orbits;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * (orbits ? 0.25 : 0.44);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius * 0.64)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mint.withValues(alpha: 0.20),
            violet.withValues(alpha: 0.08),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius * 0.64)),
      Paint()
        ..color = mint.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (orbits) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (var i = 0; i < 3; i++) {
        final orbit = radius * (1.35 + i * 0.26);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: orbit),
          -1.2 + i,
          math.pi * 1.45,
          false,
          stroke..color = (i == 1 ? violet : mint).withValues(alpha: 0.23),
        );
        final angle = i * 2.0 - 1.2;
        canvas.drawCircle(
          center + Offset(math.cos(angle), math.sin(angle)) * orbit,
          2.4,
          Paint()..color = i == 1 ? violet : mint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_VaultMarkPainter old) =>
      old.mint != mint || old.violet != violet || old.orbits != orbits;
}

class VaultEyebrow extends StatelessWidget {
  const VaultEyebrow(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 2,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}
