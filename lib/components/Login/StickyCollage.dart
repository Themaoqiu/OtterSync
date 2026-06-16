import 'package:flutter/material.dart';

enum _StickyIcon { triangle, dots, equals, circle, arrow, square, check, plus }

class StickyCollage extends StatelessWidget {
  const StickyCollage({super.key});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF6A845);
    const purple = Color(0xFFB28BE0);
    const green = Color(0xFF7CC36E);
    const ink = Color(0xFF222222);

    final tiles = <_StickyTile>[
      const _StickyTile(
        color: orange,
        icon: _StickyIcon.triangle,
        ink: ink,
        rotate: -0.02,
      ),
      const _StickyTile(
        color: purple,
        icon: _StickyIcon.dots,
        ink: ink,
        rotate: 0.04,
      ),
      const _StickyTile(
        color: orange,
        icon: _StickyIcon.equals,
        ink: ink,
        rotate: 0.03,
      ),
      const _StickyTile(
        color: green,
        icon: _StickyIcon.circle,
        ink: ink,
        rotate: -0.02,
      ),
      const _StickyTile(
        color: purple,
        icon: _StickyIcon.arrow,
        ink: ink,
        rotate: 0.05,
      ),
      const _StickyTile(
        color: orange,
        icon: _StickyIcon.square,
        ink: ink,
        rotate: -0.04,
      ),
      const _StickyTile(
        color: green,
        icon: _StickyIcon.check,
        ink: ink,
        rotate: 0.02,
      ),
      const _StickyTile(
        color: purple,
        icon: _StickyIcon.plus,
        ink: ink,
        rotate: -0.03,
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      children: [
        tiles[0],
        const SizedBox.shrink(),
        tiles[1],
        ...tiles.sublist(2),
      ],
    );
  }
}

class _StickyTile extends StatelessWidget {
  const _StickyTile({
    required this.color,
    required this.icon,
    required this.ink,
    required this.rotate,
  });

  final Color color;
  final _StickyIcon icon;
  final Color ink;
  final double rotate;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _StickyPainter(icon: icon, ink: ink),
          ),
        ),
      ),
    );
  }
}

class _StickyPainter extends CustomPainter {
  _StickyPainter({required this.icon, required this.ink});

  final _StickyIcon icon;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.shortestSide * 0.06;

    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.28;

    switch (icon) {
      case _StickyIcon.triangle:
        final path = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r * 0.95, c.dy + r * 0.7)
          ..lineTo(c.dx - r * 0.95, c.dy + r * 0.7)
          ..close();
        canvas.drawPath(path, p);
        break;
      case _StickyIcon.dots:
        final dot = Paint()..color = ink;
        for (var i = -1; i <= 1; i++) {
          canvas.drawCircle(
            Offset(c.dx + i * r * 0.7, c.dy),
            size.shortestSide * 0.045,
            dot,
          );
        }
        break;
      case _StickyIcon.equals:
        canvas.drawLine(
          Offset(c.dx - r, c.dy - r * 0.45),
          Offset(c.dx + r, c.dy - r * 0.45),
          p,
        );
        canvas.drawLine(
          Offset(c.dx - r, c.dy + r * 0.45),
          Offset(c.dx + r, c.dy + r * 0.45),
          p,
        );
        break;
      case _StickyIcon.circle:
        canvas.drawCircle(c, r, p);
        break;
      case _StickyIcon.arrow:
        canvas.drawLine(Offset(c.dx, c.dy + r), Offset(c.dx, c.dy - r), p);
        canvas.drawLine(
          Offset(c.dx, c.dy - r),
          Offset(c.dx - r * 0.55, c.dy - r * 0.4),
          p,
        );
        canvas.drawLine(
          Offset(c.dx, c.dy - r),
          Offset(c.dx + r * 0.55, c.dy - r * 0.4),
          p,
        );
        break;
      case _StickyIcon.square:
        final rect = Rect.fromCenter(
          center: c,
          width: r * 1.9,
          height: r * 1.9,
        );
        canvas.drawRect(rect, p);
        break;
      case _StickyIcon.check:
        final path = Path()
          ..moveTo(c.dx - r * 0.85, c.dy)
          ..lineTo(c.dx - r * 0.1, c.dy + r * 0.7)
          ..lineTo(c.dx + r * 0.95, c.dy - r * 0.55);
        canvas.drawPath(path, p);
        break;
      case _StickyIcon.plus:
        canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), p);
        canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), p);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _StickyPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.ink != ink;
}
